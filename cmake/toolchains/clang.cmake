# -----------------------------------------------------------------------------
# Leaf toolchain: upstream LLVM (clang-cl.exe + lld-link.exe).
#
# CMakePresets.json selects this file before project(). Shared compiler/linker
# resolution and MSVC/Windows SDK setup live in llvm-cl-common.cmake.
#
# Required input (cache variable or environment variable):
#   CLANG_DIR   bin directory containing clang-cl.exe and lld-link.exe
# -----------------------------------------------------------------------------

set(WINAPP_LLVM_DIR_VARIABLE "CLANG_DIR")
set(WINAPP_LLVM_TOOLCHAIN_NAME "LLVM")
include("${CMAKE_CURRENT_LIST_DIR}/llvm-cl-common.cmake")
