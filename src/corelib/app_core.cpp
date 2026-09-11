// -----------------------------------------------------------------------------
// corelib - sample project library demonstrating the static/dynamic switch.
//
//   BUILD_SHARED_LIBS=OFF (default) -> static .lib folded into the app
//   BUILD_SHARED_LIBS=ON            -> corelib.dll + import lib
//
// The CRT linkage is orthogonal and controlled by APP_RUNTIME_LINK.
// -----------------------------------------------------------------------------

#include "app_core.h"

#include <string>

#if defined(_MSC_VER) && !defined(__clang__)
#  define WAP_STR2(x) #x
#  define WAP_STR(x)  WAP_STR2(x)
#  define WAP_COMPILER "MSVC " WAP_STR(_MSC_VER)
#elif defined(__clang__)
#  define WAP_STR2(x) #x
#  define WAP_STR(x)  WAP_STR2(x)
#  define WAP_COMPILER "clang-cl " WAP_STR(__clang_major__) "." WAP_STR(__clang_minor__)
#else
#  define WAP_COMPILER "unknown"
#endif

namespace
{

std::string RuntimeLinkage()
{
#if defined(_DLL)
    return "dynamic (/MD)";
#else
    return "static (/MT)";
#endif
}

std::string LibraryLinkage()
{
#if defined(WAP_SHARED)
    return "shared (corelib.dll)";
#else
    return "static (corelib.lib)";
#endif
}

} // namespace

namespace app
{

std::string BuildInfo()
{
    std::string info;
    info.reserve(160);
    info += "vscode_WinApp corelib\n";
    info += "compiler  : ";
    info += WAP_COMPILER;
    info += "\nCRT link  : ";
    info += RuntimeLinkage();
    info += "\nlib link  : ";
    info += LibraryLinkage();
    info += "\n";
    return info;
}

} // namespace app
