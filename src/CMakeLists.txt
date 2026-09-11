# -----------------------------------------------------------------------------
# vscode_WinApp sources: corelib (static/shared switchable) + Win32 GUI app
# -----------------------------------------------------------------------------

# --- corelib: BUILD_SHARED_LIBS decides .lib vs .dll ---------------------------
add_library(corelib
    corelib/app_core.cpp
)
add_library(app::corelib ALIAS corelib)

target_include_directories(corelib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/corelib>
        $<INSTALL_INTERFACE:include>
)

# DLL export plumbing (see app_core.h); static builds need none of these.
if(BUILD_SHARED_LIBS)
    target_compile_definitions(corelib PRIVATE WAP_BUILDING)
    target_compile_definitions(corelib INTERFACE WAP_SHARED)
endif()

# --- app: Win32 GUI executable --------------------------------------------------
add_executable(WinApp WIN32
    app/main.cpp
)
target_link_libraries(WinApp PRIVATE app::corelib)


# --- install layout --------------------------------------------------------------
install(TARGETS WinApp corelib
    RUNTIME DESTINATION .           # exe (+ dll when BUILD_SHARED_LIBS=ON)
    LIBRARY DESTINATION .
    ARCHIVE DESTINATION .           # import/static libs
)
install(FILES corelib/app_core.h DESTINATION include)
