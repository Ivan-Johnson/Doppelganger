/*
 * Test/testRunner.c
 *
 * A simple file for running Unity unit tests
 *
 * Copyright(C) 2018, Ivan Tobias Johnson
 *
 * LICENSE: GPL 2.0 only
 */

#include "unity.h"

//TODO consider which is more elegant: manually defining functions, or having
//many headerfiles each with just a single function definition.
//
//or maybe just a tests.h that defines all of them, then defines an array
//containing all of them?
void TEST_foo();

int main()
{
	UNITY_BEGIN();
	TEST_foo();
	return UNITY_END();
}
