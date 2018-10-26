@echo off

setlocal enabledelayedexpansion
setlocal enableextensions

cd "%~dp0"

set _arch=x64
set sys_32=!SYSTEMROOT!\system32
if exist !sys_32!\reg.exe (
	!sys_32!\reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | !sys_32!\find /i "x86" > NUL && set _arch=x32
) else (
	if "!PROCESSOR_ARCHITECTURE!"=="x86" set _arch=x32
)

if "!_arch!"=="x64" (
	set _java_version=11
	set _type=jdk
) else (
	set _java_version=8
	set _type=jre
)

set _jre_dir=jre-!_java_version!-windows-!_arch!

if not exist !_jre_dir!\ (
	set _temp_dir=temp
	if not exist !_temp_dir!\ mkdir !_temp_dir!
	
	set _temp_jdk_archive=!_temp_dir!\!_type!-!_java_version!-windows-!_arch!-archive.zip
	
	if not exist !_temp_jdk_archive! (
		powershell -Command ^
		 "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
		 "$ProgressPreference = 'SilentlyContinue';" ^
		 "Invoke-WebRequest -OutFile '!_temp_jdk_archive!' 'https://api.adoptopenjdk.net/v2/binary/releases/openjdk!_java_version!?openjdk_impl=hotspot&release=latest&type=!_type!&heap_size=normal&os=windows&arch=!_arch!';" || goto end
	)
	
	set _temp_jdk_dir=!_temp_dir!\!_type!-!_java_version!-windows-!_arch!
	if not exist !_temp_jdk_dir!\ mkdir !_temp_jdk_dir!
	
	powershell -Command ^
	 "$shell = New-Object -COM Shell.Application;" ^
	 "$target = $shell.NameSpace((Resolve-Path '.\!_temp_jdk_dir!\').Path);" ^
	 "$zip = $shell.NameSpace((Resolve-Path '.\!_temp_jdk_archive!').Path);" ^
	 "$target.CopyHere($zip.Items(), 16);" || goto end
	
	for /f %%i in ('dir /b !_temp_jdk_dir!') do set _jdk_home=!_temp_jdk_dir!\%%i
	
	if "!_type!"=="jdk" (
		"!_jdk_home!\bin\jlink" -v ^
		 --no-header-files ^
		 --no-man-pages ^
		 --strip-debug ^
		 --compress=2 ^
		 --module-path "!_jdk_home!\jmods" ^
		 --add-modules java.desktop,java.management ^
		 --output !_jre_dir! || goto end
	) else (
		xcopy /i /s ".\!_jdk_home!" ".\!_jre_dir!\" || goto end
	)
	
	rmdir /s /q !_temp_dir!
)

powershell -Command ^
 "$ProgressPreference = 'SilentlyContinue';" ^
 "Invoke-WebRequest -OutFile jagexappletviewer.jar http://www.runescape.com/downloads/jagexappletviewer.jar;" || goto end

if not exist cache\ mkdir cache

for %%I in (.) do set _dir_basename=%%~nxI

"!_jre_dir!\bin\java" -jar ^
 -Duser.home=cache ^
 -Dsun.awt.noerasebackground=true ^
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws ^
 jagexappletviewer.jar "!_dir_basename!" || goto end

del jagexappletviewer.jar

:end
if !errorlevel! neq 0 pause
exit /b !errorlevel!