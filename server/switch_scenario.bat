@echo off
echo.
echo === Version Scenario Switcher ===
echo.
echo Choose a scenario:
echo   1. Up to date (no dialog)
echo   2. Optional update (dismissable dialog)
echo   3. Force update (blocking dialog)
echo.
set /p choice="Enter choice (1/2/3): "

if "%choice%"=="1" (
    copy /Y "scenarios\up_to_date.json" "version.json" >nul
    echo.
    echo [OK] Switched to: UP TO DATE
    echo     App 1.0.0 = Server 1.0.0 - No dialog shown
)
if "%choice%"=="2" (
    copy /Y "scenarios\optional_update.json" "version.json" >nul
    echo.
    echo [OK] Switched to: OPTIONAL UPDATE
    echo     App 1.0.0 ^< Server 1.1.0 - Dismissable update dialog
)
if "%choice%"=="3" (
    copy /Y "scenarios\force_update.json" "version.json" >nul
    echo.
    echo [OK] Switched to: FORCE UPDATE
    echo     App 1.0.0 ^< Min 1.5.0 - Blocking force update dialog
)
echo.
echo Restart the app to see the change (server reads file on each request).
echo.
pause
