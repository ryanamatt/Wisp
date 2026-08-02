# backend/time/CMakeLists.txt

qt_add_qml_module(wisptime
    URI Wisp.Time
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Time
    SOURCES
        time.hpp
        time.cpp
)

target_include_directories(wisptime PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(wisptime PRIVATE
    Qt6::Core
    Qt6::Qml
)
