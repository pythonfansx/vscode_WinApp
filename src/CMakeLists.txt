add_executable(WinAppConsole
    app/main.cpp
)

install(TARGETS WinAppConsole
    RUNTIME DESTINATION .
)
