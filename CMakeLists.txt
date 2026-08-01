cmake_minimum_required(VERSION 3.16)

project(wisptime LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)

qt_standard_project_setup()

# Builds a QML module (Wisp.Time) with our Time singleton registered via
# QML_ELEMENT/QML_SINGLETON in time.hpp. qt_add_qml_module auto-generates
# the qmldir/qmltypes and lays the output out as Wisp/Time/ under the
# build tree's QML output dir, matching the URI below.
# OUTPUT_DIRECTORY matters here: QML import resolution expects a module
# with URI "Wisp.Time" to live under a "Wisp/Time/" directory (dots in the
# URI map to path separators). Without this, qt_add_qml_module just dumps
# the qmldir/plugin flat into CMAKE_CURRENT_BINARY_DIR, which is why
# quickshell couldn't find it.
qt_add_qml_module(wisptime
    URI Wisp.Time
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Time
    SOURCES
        time.hpp
        time.cpp
)

target_link_libraries(wisptime PRIVATE
    Qt6::Core
    Qt6::Qml
)