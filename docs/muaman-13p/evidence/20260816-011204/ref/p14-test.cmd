@echo off
"C:\src\flutter\bin\flutter.bat" test 2>&1
exit /b %ERRORLEVEL%
