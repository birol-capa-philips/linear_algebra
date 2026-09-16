# Native Windows builds

This repository provides one CMake adapter for building either included
CLAPACK 3.2.1 source tree with Visual Studio 2022 for 32-bit Windows. The
source tree is selected by a configure preset; no CMake files are added to the
imported source directories.

The adapter reads source lists from each distribution's original GNU
makefiles. The `RelWithDebInfo` build configuration enables optimization and
compiler debug information.

## Prerequisites

- Visual Studio 2022 with the Desktop development with C++ workload
- CMake 3.21 or newer

Run all commands from the repository root.

## Select a source tree

`CLAPACK_SOURCE_DIR` is a required CMake cache variable containing the path to
the CLAPACK source tree to build. Do not edit `CMakeLists.txt` to change it.

The included configure presets set it automatically:

| Configure preset | `CLAPACK_SOURCE_DIR` | Build directory |
| --- | --- | --- |
| `archive-vs2022-win32` | `reference_from_archive/CLAPACK_3_2_1` | `build/archive-vs2022-win32` |
| `netlib-vs2022-win32` | `reference_from_netlib/CLAPACK-3.2.1` | `build/netlib-vs2022-win32` |

For another compatible CLAPACK 3.2.1 tree, pass the variable while creating a
new, unique build directory:

```powershell
cmake -S . -B build/my-clapack -A Win32 `
	-DCLAPACK_SOURCE_DIR="C:/path/to/CLAPACK-3.2.1"
cmake --build build/my-clapack --config RelWithDebInfo --parallel
ctest --test-dir build/my-clapack -C RelWithDebInfo `
	--parallel 4 --output-on-failure
```

A build directory stores `CLAPACK_SOURCE_DIR` in its CMake cache, so use a
different build directory for every source tree. For frequently used trees,
add another configure, build, and test preset to `CMakePresets.json` using the
same pattern as the included presets.

## Archive source

```powershell
cmake --preset archive-vs2022-win32
cmake --build --preset archive-vs2022-win32-relwithdebinfo --parallel
ctest --preset archive-vs2022-win32
```

Outputs are written under `build/archive-vs2022-win32/`.

## Netlib source

```powershell
cmake --preset netlib-vs2022-win32
cmake --build --preset netlib-vs2022-win32-relwithdebinfo --parallel
ctest --preset netlib-vs2022-win32
```

Outputs are written under `build/netlib-vs2022-win32/`.

Each build produces these static libraries under its
`lib/RelWithDebInfo/` directory:

- `f2c.lib` - f2c runtime
- `blas.lib` - reference BLAS
- `lapack.lib` - CLAPACK
- `tmg.lib` - LAPACK test matrix generators

Compiler program databases are written under `pdb/RelWithDebInfo/`. Reports
from input-driven tests are written under `test-results/`.

## Test labels

Each source tree registers 101 tests: 12 BLAS tests, 7 installation checks,
and 82 LAPACK tests. Run one category directly against a configured build:

```powershell
ctest --test-dir build/netlib-vs2022-win32 -C RelWithDebInfo -L blas --output-on-failure
ctest --test-dir build/netlib-vs2022-win32 -C RelWithDebInfo -L install --output-on-failure
ctest --test-dir build/netlib-vs2022-win32 -C RelWithDebInfo -L lapack --output-on-failure
```

`CLAPACK_REQUIRE_32_BIT` defaults to `ON` and rejects a non-Win32 build.