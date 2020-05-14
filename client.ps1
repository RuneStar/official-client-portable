#Requires -Version 2.0
Set-StrictMode -Version 2.0

trap { Write-Error -ErrorRecord $_ -ErrorAction Continue; exit 1 }
$ErrorActionPreference = 'Stop'
$Global:ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)

function Expand-Zip($Path, $DestinationPath) {
	if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
		Expand-Archive -Path $Path -DestinationPath $DestinationPath -Force -Verbose
	} else {
		New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
		$Shell = New-Object -COMObject 'Shell.Application'
		$Target = $Shell.NameSpace((Convert-Path $DestinationPath))
		$Zip = $Shell.NameSpace((Convert-Path $Path))
		$Target.CopyHere($Zip.Items(), 16)
	}
}

$JavaVersion = 11
$Arch  = if ($Env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $Env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') { 'x64' } else { 'x32' }
$JreDir = "jre-windows-$Arch"
if (!(Test-Path $JreDir)) {
	$TempDir  = 'temp'
	New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
	$JdkArchive = "$TempDir\jdk-$JavaVersion-windows-$Arch.zip"
	if (!(Test-Path $JdkArchive)) {
		$JdkArchiveUrl = "https://api.adoptopenjdk.net/v3/binary/latest/$JavaVersion/ga/windows/$Arch/jdk/hotspot/normal/adoptopenjdk"
		"Downloading '$JdkArchiveUrl' to '$JdkArchive'"
		(New-Object System.Net.WebClient).DownloadFile($JdkArchiveUrl, $JdkArchive)
	}
	$JdkDir = "$TempDir\jdk-$JavaVersion-windows-$Arch"
	Expand-Zip -Path $JdkArchive -DestinationPath $JdkDir
	$JdkHome = Join-Path $JdkDir * -Resolve

	& "$JdkHome\bin\jlink" `
		"--verbose" `
		"--no-header-files" `
		"--no-man-pages" `
		"--strip-debug" `
		"--compress=2" `
		"--module-path" "$JdkHome\jmods" `
		"--add-modules" "java.desktop,java.management" `
		"--output" "$JreDir"

	if ($LastExitCode) { exit $LastExitCode }

	Remove-Item $TempDir -Recurse
}

New-Item -ItemType Directory -Path 'cache' -Force | Out-Null

& "$JreDir\bin\javaw" `
	"-Duser.home=cache" `
	"-Dsun.awt.noerasebackground=true" `
	"-Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws" `
	"-jar" "jagexappletviewer.jar" `
	"$((Get-Item (Convert-Path .)).Name)"
