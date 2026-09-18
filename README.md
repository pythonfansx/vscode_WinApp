# vscode_WinApp — template/static-lib

Windows C++ 静态库模板。只产出 `.lib`、公共头和 CMake targets 文件，不夹带演示 EXE。

## 目标与安装布局

- 构建目标：`WinAppStatic`
- 工程内别名：`WinApp::Static`
- 产物：`winapp_static.lib`
- 公共头：`include/winapp/winapp.h`
- 安装导出：`lib/cmake/WinAppStatic/WinAppStaticTargets.cmake`
- `APP_RUNTIME_LINK=static|dynamic` 控制库对象使用 `/MT` 或 `/MD`

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
target_link_libraries(MyApp PRIVATE WinApp::Static)
```

安装后可直接 `find_package(WinAppStatic CONFIG REQUIRED)`，导入目标仍为 `WinApp::Static`。

## 模板分支

| 分支 | 交付形态 |
|---|---|
| `main` | 原生 Win32 GUI EXE |
| `template/console` | 控制台 EXE |
| `template/static-lib` | 静态库（本分支） |
| `template/shared-lib` | Windows DLL |
| `template/qt` | Qt Widgets GUI |
