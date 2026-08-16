@echo off
"C:\src\flutter\bin\flutter.bat" analyze 2>&1
exit /b %ERRORLEVEL%
