# vscode_WinApp — template/qt

Qt 5.15 Widgets GUI 模板。纯 **CMake + Ninja**，支持 MSVC、上游 clang-cl 和 Arkari clang-cl；Qt 静态/动态 kit 与 CRT 自动配对。

## 链接模型

| `APP_QT_LINK` | Qt kit | CRT | 产物 |
|---|---|---|---|
| `static`（默认） | `msvc2019_64_static` | `/MT` | Qt、平台插件和 CRT 折入单个 EXE |
| `dynamic` | `msvc2019_64` | `/MD` | EXE 依赖 Qt5 DLL 与 VC Runtime |

静态模式显式链接 `Qt5::QWindowsIntegrationPlugin`，并由 `Q_IMPORT_PLUGIN` 注册。不能用“插件 target 是否存在”判断静态 Qt，因为动态 kit 同样导出该 target，但它指向 DLL。

## Qt 路径

推荐指定 Qt 根目录；其下必须同时或分别包含对应 kit：

```powershell
$env:QT_ROOT = "<Qt 5.15.2 根目录>"
```

也可设置环境变量 `QT_ROOT`。若两者均未设置，可直接让 `CMAKE_PREFIX_PATH` 指向已经选好的 kit。

## 构建

```powershell
$env:QT_ROOT = "<Qt 5.15.2 根目录>"

# MSVC + 静态 Qt
cmake --preset msvc-release --fresh
cmake --build --preset msvc-release

# 上游 LLVM + 动态 Qt
cmake --preset clang-release --fresh `
  -DCLANG_DIR=<LLVM bin目录> `
  -DAPP_QT_LINK=dynamic
cmake --build --preset clang-release

# Arkari + 静态 Qt
cmake --preset arkari-release --fresh `
  -DARKARI_DIR=<Arkari bin目录>
cmake --build --preset arkari-release
```

产物：`out/build/<preset>/src/WinAppQt.exe`。

动态 Qt 部署：

```powershell
& "$env:QT_ROOT/msvc2019_64/bin/windeployqt.exe" out/build/msvc-release/src/WinAppQt.exe
```

## 工程结构

- `src/app/main.cpp`：Qt Widgets 窗口与静态平台插件导入
- `src/corelib/`：示例业务库；`BUILD_SHARED_LIBS=OFF|ON` 控制 `.lib/.dll`
- `cmake/toolchains/llvm-cl-common.cmake`：clang-cl/Arkari 共用解析、resource-dir 与 SDK 层
- `.vscode/`：CMake Tools + clangd；无编辑器私有机器路径 fallback

## 模板分支

| 分支 | 交付形态 |
|---|---|
| `main` | 原生 Win32 GUI EXE |
| `template/console` | 控制台 EXE |
| `template/static-lib` | 静态库 |
| `template/shared-lib` | Windows DLL |
| `template/qt` | Qt Widgets GUI（本分支） |
