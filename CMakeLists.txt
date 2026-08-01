# CMakeLists.txt

cmake_minimum_required(VERSION 3.16)

project(wisp VERSION 0.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)
qt_standard_project_setup()

# Put the wisp binary directly at build/wisp instead of build/src/wisp.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

add_subdirectory(backend/time)

# The `wisp` CLI executable itself.
add_subdirectory(src)