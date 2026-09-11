# -----------------------------------------------------------------------------
# Toolchain: Arkari clang (https://github.com/KomiMoe/Arkari) -- obfuscating
# LLVM fork, MSVC-compatible ABI (clang-cl.exe + lld-link.exe),
# user-mode applications.
#
# Same env-free cmake + ninja + toolchain approach as clang.cmake, plus
# Arkari's obfuscation passes through one cache variable:
#
#   ARKARI_OBFUSCATION   space-separated -mllvm options. DEFAULT ON with the
#                        full verified set; disable with -DARKARI_OBFUSCATION="".
#                        Verified against Arkari 20.1.8 (81e7049e):
#                          -mllvm -irobf-icall    indirect calls
#                          -mllvm -irobf-indbr    indirect branches
#                          -mllvm -irobf-indgv    indirect global variables
#                          -mllvm -irobf-cse      common-subexpression-based obf
#                        (legacy OLLVM -bcf/-fla/-sub are NOT in Arkari)
#
# Examples:
#   cmake --preset arkari-debug   (obfuscation on by default)
#   cmake --preset arkari-release -DARKARI_OBFUSCATION=""   (off)
#
# Toolchain location resolution order:
#   1. ARKARI_DIR cache variable   (bin directory holding clang-cl.exe)
#   2. ARKARI_DIR environment variable
#   3. Default path below
#
# MSVC headers/libs and the SDK discovery come from cmake/LocateMSVC.cmake
# (MSVC_VS_DIR / WIN_KITS_ROOT apply here as well).
# -----------------------------------------------------------------------------

set(_arkari_default_dir "G:/opensource/Arkari/build_ninja/bin")

set(_arkari_dir "")
if(DEFINED ARKARI_DIR)
    set(_arkari_dir "${ARKARI_DIR}")
elseif(DEFINED ENV{ARKARI_DIR})
    set(_arkari_dir "$ENV{ARKARI_DIR}")
else()
    set(_arkari_dir "${_arkari_default_dir}")
endif()

if(NOT EXISTS "${_arkari_dir}/clang-cl.exe")
    message(FATAL_ERROR
        "Arkari clang-cl.exe not found in '${_arkari_dir}'. "
        "Set ARKARI_DIR (-D or env) to Arkari's build_ninja/bin directory.")
endif()

find_program(ARKARI_CLANG_CL clang-cl.exe HINTS "${_arkari_dir}" REQUIRED)
find_program(ARKARI_LLD_LINK lld-link.exe  HINTS "${_arkari_dir}" REQUIRED)

# MSVC environment (INCLUDE/LIB sources), toolset discovery, rc/mt.
include("${CMAKE_CURRENT_LIST_DIR}/../LocateMSVC.cmake")

set(CMAKE_C_COMPILER   "${ARKARI_CLANG_CL}")
set(CMAKE_CXX_COMPILER "${ARKARI_CLANG_CL}")
set(CMAKE_LINKER "${ARKARI_LLD_LINK}")

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

# Optional Arkari obfuscation passes (compile-only -mllvm options).
# Default ON with the full verified set; disable with -DARKARI_OBFUSCATION="".
set(ARKARI_OBFUSCATION
    "-mllvm -irobf-icall -mllvm -irobf-indbr -mllvm -irobf-indgv -mllvm -irobf-cse"
    CACHE STRING
    "Arkari obfuscation flags (default: full verified set; pass empty string to disable)")
if(NOT ARKARI_OBFUSCATION STREQUAL "")
    # String-append (a list would smuggle ';' into the flags and clang-cl
    # would swallow everything as one unknown argument).
    string(APPEND CMAKE_C_FLAGS_INIT   " ${ARKARI_OBFUSCATION}")
    string(APPEND CMAKE_CXX_FLAGS_INIT " ${ARKARI_OBFUSCATION}")
endif()
