cmake_minimum_required(VERSION 3.21)

# CMake 4.x 兼容：Qt 6.5 的工程脚本基于旧策略
set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "" FORCE)

project(devboard-qt VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(devboard-qt
    src/main.cpp
    src/core/AdbClient.h
    src/core/AdbClient.cpp
)

qt_add_qml_module(devboard-qt
    URI devboard
    VERSION 1.0
    QML_FILES
        src/ui/qml/Main.qml
)

target_link_libraries(devboard-qt PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
)

# Windows GUI 程序（无控制台）
set_target_properties(devboard-qt PROPERTIES
    WIN32_EXECUTABLE TRUE
)

install(TARGETS devboard-qt
    RUNTIME DESTINATION .
)
