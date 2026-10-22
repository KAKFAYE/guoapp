@echo off
chcp 65001 >nul
cd /d "%~dp0"
set LOG=build_log.txt
echo ============ 红果鉴 VS 一键生成 ============
echo 日志同时写入文件 %LOG%（构建失败时把这个文件发给助手即可定位）
set MISSING=
where flutter >nul 2>nul || set MISSING=%MISSING% Flutter
where go >nul 2>nul     || set MISSING=%MISSING% Go
where python >nul 2>nul || set MISSING=%MISSING% Python
where gcc >nul 2>nul    || set MISSING=%MISSING% MinGW(gcc)
if not "%MISSING%"=="" (
  echo [失败] 以下工具未安装或未加入 PATH:%MISSING%
  echo [失败] 以上内容也写入了 %LOG%
  > "%LOG%" echo 缺少工具:%MISSING%
  >>"%LOG%" echo 请安装：VS2022(C++桌面开发)、Flutter 3.47.4、Go 1.24+、Python 3.10+、MinGW-w64 并加入 PATH
  exit /b 1
)
echo [1/3] 拉取依赖 (flutter pub get)...
>>"%LOG%" echo ===== flutter pub get =====
call flutter pub get --enforce-lockfile >>"%LOG%" 2>&1
if errorlevel 1 (echo [失败] flutter pub get 出错，详见 %LOG% & exit /b 1)
echo [2/3] 编译 Go 内核 (约几分钟)...
>>"%LOG%" echo ===== build_native =====
python scripts\build_native.py --platform windows >>"%LOG%" 2>&1
if errorlevel 1 (echo [失败] Go 内核编译出错，详见 %LOG% & exit /b 1)
echo [3/3] 构建 Windows 应用 (首次约10-20分钟，请耐心等待)...
>>"%LOG%" echo ===== build_windows =====
python scripts\build_windows.py >>"%LOG%" 2>&1
if errorlevel 1 (echo [失败] 应用构建出错，详见 %LOG%；常见原因：VS2022 未勾选 "使用 C++ 的桌面开发" & exit /b 1)
echo ============ 完成！产物在 dist\windows ============
>"%LOG%" echo 成功
