#makefile
#
#Defines how the project should be built
#
#Copyright(C) 2018, Ivan Tobias Johnson
#
#LICENSE: GPL 2.0 only

APP=jormungandr
TEST_RUNNER=testRunner

SRC_DIR=Src
SRC_TEST_DIR=Test
BIN_DIR_BASE=Bin

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

SOURCES=$(wildcard $(SRC_DIR)/*.c)
HEADERS=$(wildcard $(SRC_DIR)/*.h)
OBJECTS=$(SOURCES:$(SRC_DIR)/%.c=$(BIN_DIR)/%.o)
BIN_DIR  = $(BIN_DIR_BASE)/$(ISTEST)/$(OPTIMIZED)/$(STRICT)
DEPENDS=$(BIN_DIR)/.depends

.PHONY: all
all: $(BIN_DIR)/$(APP)
#symlink the built executable to $(BIN_DIR_BASE)/ for convinience
	ln -sf $(BIN_DIR:$(BIN_DIR_BASE)/%=%)/$(APP) $(BIN_DIR_BASE)/

.PHONY: clean
clean:
	rm -rf $(BIN_DIR)

.PHONY: CLEAN
CLEAN:
	rm -rf $(BIN_DIR_BASE)

$(BIN_DIR)/$(APP): $(OBJECTS) | $(BIN_DIR)
	$(CC) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

$(BIN_DIR)/%.o: | $(BIN_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(DEPENDS): $(SOURCES) | $(BIN_DIR)
	$(CC) $(CFLAGS) -MM $(SOURCES) | sed -e 's!^!$(BIN_DIR)/!' >$@

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

BIN_TEST_DIR=$(BIN_DIR)/Test
TEST_SOURCES=$(wildcard $(SRC_TEST_DIR)/*.c)
TEST_OBJECTS=$(TEST_SOURCES:$(SRC_TEST_DIR)/%.c=$(BIN_TEST_DIR)/%.o)
TEST_DEPENDS=$(BIN_TEST_DIR)/.depends

#.PHONY:test
test: $(BIN_TEST_DIR)/$(TEST_RUNNER)
#symlink the built executable to $(BIN_DIR_BASE)/ for convinience
	ln -sf $(BIN_TEST_DIR:$(BIN_DIR_BASE)/%=%)/$(TEST_RUNNER) $(BIN_DIR_BASE)/

$(BIN_TEST_DIR)/$(TEST_RUNNER): $(TEST_OBJECTS) $(OBJECTS) | $(BIN_DIR) $(BIN_TEST_DIR)
	$(CC) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

$(BIN_TEST_DIR)/%.o: | $(BIN_TEST_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(TEST_DEPENDS): $(TEST_SOURCES) | $(BIN_TEST_DIR)
	$(CC) $(CFLAGS) -MM $(TEST_SOURCES) | sed -e 's!^!$(BIN_TEST_DIR)/!' >$@

ifeq ($(MAKECMDGOALS),test)
-include $(TEST_DEPENDS)
endif

$(BIN_TEST_DIR):
	mkdir -p $@
