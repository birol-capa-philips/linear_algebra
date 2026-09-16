# -*- Makefile -*-
####################################################################
#  LAPACK make include file.                                       #
#  LAPACK, Version 3.2.1                                           #
#  June 2009		                                           #
#                                                                  #
#  March 5, 2013  GK for VxWorks 6.9 Kernel Space                  #
#  -Non-standard version of sigevent.h is needed                   #
####################################################################
#
# See the INSTALL/ directory for more examples.
#
# SHELL = /bin/sh
SHELL = $(WIND_UTILITIES)/x86-win32/bin/sh.EXE
#
#  The machine (platform) identifier to append to the library names
#
#PLAT = _LINUX
PLAT = _VXWORKS
#  
#  Modify the FORTRAN and OPTS definitions to refer to the
#  compiler and desired compiler options for your machine.  NOOPT
#  refers to the compiler options desired when NO OPTIMIZATION is
#  selected.  Define LOADER and LOADOPTS to refer to the loader
#  and desired load options for your machine.
#
#######################################################
# Turn on verbose output from build tools:
TRACE = 1

# This is used to compile C libary
# CC        = gcc
CC        = ccpentium -DNO_BLAS_WRAP
# if no wrapping of the blas library is needed, uncomment next line
#CC        = gcc -DNO_BLAS_WRAP
#CFLAGS    = -O2 -I$(TOPDIR)/INCLUDE

# For VxWorks kernel builds, define _CLAPACK_BUILD (-D_CLAPACK_BUILD) to fix up $(WIND_BASE)/target/h/sigevent.h
CFLAGS  = -mtune=pentium4 -march=pentium4 -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp -ansi -fno-zero-initialized-in-bss -O3 -Wall -Wsystem-headers  -MD -MP -D_CLAPACK_BUILD -DCPU=_VX_PENTIUM4 -DTOOL_FAMILY=gnu -DTOOL=gnu -D_WRS_KERNEL -D_WRS_VX_SMP -D_WRS_CONFIG_SMP -D_VSB_CONFIG_FILE=\"$(WIND_BASE)/target/lib_smp/h/config/vsbConfig.h\" -I$(WIND_BASE)/target/h/wrn/coreip -I$(WIND_BASE)/target/h -I$(TOPDIR)/INCLUDE -Wno-parentheses

# xxx The whole concept of loaders and linkers really only applies to native builds. On a VxWorks cross-development host, we don't want to be building executables - only archives.
# LOADER    = gcc
#LOADER    = ccpentium
# xxx Gary added the definition of LD

LD = ldpentium -O3 -L$(WIND_BASE)/target/lib/pentium/PENTIUM4/common/

LOADOPTS  =

# For VxWorks kernel builds, define _CLAPACK_BUILD (-D_CLAPACK_BUILD) to fix up $(WIND_BASE)/target/h/sigevent.h
NOOPT = -mtune=pentium4 -march=pentium4 -nostdlib -fno-builtin -fno-defer-pop -fno-implicit-fp -ansi -fno-zero-initialized-in-bss -O0 -Wall -Wsystem-headers  -MD -MP -D_CLAPACK_BUILD -DCPU=_VX_PENTIUM4 -DTOOL_FAMILY=gnu -DTOOL=gnu -D_WRS_KERNEL -D_WRS_VX_SMP -D_WRS_CONFIG_SMP -D_VSB_CONFIG_FILE=\"$(WIND_BASE)/target/lib_smp/h/config/vsbConfig.h\" -I$(WIND_BASE)/target/h/wrn/coreip -I$(WIND_BASE)/target/h -I$(TOPDIR)/INCLUDE -Wno-parentheses

DRVCFLAGS = $(CFLAGS)
F2CCFLAGS = $(CFLAGS)
#######################################################################

#
# Timer for the SECOND and DSECND routines
#
# Default : SECOND and DSECND will use a call to the EXTERNAL FUNCTION ETIME
# TIMER    = EXT_ETIME
# For RS6K : SECOND and DSECND will use a call to the EXTERNAL FUNCTION ETIME_
# TIMER    = EXT_ETIME_
# For gfortran compiler: SECOND and DSECND will use a call to the INTERNAL FUNCTION ETIME
# TIMER    = INT_ETIME
# If your Fortran compiler does not provide etime (like Nag Fortran Compiler, etc...)
# SECOND and DSECND will use a call to the Fortran standard INTERNAL FUNCTION CPU_TIME 
TIMER    = INT_CPU_TIME
# xxx If neither of this works...you can use the NONE value... In that case, SECOND and DSECND will always return 0
#TIMER     = NONE
#
#  The archiver and the flag(s) to use when building archive (library)
#  If you system has no ranlib, set RANLIB = echo.
#
# ARCH     = ar
ARCH     = arpentium
ARCHFLAGS= cr
# RANLIB   = ranlib
RANLIB   = ranlibpentium
#
#  The location of BLAS library for linking the testing programs.
#  The target's machine-specific, optimized BLAS library should be
#  used whenever possible.
#
BLASLIB      = ../../$(BINDIR)/blas$(LIBPOSTFIX)
#
#  Location of the extended-precision BLAS (XBLAS) Fortran library
#  used for building and testing extended-precision routines.  The
#  relevant routines will be compiled and XBLAS will be linked only if
#  USEXBLAS is defined.
#
# USEXBLAS    = Yes
XBLASLIB     =
# XBLASLIB    = -lxblas
#
#  Names of generated libraries in addition to blas$(LIBPOSTFIX)
#
LAPACKLIB    = $(BINDIR)/lapack$(LIBPOSTFIX)
F2CLIB       = ../../$(BINDIR)/f2c$(LIBPOSTFIX)
TMGLIB       = $(BINDIR)/tmg$(LIBPOSTFIX)

EIGSRCLIB    = $(BINDIR)/eigsrc$(LIBPOSTFIX)
LINSRCLIB    = $(BINDIR)/linsrc$(LIBPOSTFIX)
