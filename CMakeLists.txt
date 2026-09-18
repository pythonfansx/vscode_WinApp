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
# Template shapes live on dedicated branches:
#
#   main                 native Win32 GUI executable (this branch)
#   template/console     console executable
#   template/static-lib  static library
#   template/shared-lib  Windows DLL
#   template/qt          Qt Widgets GUI executable
#
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
