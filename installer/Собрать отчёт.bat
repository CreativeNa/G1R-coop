@echo off
chcp 65001 >nul
title Отчёт о проблеме — Gothic 1 Remake Co-op
echo.
echo   Отчёт о проблеме для Gothic 1 Remake Co-op
echo   ==========================================
echo.
echo   Сейчас будет собран архив с диагностикой: журналы мода,
echo   система, версии файлов и счётчики ошибок.
echo.
echo   Личные данные (адреса, имя компьютера, имя пользователя)
echo   заменяются автоматически — их в архиве не будет.
echo.
echo   Внизу опишите одной строкой, что случилось и во сколько.
echo   Можно просто нажать Enter.
echo.
set "NOTE="
set /p "NOTE=Что случилось: "

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\collect_logs.ps1" -Note "%NOTE%"
if errorlevel 1 (
    echo.
    echo   Не удалось собрать отчёт. Проверьте, что мод установлен установщиком.
    echo.
    pause
    exit /b 1
)

echo.
echo   Готово. Сейчас откроется папка с архивом report_...zip —
echo   пришлите этот файл разработчику.
echo.
start "" explorer "%LOCALAPPDATA%\G1RCoop\beta_reports"
timeout /t 3 >nul
