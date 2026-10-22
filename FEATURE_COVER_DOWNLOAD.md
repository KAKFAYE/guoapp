# 封面右上角快捷下载（新增功能说明）

## 改动内容
在"发现"页每个剧封面的右上角新增一个可点击的下载按钮（与原有"更多"按钮并排，
"更多"按钮自动左移避让）。点击后弹出菜单：

- 下载选集…：打开原有的选集下载器，可勾选任意单集、画质（自动/1080P/720P/480P）
- 下载全部：一键把本剧全部分集（按下载偏好过滤 VIP，一次最多 500 集）加入下载队列
- 多选下载：进入多选模式，与其他剧一起批量下载（一次最多 50 部）

仅当当前用户有下载权限且站源支持下载时显示该按钮。

## 涉及文件
- lib/widgets.dart：新增 CoverDownloadButton 组件；DramaTile 增加 onQuickDownload 参数及右上角定位逻辑
- lib/home_screen.dart：新增 _quickDownload（弹出快捷菜单）与 _downloadAll（整剧加入下载）方法，并接入 _catalogTile

## Windows 构建方法（Visual Studio）
环境要求：Flutter 3.47.4、Dart 3.12+、Go 1.24.1+、Python 3.10+、
Visual Studio 2022（含"C++ 桌面开发"工作负载）、MinGW-w64 x64（Go 交叉编译需要）。

~~~sh
flutter pub get --enforce-lockfile
python scripts/build_windows.py          # 产物在 dist/windows（hongguojian-*）
python scripts/build_windows.py --all-sources   # 全站源版（zhenguojian-*）
~~~
