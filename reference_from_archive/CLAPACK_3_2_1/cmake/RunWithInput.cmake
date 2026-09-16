if(NOT DEFINED TEST_EXECUTABLE OR NOT EXISTS "${TEST_EXECUTABLE}")
    message(FATAL_ERROR "TEST_EXECUTABLE does not exist: ${TEST_EXECUTABLE}")
endif()

if(NOT DEFINED TEST_INPUT OR NOT EXISTS "${TEST_INPUT}")
    message(FATAL_ERROR "TEST_INPUT does not exist: ${TEST_INPUT}")
endif()

if(DEFINED TEST_WORKING_DIRECTORY)
    file(MAKE_DIRECTORY "${TEST_WORKING_DIRECTORY}")
endif()

if(DEFINED TEST_REPORT)
    if(IS_ABSOLUTE "${TEST_REPORT}")
        set(test_report_path "${TEST_REPORT}")
    elseif(DEFINED TEST_WORKING_DIRECTORY)
        set(test_report_path "${TEST_WORKING_DIRECTORY}/${TEST_REPORT}")
    else()
        set(test_report_path "${CMAKE_CURRENT_BINARY_DIR}/${TEST_REPORT}")
    endif()
    file(REMOVE "${test_report_path}")
endif()

if(DEFINED TEST_WORKING_DIRECTORY)
    execute_process(
        COMMAND "${TEST_EXECUTABLE}"
        INPUT_FILE "${TEST_INPUT}"
        WORKING_DIRECTORY "${TEST_WORKING_DIRECTORY}"
        RESULT_VARIABLE test_result
        OUTPUT_VARIABLE test_stdout
        ERROR_VARIABLE test_stderr
    )
else()
    execute_process(
        COMMAND "${TEST_EXECUTABLE}"
        INPUT_FILE "${TEST_INPUT}"
        RESULT_VARIABLE test_result
        OUTPUT_VARIABLE test_stdout
        ERROR_VARIABLE test_stderr
    )
endif()

set(test_output "${test_stdout}${test_stderr}")
if(DEFINED TEST_REPORT)
    if(NOT EXISTS "${test_report_path}")
        message(FATAL_ERROR "Test report was not created: ${test_report_path}")
    endif()
    file(READ "${test_report_path}" test_report_output)
    string(APPEND test_output "${test_report_output}")
endif()
message("${test_output}")

if(DEFINED TEST_OUTPUT)
    get_filename_component(test_output_directory "${TEST_OUTPUT}" DIRECTORY)
    file(MAKE_DIRECTORY "${test_output_directory}")
    file(WRITE "${TEST_OUTPUT}" "${test_output}")
endif()

if(NOT test_result EQUAL 0)
    message(FATAL_ERROR "Test process exited with code ${test_result}")
endif()

if(DEFINED REQUIRED_REGEX AND NOT test_output MATCHES "${REQUIRED_REGEX}")
    message(FATAL_ERROR
        "Test output did not match required expression: ${REQUIRED_REGEX}")
endif()

if(DEFINED FORBIDDEN_REGEX AND test_output MATCHES "${FORBIDDEN_REGEX}")
    message(FATAL_ERROR
        "Test output matched forbidden expression: ${FORBIDDEN_REGEX}")
endif()