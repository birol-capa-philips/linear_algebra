#!/bin/sh
#
# Build the static libraries to be linked with a VxWorks user-space application (RTP)
#
# make lib
#
set -x
make f2clib
make blaslib
make lapacklib
make tmglib
set +x

