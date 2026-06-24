@echo off
set /p version="Podaj numer wersji (np. 1.0.0): "

echo.
echo === WYSYLANIE WERSJI WINDOWS ===
.\butler push build/windows Zuthen/nie-chc-uwierzy:windows --userversion %version%

echo.
echo === WYSYLANIE WERSJI MACOS ===
.\butler push build/mac Zuthen/nie-chc-uwierzy:mac --userversion %version%

echo.
echo === SKOŃCZONE! ===
pause
