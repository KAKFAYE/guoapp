@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============ 红果鉴 VS 一键生成 ============
set MISSING=
where flutter >nul 2>nul || set MISSING=%MISSING% Flutter
where go >nul 2>nul     || set MISSING=%MISSING% Go
where python >nul 2>nul || set MISSING=%MISSING% Python
where gcc >nul 2>nul    || set MISSING=%MISSING% MinGW(gcc)
if not "%MISSING%"=="" (
  echo [失败] 以下工具未安装或未加入 PATH:%MISSING%
  echo 请先按 VS构建教程.md 安装：VS2022(C++桌面开发)、Flutter 3.47.4、Go 1.24+、Python 3.10+、MinGW-w64
  echo 或者不改用本地编译：把项目传到 GitHub 用 Actions 云端打包。
  exit /b 1
)
echo [1/3] 拉取依赖...
call flutter pub get --enforce-lockfile
if errorlevel 1 (echo [失败] flutter pub get 出错，详见上方输出 & exit /b 1)
echo [2/3] 编译 Go 内核...
python scripts\build_native.py --platform windows
if errorlevel 1 (echo [失败] Go 内核编译出错，详见上方输出 & exit /b 1)
echo [3/3] 构建 Windows 应用...
python scripts\build_windows.py %*
if errorlevel 1 (echo [失败] 应用构建出错，请确认 VS2022 已勾选 "使用 C++ 的桌面开发" 工作负载 & exit /b 1)
echo ============ 完成！产物在 dist\windows ============
