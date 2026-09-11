cmake_minimum_required(VERSION 3.21)

project(vscode_WinApp
    VERSION 1.0.0
    DESCRIPTION "Windows user-mode application template: CMake + Ninja, MSVC/Clang/Arkari toolchains, static/dynamic linking"
    LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# All CMake machinery (MSVC/SDK discovery, toolchains) lives in cmake/;
# toolchain files are wired up through CMakePresets.json.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# -----------------------------------------------------------------------------
# Static / dynamic linking (freely configurable)
# -----------------------------------------------------------------------------
# On this branch the Qt kit is chosen FIRST (it may force the CRT choice to
# match how the kit was built), then the runtime mapping is evaluated.
set(APP_QT_LINK "static" CACHE STRING "Qt kit linkage: static or dynamic")
set_property(CACHE APP_QT_LINK PROPERTY STRINGS static dynamic)
set(APP_QT_ROOT "D:/Qt/5.15.2" CACHE PATH
    "Qt root containing msvc2019_64 and msvc2019_64_static")

if(APP_QT_LINK STREQUAL "static")
    set(_qt_kit "${APP_QT_ROOT}/msvc2019_64_static")
    # Static Qt is built against the static CRT; force /MT to avoid LNK2038.
    set(APP_RUNTIME_LINK "static" CACHE STRING "" FORCE)
else()
    set(_qt_kit "${APP_QT_ROOT}/msvc2019_64")
    # The shared kit is built against /MD; force the dynamic CRT to match.
    set(APP_RUNTIME_LINK "dynamic" CACHE STRING "" FORCE)
endif()
list(PREPEND CMAKE_PREFIX_PATH "${_qt_kit}")

# 1) C runtime linkage:  static (/MT, /MTd)  vs  dynamic (/MD, /MDd).
#    Maps onto CMAKE_MSVC_RUNTIME_LIBRARY (CMP0091, NEW for >= 3.15 policies).
set(APP_RUNTIME_LINK "static" CACHE STRING "C runtime linkage: static (/MT) or dynamic (/MD)")
set_property(CACHE APP_RUNTIME_LINK PROPERTY STRINGS static dynamic)
if(APP_RUNTIME_LINK STREQUAL "static")
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
else()
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

# 2) Project libraries: the standard CMake switch -- corelib becomes a DLL
#    when ON, a static .lib when OFF (default).
option(BUILD_SHARED_LIBS "Build project libraries as DLLs instead of static libs" OFF)

# -----------------------------------------------------------------------------
# Qt (this branch): the kit selected above is resolved and consumed here.
#   APP_QT_LINK static  -> everything folded into the exe (QWindowsIntegration
#                          plugin imported in src/app/main.cpp)
#   APP_QT_LINK dynamic -> exe depends on Qt5*.dll; deploy with windeployqt
# -----------------------------------------------------------------------------

find_package(Qt5 5.15 REQUIRED COMPONENTS Core Gui Widgets)
message(STATUS "Qt5      : ${Qt5Core_VERSION} @ ${_qt_kit} (${APP_QT_LINK})")
set(CMAKE_AUTOMOC ON)

# -----------------------------------------------------------------------------
add_subdirectory(src)

# Mirror the compile database to the source root after every build so clangd
# (and any ancestor-lookup consumer) finds it without build-dir gymnastics.
# Reflects the last built preset; VSCode's cmake.copyCompileCommands covers
# the configure-time path. Root copy is gitignored.
if(CMAKE_EXPORT_COMPILE_COMMANDS)
    add_custom_target(update-compile-commands ALL
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_BINARY_DIR}/compile_commands.json"
            "${CMAKE_SOURCE_DIR}/compile_commands.json"
        COMMENT "Refreshing root compile_commands.json (clangd)")
endif()
