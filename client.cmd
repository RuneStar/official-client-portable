@ECHO OFF
PUSHD %~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "client.ps1" || PAUSE
POPD
