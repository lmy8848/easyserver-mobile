cmake_minimum_required(VERSION 3.16)
project(devboard-qt LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

# Widgets 而非 Quick：本机 Qt Quick 场景图渲染不可用（渲染循环启动后不绘制），
# Widgets 的 backing store 渲染正常，镜像走 scrcpy 子进程窗口嵌入。
find_package(Qt6 REQUIRED COMPONENTS Widgets)

qt_standard_project_setup()

qt_add_executable(devboard-qt
    src/main.cpp
    src/MainWindow.cpp src/MainWindow.h
    src/AdbClient.cpp src/AdbClient.h
    src/ScrcpyProcess.cpp src/ScrcpyProcess.h
    src/Panels.cpp src/Panels.h
)

target_link_libraries(devboard-qt PRIVATE Qt6::Widgets)

# 显式 GUI 子系统：否则 exe 启动时会带一个黑色控制台窗口（用户看到"两个窗口"）。
# 诊断信息仍由 main.cpp 的消息处理器写日志文件。
set_target_properties(devboard-qt PROPERTIES WIN32_EXECUTABLE TRUE)

# Windows 头文件需要（避免 min/max 宏、隐藏控制台）
target_compile_definitions(devboard-qt PRIVATE NOMINMAX)

if (WIN32)
    target_link_libraries(devboard-qt PRIVATE user32)
endif()

# 部署 Qt 运行时（windeployqt，避免手工复制 DLL）
if (WIN32)
    get_target_property(_qt_qmake Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qt_qmake}" DIRECTORY)
    add_custom_command(TARGET devboard-qt POST_BUILD
        COMMAND "${_qt_bin_dir}/windeployqt.exe" --release --no-translations
                "$<TARGET_FILE:devboard-qt>"
        COMMENT "Deploying Qt runtime via windeployqt"
    )
endif()
