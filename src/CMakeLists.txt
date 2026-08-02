# src/CMakeLists.txt

add_library(wispconfig STATIC
    config/config.cpp
)

target_include_directories(wispconfig
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/config
        ${CMAKE_SOURCE_DIR}/src
    PRIVATE
        ${CMAKE_SOURCE_DIR}/third_party
)

# --- wisp Executable ---
add_executable(wisp main.cpp)

target_link_libraries(wisp PRIVATE wispconfig)

target_compile_definitions(wisp PRIVATE
    WISP_VERSION="${PROJECT_VERSION}"
    WISP_DEFAULT_QML_DIR="${CMAKE_SOURCE_DIR}/qml"
    WISP_QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml"
)