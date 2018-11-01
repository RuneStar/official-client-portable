#Requires -Version 2.0
Set-StrictMode -Version 2.0

function Expand-Zip($Path, $DestinationPath) {
	if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
		Expand-Archive -Verbose -Force -Path $Path -DestinationPath $DestinationPath
	} else {
		New-Item -ItemType Directory -Path $DestinationPath -Force -Verbose | Out-Null
		$shell = New-Object -COM Shell.Application
		$target = $shell.NameSpace((Resolve-Path $DestinationPath).Path)
		$zip = $shell.NameSpace((Resolve-Path $Path).Path)
		$target.CopyHere($zip.Items(), 16)
	}
}

function Download-File($Uri, $OutFile) {
	if (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue) {
		Invoke-WebRequest -TimeoutSec 5 -Verbose -Uri $Uri -OutFile $OutFile
	} else {
		New-Item -ItemType File -Path $OutFile -Verbose | Out-Null
		(New-Object System.Net.WebClient).DownloadFile($Uri, $OutFile)
	}
}

trap { $_ ; exit 1 }
$host.ui.RawUI.WindowTitle = "Old School RuneScape"
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) # TLS 1.2
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

$_java_version = 11
if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
	$_arch = 'x64'
} else {
	$_arch = 'x32'
}

$_jre_dir = Join-Path $PSScriptRoot jre-$_java_version-windows-$_arch
if (!(Test-Path $_jre_dir)) {
	$_temp_dir = Join-Path $PSScriptRoot temp
	New-Item -ItemType Directory -Path $_temp_dir -Force -Verbose | Out-Null
	
	$_temp_jdk_archive = Join-Path $_temp_dir jdk-$_java_version-windows-$_arch.zip
	if (!(Test-Path $_temp_jdk_archive)) {
		Download-File -Uri "https://api.adoptopenjdk.net/v2/binary/nightly/openjdk$($_java_version)?openjdk_impl=hotspot&release=latest&type=jdk&heap_size=normal&os=windows&arch=$_arch" -OutFile $_temp_jdk_archive
	}
	
	$_temp_jdk_dir = Join-Path $_temp_dir jdk-$_java_version-windows-$_arch
	Expand-Zip -Path $_temp_jdk_archive -DestinationPath $_temp_jdk_dir
	$_jdk_home = Join-Path $_temp_jdk_dir * -Resolve
	
	& "$_jdk_home\bin\jlink" -v `
	 --no-header-files `
	 --no-man-pages `
	 --strip-debug `
	 --compress=1 `
	 --module-path "$_jdk_home\jmods" `
	 --add-modules java.desktop,java.management `
	 --output "$_jre_dir"
	
	if ($LastExitCode -ne 0) { exit $LastExitCode }
	
	Remove-Item $_temp_dir -Recurse
}

$_jar = Join-Path $PSScriptRoot jagexappletviewer.jar
if (!(Test-Path $_jar)) {
	Download-File -Uri http://www.runescape.com/downloads/jagexappletviewer.jar -OutFile $_jar
}

$_cache_dir = Join-Path $PSScriptRoot cache
New-Item -ItemType Directory -Path $_cache_dir -Force -Verbose | Out-Null

& "$_jre_dir\bin\java" -jar `
 "-Duser.home=$_cache_dir" `
 "-Dsun.awt.noerasebackground=true" `
 "-Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws" `
 "$_jar" "$((Get-Item $PSScriptRoot).Name)"

exit $LastExitCode