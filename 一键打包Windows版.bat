@echo off
chcp 65001 >nul
title 红果鉴 Windows 一键打包
cd /d "%~dp0"

echo ============================================
echo  红果鉴 Windows 版一键打包（含封面快捷下载）
echo ============================================
echo.

where flutter >nul 2>nul || (echo [错误] 未找到 flutter，请先安装 Flutter 3.47.4 并加入 PATH & pause & exit /b 1)
where go >nul 2>nul     || (echo [错误] 未找到 go，请安装 Go 1.24.1+ 并加入 PATH & pause & exit /b 1)
where python >nul 2>nul || (echo [错误] 未找到 python，请安装 Python 3.10+ 并加入 PATH & pause & exit /b 1)

echo [1/3] 拉取依赖...
call flutter pub get --enforce-lockfile || (echo [错误] 依赖拉取失败 & pause & exit /b 1)

echo [2/3] 编译 Go 内核...
python scripts\build_native.py --platform windows || (echo [错误] 内核编译失败 & pause & exit /b 1)

echo [3/3] 构建 Windows 应用（将调用 Visual Studio 的 C++ 工具链）...
python scripts\build_windows.py %* || (echo [错误] 构建失败，请确认已安装 VS2022 的 "使用 C++ 的桌面开发" 工作负载 & pause & exit /b 1)

echo.
echo ✓ 打包完成！产物在 dist\windows 目录
if exist dist\windows start "" explorer "%~dp0dist\windows"
pause
