# -----------------------------------------------------------------------------
# Toolchain: LLVM (clang-cl.exe + lld-link.exe), MSVC-compatible ABI
#            -- user-mode applications
#
# Same env-free cmake + ninja + toolchain approach as msvc.cmake (see
# cmake/LocateMSVC.cmake for the MSVC/SDK discovery and the /LIBPATH flags).
#
# clang-cl resolution order:
#   1. CLANG_DIR cache variable     cmake --preset clang-debug -DCLANG_DIR=...
#   2. CLANG_DIR environment variable
#   3. PATH                          (directory containing clang-cl.exe)
#
# Overridable inputs (cache or environment):
#   MSVC_VS_DIR     Exact VS installation directory (headers/libs come from MSVC)
#   WIN_KITS_ROOT   Windows Kits root
# -----------------------------------------------------------------------------

set(_clang_dir "")
if(DEFINED CLANG_DIR)
    set(_clang_dir "${CLANG_DIR}")
elseif(DEFINED ENV{CLANG_DIR})
    set(_clang_dir "$ENV{CLANG_DIR}")
endif()

if(_clang_dir STREQUAL "")
    find_program(CLANG_CL_EXE clang-cl.exe REQUIRED)
    get_filename_component(_clang_dir "${CLANG_CL_EXE}" DIRECTORY)
else()
    if(NOT EXISTS "${_clang_dir}/clang-cl.exe")
        message(FATAL_ERROR "clang-cl.exe not found in CLANG_DIR='${_clang_dir}'")
    endif()
    set(CLANG_CL_EXE "${_clang_dir}/clang-cl.exe")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../LocateMSVC.cmake")

set(CMAKE_C_COMPILER   "${CLANG_CL_EXE}")
set(CMAKE_CXX_COMPILER "${CLANG_CL_EXE}")

find_program(CLANG_LLD_LINK lld-link.exe HINTS "${_clang_dir}" REQUIRED)
set(CMAKE_LINKER "${CLANG_LLD_LINK}")

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
