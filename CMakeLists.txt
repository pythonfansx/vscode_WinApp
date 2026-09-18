cmake_minimum_required(VERSION 3.21)

project(vscode_WinApp_console
    VERSION 1.0.0
    DESCRIPTION "Minimal Windows console executable template"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(APP_RUNTIME_LINK "static" CACHE STRING "C runtime linkage: static (/MT) or dynamic (/MD)")
set_property(CACHE APP_RUNTIME_LINK PROPERTY STRINGS static dynamic)
if(NOT APP_RUNTIME_LINK STREQUAL "static" AND
   NOT APP_RUNTIME_LINK STREQUAL "dynamic")
    message(FATAL_ERROR "APP_RUNTIME_LINK must be 'static' or 'dynamic'")
endif()
if(APP_RUNTIME_LINK STREQUAL "static")
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
else()
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

add_subdirectory(src)

if(CMAKE_EXPORT_COMPILE_COMMANDS)
    add_custom_target(update-compile-commands ALL
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_BINARY_DIR}/compile_commands.json"
            "${CMAKE_SOURCE_DIR}/compile_commands.json"
        COMMENT "Refreshing root compile_commands.json (clangd)")
endif()
