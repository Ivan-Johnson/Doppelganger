#!/bin/sh

#if build fails, return 125 so that this commit is skipped
make IS_TEST=yes bisect_make || exit 125
make IS_TEST=yes bisect_run
