# vscode_WinApp — template/shared-lib

Windows DLL 模板。只产出 DLL、导入库、公共头和 CMake targets 文件；示例 API 使用稳定的 `extern "C"` 导出边界。

## 目标与安装布局

- 构建目标：`WinAppShared`
- 工程内别名：`WinApp::Shared`
- 产物：`winapp_shared.dll` + `winapp_shared.lib`
- 公共头：`include/winapp/winapp.h`
- 安装导出：`lib/cmake/WinAppShared/WinAppSharedTargets.cmake`
- 默认 `APP_RUNTIME_LINK=dynamic`（`/MD`）；可显式改为 `static`

`WINAPP_SHARED_BUILD` 只对 DLL 自身生效；消费者自动看到 `__declspec(dllimport)`，不会把导出宏泄漏到使用方。

## 构建

```powershell
cmake --preset msvc-release --fresh
cmake --build --preset msvc-release
cmake --install out/build/msvc-release

cmake --preset clang-release --fresh -DCLANG_DIR=D:/path/to/llvm/bin
cmake --build --preset clang-release

cmake --preset arkari-release --fresh -DARKARI_DIR=D:/path/to/arkari/bin
cmake --build --preset arkari-release
```

构建树内消费：

```cmake
add_subdirectory(path/to/vscode_WinApp)
target_link_libraries(MyApp PRIVATE WinApp::Shared)
```

安装后可直接 `find_package(WinAppShared CONFIG REQUIRED)`，导入目标仍为 `WinApp::Shared`。

运行消费者时，`winapp_shared.dll` 必须位于 EXE 同目录或系统 DLL 搜索路径。

## 模板分支

| 分支 | 交付形态 |
|---|---|
| `main` | 原生 Win32 GUI EXE |
| `template/console` | 控制台 EXE |
| `template/static-lib` | 静态库 |
| `template/shared-lib` | Windows DLL（本分支） |
| `template/qt` | Qt Widgets GUI |
