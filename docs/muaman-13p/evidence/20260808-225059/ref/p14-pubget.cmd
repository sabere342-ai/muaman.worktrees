@echo off
"C:\src\flutter\bin\flutter.bat" pub get 2>&1
exit /b %ERRORLEVEL%
