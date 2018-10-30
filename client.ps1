#Requires -Version 3.0
Set-StrictMode -Version 2.0
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Stop"

if ([Environment]::Is64BitOperatingSystem) {
	$_arch = "x64"
	$_java_version = 11
	$_java_type = "jdk"
} else {
	$_arch = "x32"
	$_java_version = 8
	$_java_type = "jre"
}

$_jre_dir = ".\jre-$_java_version-windows-$_arch"

if (!(Test-Path $_jre_dir)) {
	$_temp_dir = ".\temp"
	New-Item -ItemType Directory -Path $_temp_dir -Force | Out-Null
	
	$_temp_jdk_archive="$_temp_dir\$_java_type-$_java_version-windows-$_arch.zip"
	
	if (!(Test-Path $_temp_jdk_archive)) {
		Invoke-WebRequest -OutFile "$_temp_jdk_archive" "https://api.adoptopenjdk.net/v2/binary/releases/openjdk$($_java_version)?openjdk_impl=hotspot&release=latest&type=$_java_type&heap_size=normal&os=windows&arch=$_arch" 
	}
	
	$_temp_jdk_dir="$_temp_dir\$_java_type-$_java_version-windows-$_arch"
	New-Item -ItemType Directory -Path $_temp_jdk_dir -Force | Out-Null
	
	$shell = New-Object -COM Shell.Application
	$target = $shell.NameSpace((Resolve-Path $_temp_jdk_dir).Path)
	$zip = $shell.NameSpace((Resolve-Path $_temp_jdk_archive).Path)
	$target.CopyHere($zip.Items(), 16)
	
	$_jdk_home = "$_temp_jdk_dir\" + (Get-ChildItem $_temp_jdk_dir)
	if ($_java_type -eq "jdk") {
		& "$_jdk_home\bin\jlink" -v `
		 --no-header-files `
		 --no-man-pages `
		 --strip-debug `
		 --compress=2 `
		 --module-path $($_jdk_home.Replace(".\", "") + "\jmods") `
		 --add-modules java.desktop,java.management `
		 --output $($_jre_dir.Replace(".\", ""))
	} else {
		Copy-Item "$_jdk_home" -Destination "$_jre_dir" -Recurse
	}
	
	Remove-Item $_temp_dir -Recurse
}

Invoke-WebRequest -OutFile jagexappletviewer.jar http://www.runescape.com/downloads/jagexappletviewer.jar

New-Item -ItemType Directory -Path "cache" -Force | Out-Null

& "$_jre_dir\bin\java" -jar `
 "-Duser.home=cache" `
 "-Dsun.awt.noerasebackground=true" `
 "-Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws" `
 "jagexappletviewer.jar" "$((Get-Item (Get-Location)).Name)"
 
Remove-Item ".\jagexappletviewer.jar"