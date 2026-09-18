add_library(WinAppStatic STATIC
    lib/winapp.cpp
    include/winapp/winapp.h
)
add_library(WinApp::Static ALIAS WinAppStatic)

set_target_properties(WinAppStatic PROPERTIES
    OUTPUT_NAME winapp_static
    EXPORT_NAME Static
)

target_include_directories(WinAppStatic
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

install(TARGETS WinAppStatic
    EXPORT WinAppStaticTargets
    ARCHIVE DESTINATION lib
    INCLUDES DESTINATION include
)
install(DIRECTORY include/ DESTINATION include)
install(EXPORT WinAppStaticTargets
    FILE WinAppStaticTargets.cmake
    NAMESPACE WinApp::
    DESTINATION lib/cmake/WinAppStatic
)

include(CMakePackageConfigHelpers)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/WinAppStaticConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppStaticConfig.cmake"
    INSTALL_DESTINATION lib/cmake/WinAppStatic
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppStaticConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppStaticConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppStaticConfigVersion.cmake"
    DESTINATION lib/cmake/WinAppStatic
)
