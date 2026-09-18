# vscode_WinApp — template/console

最小 Windows 控制台 EXE 模板。纯 **CMake + Ninja**，支持 MSVC、上游 clang-cl 和 Arkari clang-cl；不依赖 Visual Studio Developer Prompt、vcvars、cmd 或 PowerShell 包装。

## 目标

- 目标：`WinAppConsole.exe`
- C++17
- `APP_RUNTIME_LINK=static|dynamic` 控制 `/MT` 或 `/MD`
- 构建后自动刷新根目录 `compile_commands.json`
- VSCode 只推荐 CMake Tools 与 clangd

## 构建

```powershell
cmake --preset msvc-debug --fresh
cmake --build --preset msvc-debug

cmake --preset clang-release --fresh -DCLANG_DIR=D:/path/to/llvm/bin
cmake --build --preset clang-release

cmake --preset arkari-release --fresh -DARKARI_DIR=D:/path/to/arkari/bin
cmake --build --preset arkari-release
```

动态 CRT：

```powershell
cmake --preset msvc-release --fresh -DAPP_RUNTIME_LINK=dynamic
cmake --build --preset msvc-release
```

产物：`out/build/<preset>/src/WinAppConsole.exe`。运行后输出实际编译器和 CRT 链接方式。

## 安装

```powershell
cmake --install out/build/msvc-release
```

安装产物位于 `out/install/msvc-release/WinAppConsole.exe`。

## 模板分支

| 分支 | 交付形态 |
|---|---|
| `main` | 原生 Win32 GUI EXE |
| `template/console` | 控制台 EXE（本分支） |
| `template/static-lib` | 静态库 |
| `template/shared-lib` | Windows DLL |
| `template/qt` | Qt Widgets GUI |
