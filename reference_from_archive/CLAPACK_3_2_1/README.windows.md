# Native Windows build

This CMake adapter builds the CLAPACK 3.2.1 static libraries with Visual
Studio 2022 for 32-bit Windows. The supplied preset uses the
`RelWithDebInfo` configuration, which enables optimization and compiler debug
information.

The adapter preserves the original build manifests by reading the source lists
from the existing GNU makefiles. The VxWorks `make.inc` and source tree remain
unchanged, including the patched LAPACK sources under `SRC`.

## Prerequisites

- Visual Studio 2022 with the Desktop development with C++ workload
- CMake 3.21 or newer

The commands can be run from a normal terminal or a Visual Studio 2022
Developer Command Prompt.

## Configure and build

Run these commands from the `CLAPACK_3_2_1` directory:

```powershell
cmake --preset vs2022-win32
cmake --build --preset vs2022-win32-relwithdebinfo --parallel
```

The preset selects the Visual Studio 2022 generator, the `Win32` platform, and
the `RelWithDebInfo` configuration. CMake rejects a non-32-bit configuration by
default.

## Outputs

Static libraries are written to:

```text
build/vs2022-win32/lib/RelWithDebInfo/
```

The generated libraries are:

- `f2c.lib` - f2c runtime
- `blas.lib` - reference BLAS
- `lapack.lib` - CLAPACK
- `tmg.lib` - LAPACK test matrix generators

Compiler program databases are written to:

```text
build/vs2022-win32/pdb/RelWithDebInfo/
```

All four libraries have been verified as x86 COFF archives (`14C machine
(x86)`).

## Run the tests

The adapter builds and registers the original BLAS, LAPACK installation, and
LAPACK numerical test programs. After building, run all tests from the
`CLAPACK_3_2_1` directory:

```powershell
ctest --test-dir build/vs2022-win32 -C RelWithDebInfo --parallel 4 --output-on-failure
```

The complete suite contains 101 tests: 12 BLAS tests, 7 installation checks,
and 82 LAPACK tests. All 101 tests pass with the configuration documented
above.

Tests can be selected by label:

```powershell
ctest --test-dir build/vs2022-win32 -C RelWithDebInfo -L blas --output-on-failure
ctest --test-dir build/vs2022-win32 -C RelWithDebInfo -L install --output-on-failure
ctest --test-dir build/vs2022-win32 -C RelWithDebInfo -L lapack --output-on-failure
```

Reports from the input-driven BLAS and LAPACK programs are written to:

```text
build/vs2022-win32/test-results/
```

## Build files

- `CMakeLists.txt` defines the four static-library targets and MSVC settings.
- `CMakePresets.json` defines the Visual Studio 2022 Win32 build presets.
- `cmake/MakefileSources.cmake` imports source manifests from the original
  makefiles.
- `cmake/RunWithInput.cmake` runs input-driven tests and validates their
  generated reports.
- `cmake/windows_timers.c` supplies native Windows implementations of the
  LAPACK timing routines that are VxWorks-specific in this archive.