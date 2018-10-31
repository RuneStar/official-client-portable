#Requires -Version 3.0
Set-StrictMode -Version 2.0
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

trap {
	$_
	exit 1
}

if ([Environment]::Is64BitOperatingSystem) {
	$_arch = "x64"
	$_java_version = 11
	$_java_type = "jdk"
} else {
	$_arch = "x32"
	$_java_version = 8
	$_java_type = "jre"
}

$_jre_dir = Join-Path $PSScriptRoot jre-$_java_version-windows-$_arch

if (!(Test-Path $_jre_dir)) {
	$_temp_dir = Join-Path $PSScriptRoot temp
	New-Item -ItemType Directory -Path $_temp_dir -Force -Verbose | Out-Null
	
	$_temp_jdk_archive = Join-Path $_temp_dir $_java_type-$_java_version-windows-$_arch.zip
	
	if (!(Test-Path $_temp_jdk_archive)) {
		Invoke-WebRequest -TimeoutSec 5 -Verbose -OutFile $_temp_jdk_archive "https://api.adoptopenjdk.net/v2/binary/releases/openjdk$($_java_version)?openjdk_impl=hotspot&release=latest&type=$_java_type&heap_size=normal&os=windows&arch=$_arch"
	}
	
	$_temp_jdk_dir = Join-Path $_temp_dir $_java_type-$_java_version-windows-$_arch
	New-Item -ItemType Directory -Path $_temp_jdk_dir -Force -Verbose | Out-Null
	
	$shell = New-Object -COM Shell.Application
	$target = $shell.NameSpace((Resolve-Path $_temp_jdk_dir).Path)
	$zip = $shell.NameSpace((Resolve-Path $_temp_jdk_archive).Path)
	$target.CopyHere($zip.Items(), 16)
	
	$_jdk_home = Join-Path $_temp_jdk_dir * -Resolve
	if ($_java_type -eq "jdk") {
		& "$_jdk_home\bin\jlink" -v `
		 --no-header-files `
		 --no-man-pages `
		 --strip-debug `
		 --compress=2 `
		 --module-path "$_jdk_home\jmods" `
		 --add-modules java.desktop,java.management `
		 --output "$_jre_dir"
	} else {
		Copy-Item $_jdk_home -Destination $_jre_dir -Recurse
	}
	
	Remove-Item $_temp_dir -Recurse
}

$_jar = Join-Path $PSScriptRoot jagexappletviewer.jar
Invoke-WebRequest -TimeoutSec 5 -Verbose -OutFile $_jar http://www.runescape.com/downloads/jagexappletviewer.jar

$_cache_dir = Join-Path $PSScriptRoot cache
New-Item -ItemType Directory -Path $_cache_dir -Force -Verbose | Out-Null

& "$_jre_dir\bin\java" -jar `
 "-Duser.home=$_cache_dir" `
 "-Dsun.awt.noerasebackground=true" `
 "-Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws" `
 "$_jar" "$((Get-Item $PSScriptRoot).Name)"
 
Remove-Item $_jar -Verbose