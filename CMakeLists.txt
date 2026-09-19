# CMakeLists.txt

cmake_minimum_required(VERSION 3.16)
project(wisp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)
qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(WISP_SHARE_DIR "/usr/share/wisp" CACHE PATH "Fixed install location for wisp's QML tree")

# Helper function to define standard Wisp QML modules
function(add_wisp_qml_module target_name uri_name module_dir source_name)
    qt_add_qml_module(${target_name}
        URI Wisp.${uri_name}
        OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/${uri_name}
        SOURCES
            src/${module_dir}/${source_name}.hpp
            src/${module_dir}/${source_name}.cpp
    )

    target_include_directories(${target_name} PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/src/${module_dir}
    )

    target_link_libraries(${target_name} PRIVATE
        Qt6::Core
        Qt6::Qml
    )
endfunction()

# --- wisptime QML module ---
add_wisp_qml_module(wisptime Time backend/time time)

# --- wispSystem QML module ---
add_wisp_qml_module(wispsystem System backend/systemMonitor systemMonitor)

# --- wispBrightness QML module ---
add_wisp_qml_module(wispbrightness Brightness backend/brightness brightness)

# --- wispCalendar QML module ---
add_wisp_qml_module(wispcalendar Calendar backend/calendar calendar)

# --- wisplogcore: plain C++ logging ---
add_library(wisplogcore STATIC
    src/logging/log.cpp
)

target_include_directories(wisplogcore PUBLIC
    ${CMAKE_SOURCE_DIR}/src
)

set_target_properties(wisplogcore PROPERTIES POSITION_INDEPENDENT_CODE ON)

# --- wispLog QML module ---
add_wisp_qml_module(wisplog Log backend/logger logger)
target_link_libraries(wisplog PRIVATE wisplogcore)

# --- wispconfig library ---
add_library(wispconfig STATIC
    src/config/config.cpp
)

target_include_directories(wispconfig
    PUBLIC
        ${CMAKE_SOURCE_DIR}/src/config
        ${CMAKE_SOURCE_DIR}/src
    PRIVATE
        ${CMAKE_SOURCE_DIR}/third_party
)

# --- Version header from git ---
set(WISP_VERSION_HEADER ${CMAKE_BINARY_DIR}/generated/version.hpp)

add_custom_target(wisp_version_header ALL
    COMMAND ${CMAKE_COMMAND}
        -DSRC_DIR=${CMAKE_SOURCE_DIR}
        -DOUTPUT_FILE=${WISP_VERSION_HEADER}
        -P ${CMAKE_SOURCE_DIR}/cmake/GenerateVersionHeader.cmake
    BYPRODUCTS ${WISP_VERSION_HEADER}
    COMMENT "Checking git version"
    VERBATIM
)

# --- wispVersion QML module ---
add_wisp_qml_module(wispversion Version backend/version versionInfo)
add_dependencies(wispversion wisp_version_header)
target_include_directories(wispversion PRIVATE ${CMAKE_BINARY_DIR}/generated)

# --- wisp Executable ---
add_executable(wisp
    src/main.cpp
    src/ipc/ipc.cpp
    src/process/pidfile.cpp
    src/process/supervisor.cpp
    src/process/control.cpp
    src/bar/bar.cpp
    src/cli/logCommand.cpp
    src/cli/args.cpp
)

add_dependencies(wisp wisp_version_header)
target_include_directories(wisp PRIVATE ${CMAKE_BINARY_DIR}/generated)

target_link_libraries(wisp PRIVATE wispconfig wisplogcore)

target_compile_definitions(wisp PRIVATE
    WISP_DEFAULT_QML_DIR="${WISP_SHARE_DIR}/qml"
    WISP_QML_IMPORT_PATH="${WISP_SHARE_DIR}/qml"
    WISP_SHARE_DIR="${WISP_SHARE_DIR}"
)

# --- Install: QML tree ---
install(DIRECTORY ${CMAKE_SOURCE_DIR}/qml/
    DESTINATION ${WISP_SHARE_DIR}/qml
)

install(DIRECTORY ${CMAKE_BINARY_DIR}/qml/
    DESTINATION ${WISP_SHARE_DIR}/qml
)

install(DIRECTORY ${CMAKE_SOURCE_DIR}/scripts/
    DESTINATION ${WISP_SHARE_DIR}/scripts
    USE_SOURCE_PERMISSIONS
)

install(DIRECTORY ${CMAKE_SOURCE_DIR}/config/matugen/
    DESTINATION ${WISP_SHARE_DIR}/matugen
    USE_SOURCE_PERMISSIONS
)

install(DIRECTORY ${CMAKE_SOURCE_DIR}/assets/
    DESTINATION ${WISP_SHARE_DIR}/assets
    USE_SOURCE_PERMISSIONS
)
