# CMakeLists.txt

cmake_minimum_required(VERSION 3.16)

project(wisp VERSION 0.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)
qt_standard_project_setup()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# --- wisptime QML module ---
qt_add_qml_module(wisptime
    URI Wisp.Time
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Time
    SOURCES
        backend/time/time.hpp
        backend/time/time.cpp
)

target_include_directories(wisptime PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/backend/time
)

target_link_libraries(wisptime PRIVATE
    Qt6::Core
    Qt6::Qml
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

# --- wisp Executable ---
add_executable(wisp src/main.cpp)

target_link_libraries(wisp PRIVATE wispconfig)

target_compile_definitions(wisp PRIVATE
    WISP_VERSION="${PROJECT_VERSION}"
    WISP_DEFAULT_QML_DIR="${CMAKE_SOURCE_DIR}/qml"
    WISP_QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml"
)
