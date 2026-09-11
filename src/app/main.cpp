// -----------------------------------------------------------------------------
// vscode_WinApp -- Win32 GUI sample showing the build configuration
// (compiler / CRT linkage / library linkage) produced by corelib.
// -----------------------------------------------------------------------------

#include <windows.h>

#include <string>

#include "app_core.h"

namespace
{

std::wstring ToWide(const std::string& text)
{
    if (text.empty())
    {
        return std::wstring();
    }
    const int size = MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                         static_cast<int>(text.size()), nullptr, 0);
    std::wstring wide(static_cast<size_t>(size), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        wide.data(), size);
    return wide;
}

} // namespace

int WINAPI wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE /*prevInstance*/,
                    _In_ PWSTR /*cmdLine*/, _In_ int /*showCmd*/)
{
    UNREFERENCED_PARAMETER(instance);

    const std::wstring report = ToWide(app::BuildInfo());
    MessageBoxW(nullptr, report.c_str(), L"vscode_WinApp", MB_OK | MB_ICONINFORMATION);
    return 0;
}
