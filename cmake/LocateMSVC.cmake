# -----------------------------------------------------------------------------
# LocateMSVC.cmake
#
# Pure-CMake discovery of the MSVC toolset and Windows SDK pieces needed to
# compile and link *outside* a Visual Studio developer prompt -- no vcvars,
# no cmd/PowerShell wrappers, no environment mutation. Everything downstream
# is baked into the build as absolute paths (/I include dirs, absolute
# compilers/linkers), so plain
#     cmake --preset <preset> && cmake --build --preset <preset>
# works from any shell (PowerShell, plain cmd, CI, VS Code).
#
# The only external helper is vswhere.exe (Microsoft's official VS discovery
# tool, invoked directly -- never through a shell). Set MSVC_VS_DIR to skip it.
#
# Overridable inputs (cache variable or environment variable):
#   MSVC_VS_DIR     Visual Studio installation directory (skips vswhere)
#   WIN_KITS_ROOT   Windows Kits root (default: C:/Program Files (x86)/Windows Kits/10)
#                   Inside a VS developer prompt the WindowsSdkDir /
#                   WindowsSDKVersion variables are honoured automatically.
#
# Outputs:
#   MSVC_TOOLSET_DIR   newest <VS>/VC/Tools/MSVC/<version> directory
#   MSVC_CL            absolute cl.exe
#   MSVC_RC            absolute rc.exe (empty when not found)
#   WINSDK_VERSION     e.g. 10.0.26100.0
#   WINSDK_INCLUDE     user-mode include dirs (MSVC + ucrt/um/shared/winrt/...)
# -----------------------------------------------------------------------------

if(MSVC_LOCATED)
    return()
endif()

# --- Visual Studio installation -----------------------------------------------
if(NOT DEFINED MSVC_VS_DIR)
    if(DEFINED ENV{MSVC_VS_DIR})
        set(MSVC_VS_DIR "$ENV{MSVC_VS_DIR}")
    else()
        # $ENV{...} cannot reference names containing parentheses -> indirection.
        set(_env_pfx86_name "ProgramFiles(x86)")
        set(_vswhere "$ENV{${_env_pfx86_name}}/Microsoft Visual Studio/Installer/vswhere.exe")
        if(NOT EXISTS "${_vswhere}")
            set(_vswhere "$ENV{ProgramFiles}/Microsoft Visual Studio/Installer/vswhere.exe")
        endif()
        if(NOT EXISTS "${_vswhere}")
            message(FATAL_ERROR
                "vswhere.exe not found. Set MSVC_VS_DIR (-D or env) to your "
                "Visual Studio installation directory.")
        endif()
        execute_process(
            COMMAND "${_vswhere}" -latest -products *
                    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
                    -property installationPath
            OUTPUT_VARIABLE MSVC_VS_DIR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE _vswhere_rc)
        if(NOT _vswhere_rc EQUAL 0 OR MSVC_VS_DIR STREQUAL "")
            message(FATAL_ERROR
                "vswhere found no Visual Studio with the C++ workload "
                "(Microsoft.VisualStudio.Component.VC.Tools.x86.x64).")
        endif()
    endif()
endif()

# --- newest MSVC toolset --------------------------------------------------------
file(GLOB _msvc_toolsets "${MSVC_VS_DIR}/VC/Tools/MSVC/*")
list(SORT _msvc_toolsets COMPARE NATURAL)
list(GET _msvc_toolsets -1 MSVC_TOOLSET_DIR)

set(MSVC_CL "${MSVC_TOOLSET_DIR}/bin/Hostx64/x64/cl.exe")
if(NOT EXISTS "${MSVC_CL}")
    message(FATAL_ERROR "cl.exe not found at '${MSVC_CL}' (VS: '${MSVC_VS_DIR}').")
endif()


# --- Windows SDK (user-mode headers for the compiler itself) --------------------
# Kernel-mode (km) include dirs are added per-target by FindWDK; what the
# compiler needs beyond those is the MSVC runtime + UCRT + SDK set below.
if(NOT DEFINED WIN_KITS_ROOT)
    if(DEFINED ENV{WindowsSdkDir})
        set(WIN_KITS_ROOT "$ENV{WindowsSdkDir}")
    else()
        set(WIN_KITS_ROOT "C:/Program Files (x86)/Windows Kits/10")
    endif()
endif()
if(NOT WIN_KITS_ROOT MATCHES "/$")
    string(APPEND WIN_KITS_ROOT "/")
endif()

if(NOT DEFINED WINSDK_VERSION)
    if(DEFINED ENV{WindowsSDKVersion})
        string(REGEX REPLACE "[/\\\\]$" "" WINSDK_VERSION "$ENV{WindowsSDKVersion}")
    else()
        file(GLOB _sdk_inc_dirs "${WIN_KITS_ROOT}Include/*")
        set(_sdk_versions "")
        foreach(_d IN LISTS _sdk_inc_dirs)
            if(IS_DIRECTORY "${_d}" AND EXISTS "${_d}/um/Windows.h")
                get_filename_component(_v "${_d}" NAME)
                list(APPEND _sdk_versions "${_v}")
            endif()
        endforeach()
        list(SORT _sdk_versions COMPARE NATURAL)
        list(GET _sdk_versions -1 WINSDK_VERSION)
    endif()
endif()
if(NOT WINSDK_VERSION)
    message(FATAL_ERROR "No Windows SDK found under '${WIN_KITS_ROOT}' (set WIN_KITS_ROOT).")
endif()

set(_sdk_inc "${WIN_KITS_ROOT}Include/${WINSDK_VERSION}")
set(_msvc_inc "${MSVC_TOOLSET_DIR}/include")

set(WINSDK_INCLUDE
    "${_msvc_inc}"
    "${_sdk_inc}/ucrt"
    "${_sdk_inc}/um"
    "${_sdk_inc}/shared"
    "${_sdk_inc}/winrt"
    "${_sdk_inc}/cppwinrt"
)

foreach(_d IN LISTS WINSDK_INCLUDE)
    if(NOT IS_DIRECTORY "${_d}")
        message(WARNING "Expected include directory is missing: ${_d}")
    endif()
endforeach()

set(MSVC_RC "")
set(MSVC_MT "")
if(EXISTS "${WIN_KITS_ROOT}bin/${WINSDK_VERSION}/x64/rc.exe")
    set(MSVC_RC "${WIN_KITS_ROOT}bin/${WINSDK_VERSION}/x64/rc.exe")
endif()
if(EXISTS "${WIN_KITS_ROOT}bin/${WINSDK_VERSION}/x64/mt.exe")
    set(MSVC_MT "${WIN_KITS_ROOT}bin/${WINSDK_VERSION}/x64/mt.exe")
endif()

# --- library directories --------------------------------------------------------
# User-mode builds link the default OS/CRT libraries (kernel32.lib, ucrt.lib,
# vcruntime.lib, ...) by NAME, so the linker needs search paths. Two paths
# keep the whole thing environment-free:
#   1. LIB is set inside the configure process for CMake's own try-compiles.
#   2. MSVC_LIBPATH_FLAGS bakes the same absolute dirs into every link rule
#      (CMAKE_*_LINKER_FLAGS_INIT in the toolchain files), so plain
#      `cmake --build` from any shell needs no VS developer prompt either.
set(MSVC_LIB_DIRS
    "${MSVC_TOOLSET_DIR}/lib/x64"
    "${WIN_KITS_ROOT}Lib/${WINSDK_VERSION}/ucrt/x64"
    "${WIN_KITS_ROOT}Lib/${WINSDK_VERSION}/um/x64"
)
set(_lib_env "")
set(MSVC_LIBPATH_FLAGS "")
foreach(_d IN LISTS MSVC_LIB_DIRS)
    if(IS_DIRECTORY "${_d}")
        file(TO_NATIVE_PATH "${_d}" _d_native)
        string(APPEND _lib_env "${_d_native};")
        string(APPEND MSVC_LIBPATH_FLAGS " /LIBPATH:\"${_d_native}\"")
    endif()
endforeach()
set(ENV{LIB} "${_lib_env}")

set(MSVC_LOCATED TRUE)
