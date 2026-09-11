# vscode_WinApp

Windows **三环（用户态）应用**模板工程：**CMake + Ninja**，工具链可在 **MSVC (cl.exe) / LLVM (clang-cl.exe) / Arkari（混淆版 clang）** 之间一键切换，全部构建逻辑收拢在独立的 `cmake/` 目录，**静态/动态链接自由配置**，内置 Qt 等第三方框架的快速扩展点。VSCode 打开即识别头文件（含 `.vscode` 配置与 clangd 支持，随仓库提交）。

驱动（ring 0）模板见姊妹仓库 [vscode_WinDriver](https://github.com/pythonfansx/vscode_WinDriver)。

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
│   ├── CMakeLists.txt        # corelib + WinApp(+可选 WinAppQt) 目标与 install 规则
│   ├── corelib/              # 示例库：BUILD_SHARED_LIBS 决定 .lib / .dll
│   ├── app/                  # Win32 GUI 样例（弹出构建配置报告）
│   └── qt/                   # Qt 样例（-DUSE_QT=ON 时参与编译）
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

## Qt 等框架快速扩展

根 CMakeLists 预留 `USE_QT` 扩展点，`src/qt/main.cpp` 为现成样例：

```powershell
cmake --preset msvc-debug -DUSE_QT=ON -DCMAKE_PREFIX_PATH="C:/Qt/6.8.0/msvc2022_64" `
  && cmake --build --preset msvc-debug
```

其他框架（vcpkg / FetchContent / NuGet 三方库）同理：在根 CMakeLists 的
"Optional dependencies" 区域 `find_package` + 在 `src/CMakeLists.txt` 加目标即可。
Vendored 包可仿照 WinDriver 仓库 `third_party/musa/` 的布局入库管理。

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
| `ARKARI_OBFUSCATION` | 混淆旗标（默认全开；空串关闭） |
| `MSVC_VS_DIR` / `WIN_KITS_ROOT` | MSVC / Windows Kits 定位覆盖 |

## 已验证

- [x] 六个 preset 全绿：msvc/clang/arkari × debug/release
- [x] `APP_RUNTIME_LINK=static` → exe 导入表无 `VCRUNTIME140.dll`/`api-ms-win-crt-*`；`dynamic` → 出现
- [x] `BUILD_SHARED_LIBS=ON` → `corelib.dll` 生成，exe 导入之
- [x] 全程无需开发者命令提示符 / 无任何 cmd、PowerShell 包装
- [x] 根目录 `compile_commands.json` 构建后自动刷新，clangd 诊断干净
