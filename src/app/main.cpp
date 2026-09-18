#include <iostream>

#define WINAPP_STRINGIFY_IMPL(value) #value
#define WINAPP_STRINGIFY(value) WINAPP_STRINGIFY_IMPL(value)

namespace
{

const char* CompilerName() noexcept
{
#if defined(__clang__)
    return "clang-cl " WINAPP_STRINGIFY(__clang_major__) "." WINAPP_STRINGIFY(__clang_minor__);
#elif defined(_MSC_VER)
    return "MSVC " WINAPP_STRINGIFY(_MSC_VER);
#else
    return "unknown";
#endif
}

const char* RuntimeLinkage() noexcept
{
#if defined(_DLL)
    return "dynamic (/MD)";
#else
    return "static (/MT)";
#endif
}

} // namespace

int main()
{
    std::cout << "vscode_WinApp console executable\n"
              << "compiler : " << CompilerName() << '\n'
              << "CRT link : " << RuntimeLinkage() << '\n';
    return 0;
}
