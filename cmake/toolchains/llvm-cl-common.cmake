# -----------------------------------------------------------------------------
# Shared implementation for MSVC-ABI LLVM toolchains.
#
# Leaf toolchains must define:
#   WINAPP_LLVM_DIR_VARIABLE   cache/environment variable containing the bin
#                              directory (for example CLANG_DIR)
#   WINAPP_LLVM_TOOLCHAIN_NAME human-readable name used in diagnostics
#
# This file owns compiler/linker resolution and the shared MSVC/Windows SDK
# setup. It is internal; CMakePresets.json selects a leaf toolchain instead.
# -----------------------------------------------------------------------------

if(NOT DEFINED WINAPP_LLVM_DIR_VARIABLE OR
   "${WINAPP_LLVM_DIR_VARIABLE}" STREQUAL "")
    message(FATAL_ERROR "LLVM leaf toolchain did not set WINAPP_LLVM_DIR_VARIABLE")
endif()
if(NOT DEFINED WINAPP_LLVM_TOOLCHAIN_NAME OR
   "${WINAPP_LLVM_TOOLCHAIN_NAME}" STREQUAL "")
    set(WINAPP_LLVM_TOOLCHAIN_NAME "LLVM")
endif()

# Toolchain files are reloaded in CMake's compiler-ABI try_compile projects.
# Forward a cache-provided compiler root explicitly; environment variables are
# inherited naturally, but -DCLANG_DIR/-DARKARI_DIR otherwise disappear.
if(NOT "${WINAPP_LLVM_DIR_VARIABLE}" IN_LIST CMAKE_TRY_COMPILE_PLATFORM_VARIABLES)
    list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
        "${WINAPP_LLVM_DIR_VARIABLE}")
endif()

set(_winapp_llvm_bin_dir "")
if(DEFINED ${WINAPP_LLVM_DIR_VARIABLE} AND
   NOT "${${WINAPP_LLVM_DIR_VARIABLE}}" STREQUAL "")
    set(_winapp_llvm_bin_dir "${${WINAPP_LLVM_DIR_VARIABLE}}")
elseif(DEFINED ENV{${WINAPP_LLVM_DIR_VARIABLE}} AND
       NOT "$ENV{${WINAPP_LLVM_DIR_VARIABLE}}" STREQUAL "")
    set(_winapp_llvm_bin_dir "$ENV{${WINAPP_LLVM_DIR_VARIABLE}}")
else()
    message(FATAL_ERROR
        "${WINAPP_LLVM_DIR_VARIABLE} is required for "
        "${WINAPP_LLVM_TOOLCHAIN_NAME} and must point to the bin directory "
        "containing clang-cl.exe and lld-link.exe.")
endif()

cmake_path(CONVERT "${_winapp_llvm_bin_dir}"
    TO_CMAKE_PATH_LIST _winapp_llvm_bin_dir NORMALIZE)
set(_winapp_clang_cl "${_winapp_llvm_bin_dir}/clang-cl.exe")
set(_winapp_lld_link "${_winapp_llvm_bin_dir}/lld-link.exe")

if(NOT EXISTS "${_winapp_clang_cl}")
    message(FATAL_ERROR
        "${WINAPP_LLVM_TOOLCHAIN_NAME} clang-cl.exe not found at "
        "'${_winapp_clang_cl}'")
endif()
if(NOT EXISTS "${_winapp_lld_link}")
    message(FATAL_ERROR
        "${WINAPP_LLVM_TOOLCHAIN_NAME} lld-link.exe not found at "
        "'${_winapp_lld_link}'")
endif()

# Make the selected compiler's intrinsic headers explicit in the compilation
# database. clangd otherwise injects its own resource directory, which is wrong
# when the language server and clang-cl come from different LLVM builds.
execute_process(
    COMMAND "${_winapp_clang_cl}" -print-resource-dir
    RESULT_VARIABLE _winapp_resource_result
    OUTPUT_VARIABLE _winapp_resource_dir
    ERROR_VARIABLE _winapp_resource_error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE)
if(NOT _winapp_resource_result EQUAL 0 OR
   "${_winapp_resource_dir}" STREQUAL "")
    message(FATAL_ERROR
        "${WINAPP_LLVM_TOOLCHAIN_NAME} failed to report its resource "
        "directory: ${_winapp_resource_error}")
endif()
cmake_path(CONVERT "${_winapp_resource_dir}"
    TO_CMAKE_PATH_LIST _winapp_resource_dir NORMALIZE)
if(NOT EXISTS "${_winapp_resource_dir}/include/intrin.h")
    message(FATAL_ERROR
        "${WINAPP_LLVM_TOOLCHAIN_NAME} resource headers not found under "
        "'${_winapp_resource_dir}/include'")
endif()

set(_winapp_resource_flag "-resource-dir=${_winapp_resource_dir}")
foreach(_winapp_flags_var IN ITEMS CMAKE_C_FLAGS_INIT CMAKE_CXX_FLAGS_INIT)
    string(FIND "${${_winapp_flags_var}}"
        "${_winapp_resource_flag}" _winapp_resource_flag_index)
    if(_winapp_resource_flag_index EQUAL -1)
        string(APPEND ${_winapp_flags_var}
            " \"${_winapp_resource_flag}\"")
    endif()
endforeach()

include("${CMAKE_CURRENT_LIST_DIR}/../LocateMSVC.cmake")

set(CMAKE_C_COMPILER   "${_winapp_clang_cl}")
set(CMAKE_CXX_COMPILER "${_winapp_clang_cl}")
set(CMAKE_LINKER       "${_winapp_lld_link}")

if(MSVC_RC)
    set(CMAKE_RC_COMPILER "${MSVC_RC}")
endif()
if(MSVC_MT)
    set(CMAKE_MT "${MSVC_MT}")
endif()

# /I for every compile rule: MSVC + SDK headers without INCLUDE environment.
set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES   ${WINSDK_INCLUDE})
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${WINSDK_INCLUDE})

# /LIBPATH for every link rule: CRT/OS libraries without LIB environment.
string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT     "${MSVC_LIBPATH_FLAGS}")
string(APPEND CMAKE_SHARED_LINKER_FLAGS_INIT  "${MSVC_LIBPATH_FLAGS}")
string(APPEND CMAKE_MODULE_LINKER_FLAGS_INIT  "${MSVC_LIBPATH_FLAGS}")

unset(_winapp_llvm_bin_dir)
unset(_winapp_clang_cl)
unset(_winapp_lld_link)
unset(_winapp_resource_dir)
unset(_winapp_resource_error)
unset(_winapp_resource_flag)
unset(_winapp_resource_flag_index)
unset(_winapp_resource_result)
unset(_winapp_flags_var)
unset(WINAPP_LLVM_DIR_VARIABLE)
unset(WINAPP_LLVM_TOOLCHAIN_NAME)
