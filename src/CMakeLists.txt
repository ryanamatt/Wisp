# src/CMakeLists.txt

add_executable(wisp main.cpp)

target_compile_definitions(wisp PRIVATE
    WISP_VERSION="${PROJECT_VERSION}"
    WISP_DEFAULT_QML_DIR="${CMAKE_SOURCE_DIR}/qml"
    WISP_QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml"
)
