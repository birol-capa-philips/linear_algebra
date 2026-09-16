cmake_minimum_required(VERSION 3.21)

project(CLAPACK VERSION 3.2.1 LANGUAGES C)

include(CTest)

option(CLAPACK_REQUIRE_32_BIT "Reject non-32-bit build configurations" ON)

if(CLAPACK_REQUIRE_32_BIT AND NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
    message(FATAL_ERROR
        "This adapter is configured for 32-bit output. Configure Visual Studio with -A Win32.")
endif()

include(cmake/MakefileSources.cmake)

set(CLAPACK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(F2C_SOURCE_DIR "${CLAPACK_ROOT}/F2CLIBS/libf2c")
set(BLAS_SOURCE_DIR "${CLAPACK_ROOT}/BLAS/SRC")
set(LAPACK_SOURCE_DIR "${CLAPACK_ROOT}/SRC")
set(TMG_SOURCE_DIR "${CLAPACK_ROOT}/TESTING/MATGEN")

clapack_read_make_objects(F2C_SOURCES
    "${F2C_SOURCE_DIR}/Makefile" "${F2C_SOURCE_DIR}"
    MISC POW CX DCX REAL DBL INT HALF CMP EFL CHAR I77)

clapack_read_make_objects(BLAS_SOURCES
    "${BLAS_SOURCE_DIR}/Makefile" "${BLAS_SOURCE_DIR}"
    SBLAS1 SBLAS2 SBLAS3 DBLAS1 DBLAS2 DBLAS3
    CBLAS1 CBLAS2 CBLAS3 ZBLAS1 ZBLAS2 ZBLAS3 ALLBLAS)

clapack_read_make_objects(LAPACK_SOURCES
    "${LAPACK_SOURCE_DIR}/Makefile" "${LAPACK_SOURCE_DIR}"
    SLASRC DLASRC CLASRC ZLASRC SCLAUX DZLAUX ALLAUX)

if(WIN32)
    list(REMOVE_ITEM LAPACK_SOURCES
        "${CLAPACK_ROOT}/INSTALL/second.c"
        "${CLAPACK_ROOT}/INSTALL/dsecnd.c"
    )
    list(APPEND LAPACK_SOURCES "${CLAPACK_ROOT}/cmake/windows_timers.c")
endif()

clapack_read_make_objects(TMG_SOURCES
    "${TMG_SOURCE_DIR}/Makefile" "${TMG_SOURCE_DIR}"
    SMATGEN CMATGEN SCATGEN DMATGEN ZMATGEN DZATGEN)

function(clapack_configure_library target_name)
    target_include_directories(${target_name}
        PUBLIC
            "$<BUILD_INTERFACE:${CLAPACK_ROOT}/INCLUDE>"
            "$<INSTALL_INTERFACE:include>"
        PRIVATE
            "${F2C_SOURCE_DIR}"
    )

    set_target_properties(${target_name} PROPERTIES
        C_STANDARD 90
        C_STANDARD_REQUIRED YES
        C_EXTENSIONS YES
    )

    foreach(configuration Debug Release RelWithDebInfo MinSizeRel)
        string(TOUPPER "${configuration}" configuration_upper)
        set_target_properties(${target_name} PROPERTIES
            "ARCHIVE_OUTPUT_DIRECTORY_${configuration_upper}"
                "${CMAKE_BINARY_DIR}/lib/${configuration}"
            "COMPILE_PDB_OUTPUT_DIRECTORY_${configuration_upper}"
                "${CMAKE_BINARY_DIR}/pdb/${configuration}"
        )
    endforeach()
endfunction()

add_library(f2c STATIC ${F2C_SOURCES})
clapack_configure_library(f2c)
target_compile_definitions(f2c PRIVATE Skip_f2c_Undefs)

add_library(blas STATIC ${BLAS_SOURCES})
clapack_configure_library(blas)

add_library(lapack STATIC ${LAPACK_SOURCES})
clapack_configure_library(lapack)
target_link_libraries(lapack PUBLIC blas f2c)

add_library(tmg STATIC ${TMG_SOURCES})
clapack_configure_library(tmg)
target_link_libraries(tmg PUBLIC lapack)

if(BUILD_TESTING)
    set(CLAPACK_TEST_RESULTS_DIR "${CMAKE_BINARY_DIR}/test-results")
    file(MAKE_DIRECTORY "${CLAPACK_TEST_RESULTS_DIR}")

    function(clapack_configure_test_target target_name)
        target_include_directories(${target_name} PRIVATE
            "${CLAPACK_ROOT}/INCLUDE"
            "${F2C_SOURCE_DIR}"
        )
        target_link_libraries(${target_name} PRIVATE tmg lapack blas f2c)
        if(MSVC)
            target_link_options(${target_name} PRIVATE "/STACK:67108864")
        endif()
    endfunction()

    function(clapack_add_input_test test_name test_target input_file)
        string(REPLACE "." "_" output_name "${test_name}")
        add_test(NAME "${test_name}"
            COMMAND "${CMAKE_COMMAND}"
                "-DTEST_EXECUTABLE=$<TARGET_FILE:${test_target}>"
                "-DTEST_INPUT=${CLAPACK_ROOT}/${input_file}"
                "-DTEST_OUTPUT=${CLAPACK_TEST_RESULTS_DIR}/${output_name}.out"
                "-DREQUIRED_REGEX=tests run|examples tested"
                "-DFORBIDDEN_REGEX=out of [0-9]+ tests failed|[1-9][0-9]* error messages recorded|Execution not attempted|routines were not tested|\\*\\*\\* Error|example number where [A-Za-z() /]*info is not (0|zero)[ ]*=[ ]*[1-9]|example number where ILO or IHI wrong[ ]*=[ ]*[1-9]"
                -P "${CLAPACK_ROOT}/cmake/RunWithInput.cmake")
        set_tests_properties("${test_name}" PROPERTIES LABELS "lapack")
    endfunction()

    function(clapack_add_install_test test_name)
        set(test_target "test${test_name}")
        add_executable(${test_target} ${ARGN})
        target_include_directories(${test_target} PRIVATE
            "${CLAPACK_ROOT}/INCLUDE"
            "${F2C_SOURCE_DIR}"
        )
        target_link_libraries(${test_target} PRIVATE f2c)
        add_test(NAME "install.${test_name}" COMMAND ${test_target})
        set_tests_properties("install.${test_name}" PROPERTIES
            FAIL_REGULAR_EXPRESSION "\\*\\*\\* Error"
            LABELS "install"
        )
    endfunction()

    clapack_add_install_test(lsame
        INSTALL/lsame.c INSTALL/lsametst.c)
    clapack_add_install_test(slamch
        INSTALL/slamch.c INSTALL/lsame.c INSTALL/slamchtst.c)
    clapack_add_install_test(dlamch
        INSTALL/dlamch.c INSTALL/lsame.c INSTALL/dlamchtst.c)
    clapack_add_install_test(second
        cmake/windows_timers.c INSTALL/secondtst.c)
    clapack_add_install_test(dsecnd
        cmake/windows_timers.c INSTALL/dsecndtst.c)
    clapack_add_install_test(ieee INSTALL/tstiee.c)
    clapack_add_install_test(version
        INSTALL/ilaver.c INSTALL/LAPACK_version.c)

    set(BLAS_TEST_PRECISIONS s d c z)
    foreach(blas_level 1 2 3)
        foreach(blas_precision IN LISTS BLAS_TEST_PRECISIONS)
            set(blas_test_target "xblat${blas_level}${blas_precision}")
            add_executable(${blas_test_target}
                "BLAS/TESTING/${blas_precision}blat${blas_level}.c")
            clapack_configure_test_target(${blas_test_target})

            if(blas_level EQUAL 1)
                add_test(NAME "blas.level${blas_level}.${blas_precision}"
                    COMMAND ${blas_test_target})
                set_tests_properties(
                    "blas.level${blas_level}.${blas_precision}"
                    PROPERTIES PASS_REGULAR_EXPRESSION "PASS")
            else()
                add_test(NAME "blas.level${blas_level}.${blas_precision}"
                    COMMAND "${CMAKE_COMMAND}"
                        "-DTEST_EXECUTABLE=$<TARGET_FILE:${blas_test_target}>"
                        "-DTEST_INPUT=${CLAPACK_ROOT}/BLAS/${blas_precision}blat${blas_level}.in"
                        "-DTEST_WORKING_DIRECTORY=${CLAPACK_TEST_RESULTS_DIR}/blas.level${blas_level}.${blas_precision}"
                        "-DTEST_REPORT=${blas_precision}blat${blas_level}.out"
                        "-DTEST_OUTPUT=${CLAPACK_TEST_RESULTS_DIR}/blas.level${blas_level}.${blas_precision}.out"
                        "-DREQUIRED_REGEX=PASS"
                        -P "${CLAPACK_ROOT}/cmake/RunWithInput.cmake")
            endif()
            set_tests_properties("blas.level${blas_level}.${blas_precision}"
                PROPERTIES LABELS "blas")
        endforeach()
    endforeach()

    set(LIN_TEST_SOURCE_DIR "${CLAPACK_ROOT}/TESTING/LIN")
    clapack_read_make_objects(LIN_COMMON_SOURCES
        "${LIN_TEST_SOURCE_DIR}/Makefile" "${LIN_TEST_SOURCE_DIR}" ALINTST)
    clapack_read_make_objects(LIN_SC_SOURCES
        "${LIN_TEST_SOURCE_DIR}/Makefile" "${LIN_TEST_SOURCE_DIR}" SCLNTST)
    clapack_read_make_objects(LIN_DZ_SOURCES
        "${LIN_TEST_SOURCE_DIR}/Makefile" "${LIN_TEST_SOURCE_DIR}" DZLNTST)

    foreach(lin_precision s c d z)
        string(TOUPPER "${lin_precision}" lin_precision_upper)
        clapack_read_make_objects(LIN_${lin_precision_upper}_SOURCES
            "${LIN_TEST_SOURCE_DIR}/Makefile" "${LIN_TEST_SOURCE_DIR}"
            ${lin_precision_upper}LINTST)
    endforeach()

    list(APPEND LIN_S_SOURCES
        "${LIN_TEST_SOURCE_DIR}/sdrvge.c"
        "${LIN_TEST_SOURCE_DIR}/serrge.c"
        "${LIN_TEST_SOURCE_DIR}/sdrvgb.c"
        "${LIN_TEST_SOURCE_DIR}/sdrvpo.c")
    list(APPEND LIN_C_SOURCES
        "${LIN_TEST_SOURCE_DIR}/cdrvge.c"
        "${LIN_TEST_SOURCE_DIR}/cdrvgb.c"
        "${LIN_TEST_SOURCE_DIR}/cerrge.c"
        "${LIN_TEST_SOURCE_DIR}/cdrvpo.c"
        "${LIN_TEST_SOURCE_DIR}/cerrpo.c")
    list(APPEND LIN_D_SOURCES
        "${LIN_TEST_SOURCE_DIR}/ddrvge.c"
        "${LIN_TEST_SOURCE_DIR}/ddrvgb.c"
        "${LIN_TEST_SOURCE_DIR}/derrge.c"
        "${LIN_TEST_SOURCE_DIR}/ddrvpo.c"
        "${LIN_TEST_SOURCE_DIR}/derrpo.c")
    list(APPEND LIN_Z_SOURCES
        "${LIN_TEST_SOURCE_DIR}/zdrvge.c"
        "${LIN_TEST_SOURCE_DIR}/zdrvgb.c"
        "${LIN_TEST_SOURCE_DIR}/zerrge.c"
        "${LIN_TEST_SOURCE_DIR}/zdrvpo.c"
        "${LIN_TEST_SOURCE_DIR}/zerrpo.c")

    foreach(lin_precision s c)
        string(TOUPPER "${lin_precision}" lin_precision_upper)
        add_executable(xlintst${lin_precision}
            ${LIN_COMMON_SOURCES} ${LIN_SC_SOURCES}
            ${LIN_${lin_precision_upper}_SOURCES} cmake/windows_timers.c)
        clapack_configure_test_target(xlintst${lin_precision})
    endforeach()
    foreach(lin_precision d z)
        string(TOUPPER "${lin_precision}" lin_precision_upper)
        add_executable(xlintst${lin_precision}
            ${LIN_COMMON_SOURCES} ${LIN_DZ_SOURCES}
            ${LIN_${lin_precision_upper}_SOURCES} cmake/windows_timers.c)
        clapack_configure_test_target(xlintst${lin_precision})
    endforeach()

    set(LIN_EXTRA_TARGETS
        xlintstds:DSLINTST
        xlintstzc:ZCLINTST
        xlintstrfs:SLINTSTRFP
        xlintstrfd:DLINTSTRFP
        xlintstrfc:CLINTSTRFP
        xlintstrfz:ZLINTSTRFP)
    foreach(lin_extra_target IN LISTS LIN_EXTRA_TARGETS)
        string(REPLACE ":" ";" lin_extra_parts "${lin_extra_target}")
        list(GET lin_extra_parts 0 lin_target)
        list(GET lin_extra_parts 1 lin_source_group)
        clapack_read_make_objects(LIN_EXTRA_SOURCES
            "${LIN_TEST_SOURCE_DIR}/Makefile" "${LIN_TEST_SOURCE_DIR}"
            ${lin_source_group})
        add_executable(${lin_target}
            ${LIN_EXTRA_SOURCES} cmake/windows_timers.c)
        clapack_configure_test_target(${lin_target})
    endforeach()

    set(EIG_TEST_SOURCE_DIR "${CLAPACK_ROOT}/TESTING/EIG")
    clapack_read_make_objects(EIG_COMMON_SOURCES
        "${EIG_TEST_SOURCE_DIR}/Makefile" "${EIG_TEST_SOURCE_DIR}" AEIGTST)
    clapack_read_make_objects(EIG_SC_SOURCES
        "${EIG_TEST_SOURCE_DIR}/Makefile" "${EIG_TEST_SOURCE_DIR}" SCIGTST)
    clapack_read_make_objects(EIG_DZ_SOURCES
        "${EIG_TEST_SOURCE_DIR}/Makefile" "${EIG_TEST_SOURCE_DIR}" DZIGTST)

    foreach(eig_precision s c d z)
        string(TOUPPER "${eig_precision}" eig_precision_upper)
        clapack_read_make_objects(EIG_${eig_precision_upper}_SOURCES
            "${EIG_TEST_SOURCE_DIR}/Makefile" "${EIG_TEST_SOURCE_DIR}"
            ${eig_precision_upper}EIGTST)
    endforeach()

    foreach(eig_precision s c)
        string(TOUPPER "${eig_precision}" eig_precision_upper)
        add_executable(xeigtst${eig_precision}
            ${EIG_COMMON_SOURCES} ${EIG_SC_SOURCES}
            ${EIG_${eig_precision_upper}_SOURCES} cmake/windows_timers.c)
        clapack_configure_test_target(xeigtst${eig_precision})
    endforeach()
    foreach(eig_precision d z)
        string(TOUPPER "${eig_precision}" eig_precision_upper)
        add_executable(xeigtst${eig_precision}
            ${EIG_COMMON_SOURCES} ${EIG_DZ_SOURCES}
            ${EIG_${eig_precision_upper}_SOURCES} cmake/windows_timers.c)
        clapack_configure_test_target(xeigtst${eig_precision})
    endforeach()

    foreach(lapack_precision s c d z)
        clapack_add_input_test(
            "lapack.lin.${lapack_precision}"
            "xlintst${lapack_precision}"
            "TESTING/${lapack_precision}test.in")

        foreach(eig_test nep sep svd glm gqr gsv lse)
            clapack_add_input_test(
                "lapack.eig.${lapack_precision}.${eig_test}"
                "xeigtst${lapack_precision}"
                "TESTING/${eig_test}.in")
        endforeach()
    endforeach()

    set(EIG_S_INPUTS sec sed sgg sgd ssb ssg sbal sbak sgbal sgbak sbb)
    set(EIG_C_INPUTS cec ced cgg cgd csb csg cbal cbak cgbal cgbak cbb)
    set(EIG_D_INPUTS dec ded dgg dgd dsb dsg dbal dbak dgbal dgbak dbb)
    set(EIG_Z_INPUTS zec zed zgg zgd zsb zsg zbal zbak zgbal zgbak zbb)
    foreach(lapack_precision s c d z)
        string(TOUPPER "${lapack_precision}" lapack_precision_upper)
        foreach(eig_test IN LISTS EIG_${lapack_precision_upper}_INPUTS)
            clapack_add_input_test(
                "lapack.eig.${lapack_precision}.${eig_test}"
                "xeigtst${lapack_precision}"
                "TESTING/${eig_test}.in")
        endforeach()
    endforeach()

    clapack_add_input_test(lapack.lin.ds xlintstds TESTING/dstest.in)
    clapack_add_input_test(lapack.lin.zc xlintstzc TESTING/zctest.in)
    clapack_add_input_test(lapack.lin.s.rfp xlintstrfs TESTING/stest_rfp.in)
    clapack_add_input_test(lapack.lin.d.rfp xlintstrfd TESTING/dtest_rfp.in)
    clapack_add_input_test(lapack.lin.c.rfp xlintstrfc TESTING/ctest_rfp.in)
    clapack_add_input_test(lapack.lin.z.rfp xlintstrfz TESTING/ztest_rfp.in)
endif()

if(MSVC)
    add_compile_definitions(
        _COMPLEX_DEFINED
        MSDOS
        NO_BLAS_WRAP
        NON_POSIX_STDIO
        NON_UNIX_STDIO
        NO_TRUNCATE
        NO_ISATTY
    )
    add_compile_options(
        /W3
        /FS
        /wd4013
        /wd4100
        /wd4210
        /wd4244
        /wd4389
        /wd4554
        /wd4701
        /wd4703
        /wd4706
    )
endif()

install(TARGETS f2c blas lapack tmg ARCHIVE DESTINATION lib)
install(FILES
    "${CLAPACK_ROOT}/INCLUDE/blaswrap.h"
    "${CLAPACK_ROOT}/INCLUDE/clapack.h"
    "${CLAPACK_ROOT}/INCLUDE/f2c.h"
    DESTINATION include
)