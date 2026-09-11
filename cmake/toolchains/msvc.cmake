# -----------------------------------------------------------------------------
# Toolchain: Microsoft MSVC (cl.exe) -- user-mode applications
#
# Pure cmake + ninja + toolchain: compilers and include directories are
# resolved to absolute paths (see cmake/LocateMSVC.cmake) and baked into the
# build files; link rules carry explicit /LIBPATH flags for the CRT/SDK
# libraries. No Visual Studio developer prompt, no vcvars, no shell wrapper
# is required -- `cmake --preset msvc-debug && cmake --build --preset msvc-debug`
# works from any shell.
#
# Overridable inputs (cache variable or environment variable):
#   MSVC_VS_DIR     Exact VS installation directory
#   WIN_KITS_ROOT   Windows Kits root
# -----------------------------------------------------------------------------

include("${CMAKE_CURRENT_LIST_DIR}/../LocateMSVC.cmake")

set(CMAKE_C_COMPILER   "${MSVC_CL}")
set(CMAKE_CXX_COMPILER "${MSVC_CL}")

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
