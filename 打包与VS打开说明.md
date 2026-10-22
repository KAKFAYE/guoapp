# 打包与 Visual Studio 打开说明（零改动版）

本压缩包是**写好、配置好的完整项目**，不需要改任何代码。两种用法任选：

## 用法 A：一键打包（最简单，推荐）
前提：已安装 VS2022（勾选"使用 C++ 的桌面开发"工作负载）、Flutter 3.47.4、
Go 1.24.1+、Python 3.10+、MinGW-w64（均在 PATH 中）。

**双击根目录的 `一键打包Windows版.bat`**，等它跑完，自动打开产物目录
`dist\windows`，解压里面的 zip 运行 `hongguojian.exe` 即可。
要全站源版，在命令行执行：`一键打包Windows版.bat --all-sources`

## 用法 B：在 Visual Studio 里打开直接生成
1. 先双击 `一键打包Windows版.bat` 跑一次（生成 Flutter 所需的 ephemeral 配置）。
2. 打开 VS 2022 → **打开本地文件夹** → 选择本项目根目录（含 `windows/CMakeLists.txt`）。
3. VS 会自动识别为 CMake 工程：顶部配置选 **x64-Debug 或 x64-Release**，
   生成目标选 `hongguojian`，按 **Ctrl+Shift+B** 生成，F5 运行调试。
4. 注意：Dart/Go 代码改动后需在命令行重新执行
   `flutter build windows`（或重跑 bat），CMake 工程仅负责 Windows 壳层与最终链接。

## 新功能说明
发现页每个剧封面右上角有下载按钮：下载选集… / 下载全部 / 多选下载。
详见 `FEATURE_COVER_DOWNLOAD.md`。

## 常见问题
见 `VS构建教程.md` 第五节（缺 DLL、工具链找不到、镜像加速等）。
