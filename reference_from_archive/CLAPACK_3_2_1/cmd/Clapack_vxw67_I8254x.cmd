@ECHO OFF
SETLOCAL
TIME /T

call bt_init
call bt_vxw67vars.cmd
call to CLAPACK_3_2_1

ECHO !!!! INSTALL PATCH FOR CLAPACK
ECHO Backup C:\WindRiver\vxworks-6.7\target\h\sigevent.h to sigevent.org
copy C:\WindRiver\vxworks-6.7\target\h\sigevent.h C:\WindRiver\vxworks-6.7\target\h\sigevent.org

ECHO copy patch V:\uPOS\POS\GeoCVEmb\imports\CLAPACK_3_2_1\WindRiverPatch\vxworks-6.7\target\h\sigevent.h to C:\WindRiver\vxworks-6.7\target\h
copy \uPOS\POS\GeoCVEmb\imports\CLAPACK_3_2_1\WindRiverPatch\vxworks-6.7\target\h\sigevent.h C:\WindRiver\vxworks-6.7\target\h

set BINDIR=PENTIUMgnu
set LIBPOSTFIX=_lib.a
mkdir PENTIUMgnu

REM Can use 'clean' as argument to remove all previous build output
IF "%1"=="clean" goto CLEAN
IF "%1"=="-clean" goto CLEAN

ECHO Build Clapack libraries
make f2clib
make blaslib
make lapacklib
make tmglib

goto END

:CLEAN
ECHO Cleanup Clapack libraries
make clean

:END

ECHO !!!! UNDO INSTALL PATCH
copy C:\WindRiver\vxworks-6.7\target\h\sigevent.org C:\WindRiver\vxworks-6.7\target\h\sigevent.h

TIME /T
