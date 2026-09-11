# vscode_WinApp — template/qt 分支（Qt Widgets 模板）

> 本分支为 **Qt 版 GUI 模板**：`APP_QT_LINK=static/dynamic` 一键切换 Qt 静态 kit（`msvc2019_64_static`，默认）
> 与动态 kit（`msvc2019_64`），CRT 跟随 kit 自动配对（静态 /MT、动态 /MD），cl.exe / clang-cl.exe 双链验证通过。
> Win32 基础模板见 `main`。

| `APP_QT_LINK` | kit | CRT（自动强制） | 实测产物 |
|---|---|---|---|
| `static`（默认） | `msvc2019_64_static` | `/MT` | 37.9MB 单文件 exe，导入表仅系统库（Qt 与 CRT 全折入） |
| `dynamic` | `msvc2019_64` | `/MD` | exe 导入 `Qt5Core/Qt5Widgets.dll + MSVCP140/VCRUNTIME140 + api-ms-win-crt-*`（windeployqt 部署） |

```powershell
cmake --preset msvc-debug                                   # 静态 Qt 单文件
cmake --preset msvc-release -DAPP_QT_LINK=dynamic           # 动态 Qt
```
自定义 kit：`-DAPP_QT_ROOT=<Qt根>`（含 `msvc2019_64[_static]`）或直接 `CMAKE_PREFIX_PATH`。
静态 kit 的平台插件由 `src/app/main.cpp` 的 `Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin)` 折入；
注意共享 kit 也导出同名插件 target（指向 DLL），故 `src/CMakeLists.txt` 用 `APP_QT_LINK` 而非
`if(TARGET ...)` 判静态——后者会把 qwindows.dll 链进链接线（LNK1107）。

# vscode_WinApp

## 目录结构

```
vscode_WinApp/
├── CMakeLists.txt            # 工程入口：CRT 静态/动态开关、BUILD_SHARED_LIBS、Qt 扩展点
├── CMakePresets.json         # msvc / clang / arkari × debug / release 六个 preset（全部 Ninja）
├── .clangd                   # clangd：--driver-mode=cl（根目录 compile_commands.json）
├── cmake/                    # 所有 CMake 相关内容都抽离在这里
│   ├── LocateMSVC.cmake      # 纯 CMake 定位 MSVC 工具集 / Windows SDK（vswhere + 文件探测）
│   │                         #   并产出 /LIBPATH 链接旗标（零环境依赖）
│   └── toolchains/
│       ├── msvc.cmake        # cl.exe
│       ├── clang.cmake       # clang-cl.exe + lld-link.exe
│       └── arkari.cmake      # Arkari clang-cl.exe + lld-link.exe（混淆默认开启）
├── src/
│   ├── CMakeLists.txt        # corelib + WinApp 目标与 install 规则
│   ├── corelib/              # 示例库：BUILD_SHARED_LIBS 决定 .lib / .dll
│   └── app/                  # Win32 GUI 样例（弹出构建配置报告）
└── .vscode/                  # 随仓库提交：IntelliSense、构建任务、推荐扩展
```

## 环境要求

| 组件 | 要求 |
|---|---|
| Visual Studio 2022 | 勾选 "使用 C++ 的桌面开发"（含 MSVC v143 工具集） |
| Windows SDK | 任意可发现版本（本机验证：10.0.26100.0） |
| CMake | ≥ 3.21 |
| Ninja | 在 PATH 中即可（VS 自带的 Ninja 也行） |
| LLVM（可选） | 含 `clang-cl.exe` + `lld-link.exe`；在 PATH 中，或用 `CLANG_DIR` 指定 |
| Arkari（可选） | 混淆版 LLVM fork；默认找 `G:/opensource/Arkari/build_ninja/bin`，或用 `ARKARI_DIR` 指定 |

构建全程不需要 "x64 Native Tools Command Prompt"：工具链文件把编译器、`/I` 头文件目录、`/LIBPATH` 库目录全部解析成绝对路径写进构建系统，任何 shell（PowerShell / 普通 cmd / CI）里直接 `cmake --preset` + `cmake --build` 即可。

## 命令行使用

```powershell
# MSVC (cl.exe)
cmake --preset msvc-debug     && cmake --build --preset msvc-debug
cmake --preset msvc-release   && cmake --build --preset msvc-release

# LLVM (clang-cl.exe)
cmake --preset clang-debug    && cmake --build --preset clang-debug
cmake --preset clang-release  && cmake --build --preset clang-release

# Arkari (混淆版 clang-cl.exe) —— 混淆默认开启
cmake --preset arkari-debug   && cmake --build --preset arkari-debug
cmake --preset arkari-release && cmake --build --preset arkari-release
# 关闭混淆：
cmake --preset arkari-release -DARKARI_OBFUSCATION="" && cmake --build --preset arkari-release

# 汇总产物（exe + lib 到 out/install/<preset>）
cmake --install out/build/msvc-debug
```

产物位置：`out/build/<preset>/src/WinApp.exe`（+ `corelib.dll`，若开共享库）。

## 静态 / 动态链接（自由配置）

两个正交开关，构建期任意组合：

| 开关 | 取值 | 效果 | 证据（导入表） |
|---|---|---|---|
| `APP_RUNTIME_LINK` | `static`（默认） | CRT 静态链接 `/MT`（Debug `/MTd`），exe 不依赖 VC 运行库 | 无 `VCRUNTIME140.dll`、无 `api-ms-win-crt-*` |
| | `dynamic` | CRT 动态链接 `/MD`，exe 小、需 VC Redist | 导入 `VCRUNTIME140.dll` + `api-ms-win-crt-*` |
| `BUILD_SHARED_LIBS` | `OFF`（默认） | corelib 静态 `.lib` 折叠进 exe | 无 corelib.dll |
| | `ON` | corelib 编为 `corelib.dll` + 导入库 | 导入 `corelib.dll` |

```powershell
# 全静态（单文件发布）
cmake --preset msvc-release && cmake --build --preset msvc-release

# CRT 动态 + 库共享
cmake --preset msvc-release -DAPP_RUNTIME_LINK=dynamic -DBUILD_SHARED_LIBS=ON `
  && cmake --build --preset msvc-release
```

样例程序弹窗即显示当前组合（编译器 / CRT 链接 / 库链接），所见即所得。

## 模板分支（GUI 变体各占一支）

| 分支 | 内容 |
|---|---|
| `main` | Win32 GUI 基础模板（本分支）：corelib + 三工具链 + 静态/动态链接开关 |
| `template/qt` | Qt Widgets 版：`APP_QT_LINK=static/dynamic` 自控切换 Qt 静态/动态 kit |

其他框架（vcpkg / FetchContent / NuGet 三方库）在任一分支上加 `find_package` +
目标即可；vendored 包可仿照 WinDriver 仓库 `third_party/musa/` 的布局入库管理。

## VSCode 使用

1. 安装推荐扩展（CMake Tools + C/C++）。
2. 打开本目录 → `Ctrl+Shift+P` → **CMake: Select Configure Preset** 任选 preset。
3. F7 构建（或任务面板里的 `Build: *` 任务）。

IntelliSense：cpptools 经 `C_Cpp.default.configurationProvider` 吃当前 preset 的
`compile_commands.json`；clangd 侧由 `cmake.copyCompileCommands`（configure 后）与
根 CMakeLists 的 `update-compile-commands` 目标（build 后）双路径把 db 镜像到仓库
根目录，配合根 `.clangd`（`--driver-mode=cl`）即可正确解析 Windows 头。根目录该
文件已 gitignore。

## 灵活定制点

| 变量（-D 或环境变量） | 作用 |
|---|---|
| `APP_RUNTIME_LINK` | `static`（默认 `/MT`）或 `dynamic`（`/MD`） |
| `BUILD_SHARED_LIBS` | 项目库 `.lib`（默认）或 `.dll` |
| `USE_QT` + `CMAKE_PREFIX_PATH` | 启用 Qt 样例目标 |
| `CLANG_DIR` | clang-cl/lld-link 所在 bin 目录（默认 PATH 找） |
| `ARKARI_DIR` | Arkari 工具链 bin 目录 |
| `APP_QT_LINK`（仅 template/qt 分支） | Qt kit 静态/动态切换，见该分支 README |
| `MSVC_VS_DIR` / `WIN_KITS_ROOT` | MSVC / Windows Kits 定位覆盖 |

## 已验证

- [x] 六个 preset 全绿：msvc/clang/arkari × debug/release
- [x] `APP_RUNTIME_LINK=static` → exe 导入表无 `VCRUNTIME140.dll`/`api-ms-win-crt-*`；`dynamic` → 出现
- [x] `BUILD_SHARED_LIBS=ON` → `corelib.dll` 生成，exe 导入之
- [x] 全程无需开发者命令提示符 / 无任何 cmd、PowerShell 包装
- [x] 根目录 `compile_commands.json` 构建后自动刷新，clangd 诊断干净
