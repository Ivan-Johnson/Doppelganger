/*
 * Src/jormungandr.c
 *
 * Prints out the message "Hello, World!"
 *
 * Copyright(C) 2018, Ivan Tobias Johnson
 *
 * LICENSE: GPL 2.0 only
 */


#include <stdio.h>
#include <stdlib.h>

#include "jormungandr.h"

#ifndef TEST
int main()
{
	puts("Hello, World!");
	return 0;
}
#endif
