# -----------------------------------------------------------------------------
# Leaf toolchain: Arkari LLVM (clang-cl.exe + lld-link.exe).
#
# Required input (cache variable or environment variable):
#   ARKARI_DIR   bin directory containing Arkari clang-cl.exe and lld-link.exe
#
# CMakePresets.json selects this file before project(). Shared compiler/linker
# resolution and MSVC/Windows SDK setup live in llvm-cl-common.cmake.
# -----------------------------------------------------------------------------

set(WINAPP_LLVM_DIR_VARIABLE "ARKARI_DIR")
set(WINAPP_LLVM_TOOLCHAIN_NAME "Arkari")
include("${CMAKE_CURRENT_LIST_DIR}/llvm-cl-common.cmake")

# Optional Arkari obfuscation passes (compile-only -mllvm options).
# Default ON with the full verified set; disable with -DARKARI_OBFUSCATION="".
set(ARKARI_OBFUSCATION
    "-mllvm -irobf-icall -mllvm -irobf-indbr -mllvm -irobf-indgv -mllvm -irobf-cse"
    CACHE STRING
    "Arkari obfuscation flags (default: full verified set; pass empty string to disable)")
if(NOT ARKARI_OBFUSCATION STREQUAL "")
    # Toolchain files may be evaluated more than once during compiler setup.
    # Append the space-separated option string once; using a CMake list would
    # inject semicolons and clang-cl would read it as one malformed argument.
    foreach(_arkari_flags_var IN ITEMS CMAKE_C_FLAGS_INIT CMAKE_CXX_FLAGS_INIT)
        string(FIND " ${${_arkari_flags_var}} "
            " ${ARKARI_OBFUSCATION} " _arkari_flags_index)
        if(_arkari_flags_index EQUAL -1)
            string(APPEND ${_arkari_flags_var} " ${ARKARI_OBFUSCATION}")
        endif()
    endforeach()
    unset(_arkari_flags_index)
    unset(_arkari_flags_var)
endif()
