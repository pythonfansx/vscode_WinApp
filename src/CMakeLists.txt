add_library(WinAppShared SHARED
    lib/winapp.cpp
    include/winapp/winapp.h
)
add_library(WinApp::Shared ALIAS WinAppShared)

set_target_properties(WinAppShared PROPERTIES
    OUTPUT_NAME winapp_shared
    EXPORT_NAME Shared
)

target_compile_definitions(WinAppShared PRIVATE WINAPP_SHARED_BUILD)
target_include_directories(WinAppShared
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

install(TARGETS WinAppShared
    EXPORT WinAppSharedTargets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    INCLUDES DESTINATION include
)
install(DIRECTORY include/ DESTINATION include)
install(EXPORT WinAppSharedTargets
    FILE WinAppSharedTargets.cmake
    NAMESPACE WinApp::
    DESTINATION lib/cmake/WinAppShared
)

include(CMakePackageConfigHelpers)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/WinAppSharedConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppSharedConfig.cmake"
    INSTALL_DESTINATION lib/cmake/WinAppShared
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppSharedConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppSharedConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/WinAppSharedConfigVersion.cmake"
    DESTINATION lib/cmake/WinAppShared
)
