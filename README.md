# vscode_WinApp

Windows **三环（用户态）工程模板族**：`main` 是原生 Win32 GUI EXE，另有控制台 EXE、静态库、动态库和 Qt Widgets GUI 专用分支。所有分支统一使用 **CMake + Ninja**，可在 **MSVC (cl.exe) / LLVM (clang-cl.exe) / Arkari（混淆版 clang）** 之间切换；构建逻辑集中在 `cmake/`，VSCode 只依赖 CMake Tools 与 clangd。

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
│       ├── llvm-cl-common.cmake # clang-cl 共用的解析、resource-dir 与 SDK 层
│       ├── clang.cmake       # 上游 LLVM 叶子 toolchain
│       └── arkari.cmake      # Arkari 叶子 toolchain（混淆默认开启）
├── src/
│   ├── CMakeLists.txt        # corelib + WinApp 目标与 install 规则
│   ├── corelib/              # 示例库：BUILD_SHARED_LIBS 决定 .lib / .dll
│   └── app/                  # Win32 GUI 样例（弹出构建配置报告）
└── .vscode/                  # 随仓库提交：CMake Tools、clangd 与构建任务
```

## 环境要求

| 组件 | 要求 |
|---|---|
| Visual Studio 2022 | 勾选 "使用 C++ 的桌面开发"（含 MSVC v143 工具集） |
| Windows SDK | 任意可发现版本（本机验证：10.0.26100.0） |
| CMake | ≥ 3.21 |
| Ninja | 在 PATH 中即可（VS 自带的 Ninja 也行） |
| LLVM（可选） | 含 `clang-cl.exe` + `lld-link.exe`；用 `CLANG_DIR` 缓存变量或环境变量指定其 `bin` 目录 |
| Arkari（可选） | 混淆版 LLVM fork；用 `ARKARI_DIR` 缓存变量或环境变量指定其 `bin` 目录 |

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

## 模板分支

| 分支 | 交付形态 |
|---|---|
| `main` | 原生 Win32 GUI EXE；保留示例 `corelib` 的静态/动态切换 |
| `template/console` | 最小控制台 EXE |
| `template/static-lib` | 只产出静态 `.lib` 与公共头 |
| `template/shared-lib` | 只产出 `.dll`、导入库与公共头 |
| `template/qt` | Qt 5.15 Widgets GUI；静态/动态 Qt kit 与 CRT 自动配对 |

每个分支都是可独立复制的完整工程，不通过一个总开关混装无关目标。

## VSCode 使用

1. 安装推荐扩展（CMake Tools + clangd）。
2. 打开本目录 → `Ctrl+Shift+P` → **CMake: Select Configure Preset** 任选 preset。
3. F7 构建（或任务面板里的 `Build: *` 任务）。

clangd 直接读取当前 preset 生成的 `compile_commands.json`。CMake Tools 在 configure 后复制，
根 `update-compile-commands` 目标在 build 后再次复制，因此仓库根目录始终反映最后一次成功
配置/构建。LLVM toolchain 会把对应编译器的 `-resource-dir` 明确写进数据库，clangd 不会误用
自身安装目录里的另一份内建头。根目录 `compile_commands.json` 已 gitignore。

## 灵活定制点

| 变量（-D 或环境变量） | 作用 |
|---|---|
| `APP_RUNTIME_LINK` | `static`（默认 `/MT`）或 `dynamic`（`/MD`） |
| `BUILD_SHARED_LIBS` | 项目库 `.lib`（默认）或 `.dll` |
| `CLANG_DIR` | 上游 LLVM 的 `clang-cl.exe` / `lld-link.exe` 所在 `bin` 目录 |
| `ARKARI_DIR` | Arkari 的 `clang-cl.exe` / `lld-link.exe` 所在 `bin` 目录 |
| `MSVC_VS_DIR` / `WIN_KITS_ROOT` | MSVC / Windows Kits 定位覆盖 |
| `APP_QT_LINK`（仅 `template/qt`） | Qt kit 静态/动态切换 |

## 已验证

- [x] 六个 preset 全绿：msvc/clang/arkari × debug/release
- [x] `APP_RUNTIME_LINK=static` → exe 导入表无 `VCRUNTIME140.dll`/`api-ms-win-crt-*`；`dynamic` → 出现
- [x] `BUILD_SHARED_LIBS=ON` → `corelib.dll` 生成，exe 导入之
- [x] 全程无需开发者命令提示符 / 无任何 cmd、PowerShell 包装
- [x] 根目录 `compile_commands.json` 自动刷新，LLVM resource headers 与所选编译器严格一致
