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

trap { Write-Error -ErrorRecord $_ -ErrorAction Continue ; exit 1 }
$Host.ui.RawUI.WindowTitle = "Old School RuneScape"
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) # TLS 1.2
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

$java_version = 11
$arch = if ($Env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $Env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') { 'x64' } else { 'x32' }

$jre_dir = Join-Path $PSScriptRoot jre-$java_version-windows-$arch
if (!(Test-Path $jre_dir)) {
	$temp_dir = Join-Path $PSScriptRoot temp
	New-Item -ItemType Directory -Path $temp_dir -Force -Verbose | Out-Null
	
	$temp_jdk_archive = Join-Path $temp_dir jdk-$java_version-windows-$arch.zip
	if (!(Test-Path $temp_jdk_archive)) {
		Download-File -Uri "https://api.adoptopenjdk.net/v2/binary/releases/openjdk$($java_version)?openjdk_impl=hotspot&release=latest&type=jdk&heap_size=normal&os=windows&arch=$arch" -OutFile $temp_jdk_archive
	}

	$temp_jdk_dir = Join-Path $temp_dir jdk-$java_version-windows-$arch
	Expand-Zip -Path $temp_jdk_archive -DestinationPath $temp_jdk_dir
	$temp_jdk_home = Join-Path $temp_jdk_dir * -Resolve

	& "$temp_jdk_home\bin\jlink" `
	 --verbose `
	 --no-header-files `
	 --no-man-pages `
	 --strip-debug `
	 --compress=2 `
	 --module-path "$temp_jdk_home\jmods" `
	 --add-modules java.desktop,java.management `
	 --output "$jre_dir"

	if ($LastExitCode) { exit $LastExitCode }

	Remove-Item $temp_dir -Recurse
}

$jar = Join-Path $PSScriptRoot jagexappletviewer.jar
if (!(Test-Path $jar)) {
	Download-File -Uri http://www.runescape.com/downloads/jagexappletviewer.jar -OutFile $jar
}

$cache_dir = Join-Path $PSScriptRoot cache
New-Item -ItemType Directory -Path $cache_dir -Force -Verbose | Out-Null

& "$jre_dir\bin\java" `
 "-Duser.home=$cache_dir" `
 "-Dsun.awt.noerasebackground=true" `
 "-Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws" `
 -jar "$jar" `
 "$((Get-Item $PSScriptRoot).Name)"

exit $LastExitCode