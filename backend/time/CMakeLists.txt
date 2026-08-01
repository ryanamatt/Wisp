# backend/time/CMakeLists.txt

qt_add_qml_module(wisptime
    URI Wisp.Time
    # VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Wisp/Time
    SOURCES
        time.hpp
        time.cpp
)

target_link_libraries(wisptime PRIVATE
    Qt6::Core
    Qt6::Qml
)