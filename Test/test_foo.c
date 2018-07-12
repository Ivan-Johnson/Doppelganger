/*
 * Test/test_foo.c
 *
 * A simple file for testing Src/foo.c
 *
 * Copyright(C) 2018, Ivan Tobias Johnson
 *
 * LICENSE: GPL 2.0 only
 */

#include <assert.h>

#include "unity.h"
#include "foo.h"

void testZero()
{
	TEST_ASSERT_EQUAL_INT(0, getZero());
}

void testOne()
{
	TEST_ASSERT_EQUAL_INT(1, getOne());
}

void TEST_foo()
{
	RUN_TEST(testZero);
	RUN_TEST(testOne);
}
