#pragma once
// vscode_WinApp corelib -- build/link configuration reporter.

#include <string>

// dllexport/dllimport only when built as a DLL (BUILD_SHARED_LIBS=ON); the
// CMake target defines WAP_BUILDING while compiling the lib itself (PRIVATE)
// and WAP_SHARED for consumers (INTERFACE). WAP_BUILDING must take precedence:
// the lib's own TU does NOT see the INTERFACE define, and an empty WAP_API
// would silently export nothing -- link.exe then skips the import library
// entirely and the exe link fails with LNK2019/LNK1104.
#if defined(WAP_BUILDING)
#  define WAP_API __declspec(dllexport)
#elif defined(WAP_SHARED)
#  define WAP_API __declspec(dllimport)
#else
#  define WAP_API
#endif

namespace app
{

// Multi-line build report: compiler, CRT linkage (static/dynamic),
// library linkage (static/shared).
WAP_API std::string BuildInfo();

} // namespace app
