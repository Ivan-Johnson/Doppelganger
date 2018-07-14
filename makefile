#makefile
#
#Defines how the project should be built
#
#Copyright(C) 2018, Ivan Tobias Johnson
#
#LICENSE: MIT License

APP = foo

SRC_DIR = Src
SRC_TEST_DIR = Test
BIN_DIR_BASE = Bin

#the generate_test_runner.rb script from Unity
#if it's not in $PATH, then this variable can be changed to an absolute path.
SUMMARY_SCRIPT = Scripts/sumarize.bash
GENERATE_RUNNER = generate_test_runner.rb


.DELETE_ON_ERROR:

##############
#CC ARGUMENTS#
##############

#to cross-compile for windows, uncomment. Executables must be renamed to .exe
#CC = x86_64-w64-mingw32-gcc

CFLAGS += -I$(SRC_DIR)
CFLAGS += -Wfatal-errors -std=c99


#Controls how strict the compiler is. Zero is the most strict, larger values are
#more lenient. This value can be modified here, or make can be run as follows:
#
#make <target> STRICT=<value>
STRICT ?= 0

ifeq ($(shell test $(STRICT) -le 2; echo $$?),0)
	CFLAGS += -Werror
endif

ifeq ($(shell test $(STRICT) -le 1; echo $$?),0)
	CFLAGS += -Wconversion
endif

ifeq ($(shell test $(STRICT) -eq 0; echo $$?),0)
#-fsanitize=address
	CFLAGS += -Wall -Wextra
endif


OPTS_DEBUG = -D DEBUG -O0 -ggdb -fno-inline
OPTS_OPTIMIZED = -O3
OPTIMIZED ?= 0
ifeq ($(shell test $(OPTIMIZED) -eq 0; echo $$?),0)
	CFLAGS += $(OPTS_DEBUG)
else
	CFLAGS += $(OPTS_OPTIMIZED)
endif

ifeq ($(MAKECMDGOALS),test)
	ISTEST = 1
	CFLAGS += -D TEST
	LDLIBS += -lunity
else
	ISTEST = 0
endif

###########
#BUILD APP#
###########

SOURCES = $(wildcard $(SRC_DIR)/*.c)
HEADERS = $(wildcard $(SRC_DIR)/*.h)
OBJECTS = $(SOURCES:$(SRC_DIR)/%.c=$(BIN_DIR)/%.o)
BIN_DIR = $(BIN_DIR_BASE)/$(ISTEST)/$(OPTIMIZED)/$(STRICT)
DEPENDS = $(BIN_DIR)/.depends

.PHONY: all
all: $(BIN_DIR)/$(APP)
#symlink the built executable to $(BIN_DIR_BASE)/ for convinience
	ln -sf $(BIN_DIR:$(BIN_DIR_BASE)/%=%)/$(APP) $(BIN_DIR_BASE)/

$(BIN_DIR)/$(APP): $(OBJECTS) | $(BIN_DIR)
	$(CC) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

$(BIN_DIR)/%.o: | $(BIN_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(DEPENDS): $(SOURCES) | $(BIN_DIR)
	$(CC) $(CFLAGS) -MM $^ | sed -e 's!^!$(BIN_DIR)/!' >$@

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),CLEAN)
-include $(DEPENDS)
endif
endif


$(BIN_DIR):
	mkdir -p $@


#############
#BUILD TESTS#
#############
SOURCE_TESTRUNNER_DIR = $(BIN_DIR_BASE)/TestRunners
BIN_TESTRUNNER_DIR    = $(BIN_DIR)/TestRunners
BIN_TEST_DIR          = $(BIN_DIR)/TestCases
OUT_TEST_DIR          = $(BIN_DIR)/TestOut


#1: we're given these test case files
TEST_SOURCES        = $(wildcard $(SRC_TEST_DIR)/*.c)
#2: which we use to generate _runner.c files
TEST_SOURCES_RUNNER = $(TEST_SOURCES:$(SRC_TEST_DIR)/%.c=$(SOURCE_TESTRUNNER_DIR)/%_runner.c)
#3: that are then compiled to _runner.o files
TEST_OBJECTS        = $(TEST_SOURCES:$(SRC_TEST_DIR)/%.c=$(BIN_TESTRUNNER_DIR)/%_runner.o)
#4: which are in turn linked into executables
TEST_RUNNERS        = $(TEST_SOURCES:$(SRC_TEST_DIR)/%.c=$(BIN_TESTRUNNER_DIR)/%_runner)
#5: whose output is collected
TEST_OUT_FILES      = $(TEST_SOURCES:$(SRC_TEST_DIR)/%.c=$(OUT_TEST_DIR)/%.out)
#6: and sumarized
TEST_SUMMARY_FILE   = $(OUT_TEST_DIR)/summary.txt



TESTRUNNER_DEPENDS  = $(BIN_TESTRUNNER_DIR)/.depends
TESTCASE_DEPENDS    = $(BIN_TEST_DIR)/.depends

.PHONY:test
test: $(TEST_SUMMARY_FILE) $(TEST_OUT_FILES) $(TEST_RUNNERS)
	@for x in $^; do                                                          \
		ln -sf $${x/"$(BIN_DIR_BASE)/"} $(BIN_DIR_BASE)/$$(basename $$x);\
	done
	@cat $(TEST_SUMMARY_FILE)

$(TEST_SUMMARY_FILE): $(TEST_OUT_FILES)
#If there are no failures, then exit   successfully and silently.
#If there ARE    failures, then exit UNsuccessfully and show the summary file
	$(SUMMARY_SCRIPT) $^ > $@ || { cat $@; false; }

$(OUT_TEST_DIR)/%.out: $(BIN_TESTRUNNER_DIR)/%_runner | $(OUT_TEST_DIR)
	$< > $@ || true

#TODO: only link with the objects that it actually needs
.PRECIOUS: $(TEST_RUNNERS)
$(BIN_TESTRUNNER_DIR)/%_runner: $(OBJECTS) $(BIN_TESTRUNNER_DIR)/%_runner.o $(BIN_TEST_DIR)/%.o  | $(BIN_TESTRUNNER_DIR)
	$(CC) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

$(BIN_TEST_DIR)/%.o: | $(BIN_TEST_DIR)

$(BIN_TESTRUNNER_DIR)/%_runner.o: | $(BIN_TESTRUNNER_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(TESTRUNNER_DEPENDS): $(TEST_SOURCES_RUNNER) | $(BIN_TESTRUNNER_DIR)
	$(CC) $(CFLAGS) -MM $^ | sed -e 's!^!$(BIN_TESTRUNNER_DIR)/!' >$@
$(TESTCASE_DEPENDS): $(TEST_SOURCES) | $(BIN_TEST_DIR)
	$(CC) $(CFLAGS) -MM $^ | sed -e 's!^!$(BIN_TEST_DIR)/!' >$@

ifeq ($(MAKECMDGOALS),test)
-include $(TESTCASE_DEPENDS)
-include $(TESTRUNNER_DEPENDS)
endif

.PRECIOUS: $(TEST_SOURCES_RUNNER)
$(SOURCE_TESTRUNNER_DIR)/%_runner.c: $(SRC_TEST_DIR)/%.c | $(SOURCE_TESTRUNNER_DIR)
	$(GENERATE_RUNNER) $< $@

$(OUT_TEST_DIR):
	mkdir -p $@

$(BIN_TESTRUNNER_DIR):
	mkdir -p $@

$(SOURCE_TESTRUNNER_DIR):
	mkdir -p $@

$(BIN_TEST_DIR):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(BIN_DIR) $(SOURCE_TESTRUNNER_DIR)

.PHONY: CLEAN
CLEAN:
	rm -rf $(BIN_DIR_BASE)
