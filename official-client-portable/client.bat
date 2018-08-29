@echo off

set _JAVA_COMMAND=java

cd "%~dp0"

for %%I in (.) do set _DIR_BASENAME="%%~nxI"

%_JAVA_COMMAND% --version || goto end

powershell -Command "Invoke-WebRequest -OutFile jagexappletviewer.jar http://www.runescape.com/downloads/jagexappletviewer.jar" || goto end

if not exist cache\ mkdir cache || goto end

%_JAVA_COMMAND% -jar^
 -Duser.home=cache^
 -Dsun.awt.noerasebackground=true^
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws^
 jagexappletviewer.jar %_DIR_BASENAME% || goto end

del jagexappletviewer.jar

:end
if %errorlevel% neq 0 pause
exit /b %errorlevel%