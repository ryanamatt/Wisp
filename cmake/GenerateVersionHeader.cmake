# cmake/GenerateVersionHeader.cmake

# Regenerates the version header from git on every build.

set(_version "0.0.0-unknown")
set(_commit "unknown")

find_package(Git QUIET)

if(GIT_EXECUTABLE)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --always --dirty
        WORKING_DIRECTORY ${SRC_DIR}
        OUTPUT_VARIABLE _describe
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE _result
        ERROR_QUIET
    )
    if(_result EQUAL 0 AND _describe)
        set(_version ${_describe})
    endif()

    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${SRC_DIR}
        OUTPUT_VARIABLE _commit_output
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE _commit_result
        ERROR_QUIET
    )
    if(_commit_result EQUAL 0 AND _commit_output)
        set(_commit ${_commit_output})
    endif()
endif()

string(TIMESTAMP _build_date "%Y-%m-%d %H:%M:%S" UTC)

set(_new_content "#pragma once\n#define WISP_VERSION \"${_version}\"\n#define WISP_COMMIT_HASH \"${_commit}\"\n#define WISP_BUILD_DATE \"${_build_date}\"\n")

if(EXISTS ${OUTPUT_FILE})
    file(READ ${OUTPUT_FILE} _old_content)
else()
    set(_old_content "")
endif()

if(NOT _old_content STREQUAL _new_content)
    file(WRITE ${OUTPUT_FILE} "${_new_content}")
endif()
