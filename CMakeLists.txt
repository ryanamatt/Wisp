# CMakeLists.txt

cmake_minimum_required(VERSION 3.16)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)
qt_standard_project_setup()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(WISP_SHARE_DIR "/usr/share/wisp" CACHE PATH "Fixed install location for wisp's QML tree")

# --- wisptime QML module ---
qt_add_qml_module(wisptime
    URI Wisp.Time
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Time
    SOURCES
        src/backend/time/time.hpp
        src/backend/time/time.cpp
)

target_include_directories(wisptime PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/backend/time
)

target_link_libraries(wisptime PRIVATE
    Qt6::Core
    Qt6::Qml
)

# --- wispSystem QML module ---
qt_add_qml_module(wispsystem
    URI Wisp.System
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/System
    SOURCES
        src/backend/systemMonitor/systemMonitor.hpp
        src/backend/systemMonitor/systemMonitor.cpp
)

target_include_directories(wispsystem PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/backend/systemMonitor
)

target_link_libraries(wispsystem PRIVATE
    Qt6::Core
    Qt6::Qml
)

# --- wispCalendar QML module ---
qt_add_qml_module(wispcalendar
    URI Wisp.Calendar
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Calendar
    SOURCES
        src/backend/calendar/calendar.hpp
        src/backend/calendar/calendar.cpp
)

target_include_directories(wispcalendar PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/backend/calendar
)

target_link_libraries(wispcalendar PRIVATE
    Qt6::Core
    Qt6::Qml
)

# --- wisplogcore: plain C++ logging, no Qt dependency ---
add_library(wisplogcore STATIC
    src/logging/log.cpp
)

target_include_directories(wisplogcore PUBLIC
    ${CMAKE_SOURCE_DIR}/src
)

set_target_properties(wisplogcore PROPERTIES POSITION_INDEPENDENT_CODE ON)

# --- wispLog QML module ---
qt_add_qml_module(wisplog
    URI Wisp.Log
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Log
    SOURCES
        src/backend/logger/logger.hpp
        src/backend/logger/logger.cpp
)

target_include_directories(wisplog PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/backend/logger
)

target_link_libraries(wisplog PRIVATE
    Qt6::Core
    Qt6::Qml
    wisplogcore
)

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
qt_add_qml_module(wispversion
    URI Wisp.Version
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Version
    SOURCES
        src/backend/version/versionInfo.hpp
        src/backend/version/versionInfo.cpp
)

add_dependencies(wispversion wisp_version_header)

target_include_directories(wispversion PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/backend/version
    ${CMAKE_BINARY_DIR}/generated
)

target_link_libraries(wispversion PRIVATE
    Qt6::Core
    Qt6::Qml
)

# --- wisp Executable ---
add_executable(wisp
    src/main.cpp
    src/ipc/ipc.cpp
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
