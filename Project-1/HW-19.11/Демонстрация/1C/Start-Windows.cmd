@echo off
chcp 65001 >nul
setlocal
set "CLIENT="
for %%R in ("%ProgramFiles%" "%ProgramFiles(x86)%") do (
  for %%P in (1cv8t 1cv8) do (
    for /f "delims=" %%V in ('dir /b /ad /o:-n "%%~R\%%P\8.3.*" 2^>nul') do (
      for %%E in (1cv8ct 1cv8c 1cv8t 1cv8) do (
        if not defined CLIENT if exist "%%~R\%%P\%%V\bin\%%E.exe" set "CLIENT=%%~R\%%P\%%V\bin\%%E.exe"
      )
    )
  )
)
if not defined CLIENT (
  echo Для показа нужна платформа 1С 8.3.27. Установите её и повторите запуск.
  echo https://online.1c.ru/catalog/free/learning.php
  pause
  exit /b 1
)
if not exist "%~dp0database\1Cv8.1CD" goto incomplete
if not exist "%~dp0tests.epf" goto incomplete
if /i "%~1"=="--check" (
  "%CLIENT%" ENTERPRISE /F "%~dp0database" /N "Администратор" /Lru /Execute "%~dp0tests.epf" /C"ЗапуститьАвтотесты|%~dp0result.txt" /DisableStartupDialogs /DisableStartupMessages
  exit /b
)
start "" "%CLIENT%" ENTERPRISE /F "%~dp0database" /N "Администратор" /Lru /Execute "%~dp0tests.epf"
exit /b
:incomplete
echo Полностью распакуйте VoltMarket-1C.zip в обычную папку и запустите файл из неё.
pause
exit /b 1
