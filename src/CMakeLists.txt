# -----------------------------------------------------------------------------
# vscode_WinApp sources (template/qt): corelib + Qt Widgets app
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

# --- app: Qt Widgets executable --------------------------------------------------
add_executable(WinAppQt WIN32
    app/main.cpp
)
target_link_libraries(WinAppQt PRIVATE Qt5::Widgets app::corelib)
# Static kit: import the platform plugin into the executable (see the
# Q_IMPORT_PLUGIN block in app/main.cpp). NB: the SHARED kit also exposes a
# Qt5::QWindowsIntegrationPlugin target (pointing at the plugin DLL!) -- never
# detect "static" via TARGET existence, link it only for the static kit.
if(APP_QT_LINK STREQUAL "static")
    target_link_libraries(WinAppQt PRIVATE Qt5::QWindowsIntegrationPlugin)
endif()

# --- install layout --------------------------------------------------------------
install(TARGETS WinAppQt corelib
    RUNTIME DESTINATION .           # exe (+ dlls when BUILD_SHARED_LIBS=ON)
    LIBRARY DESTINATION .
    ARCHIVE DESTINATION .
)
install(FILES corelib/app_core.h DESTINATION include)

# Dynamic kit hint: after install, collect the Qt runtime next to the exe:
#   windeployqt out/install/<preset>/WinAppQt.exe
