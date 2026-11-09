@echo off
chcp 65001 >nul
title Отчёт о проблеме — Gothic 1 Remake Co-op
echo.
echo   Отчёт о проблеме для Gothic 1 Remake Co-op
echo   ==========================================
echo.
echo   Сейчас будет собран архив с диагностикой: журналы мода,
echo   лаунчера и установщика, система и версии файлов.
echo.
echo   Личные данные (адреса, имя компьютера, имя пользователя)
echo   заменяются автоматически — их в архиве не будет.
echo.
echo   Если проблема со связью - пришлите отчёт с ОБОИХ компьютеров.
echo.
echo   Внизу опишите одной строкой, что случилось и во сколько.
echo   Можно просто нажать Enter.
echo.
set "NOTE="
set /p "NOTE=Что случилось: "

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\collect_logs.ps1" -Note "%NOTE%"
if errorlevel 1 goto manual

echo.
echo   Готово. Сейчас откроется папка с архивом report_...zip —
echo   пришлите этот файл разработчику.
echo.
start "" explorer "%LOCALAPPDATA%\G1RCoop\beta_reports"
timeout /t 3 >nul
exit /b 0

:manual
echo.
echo   Не удалось собрать отчёт автоматически.
echo   Открываю папку с логами — пришлите её содержимое (можно архивом).
echo.
start "" explorer "%LOCALAPPDATA%\G1RCoop\logs"
pause
exit /b 1
