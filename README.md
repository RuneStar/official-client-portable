[![Discord](https://img.shields.io/discord/384870460640329728.svg?logo=discord)](https://discord.gg/G2kxrnU)

Official Old School RuneScape client made cross-platform and portable.
Saves all dependencies and game files to a self-contained directory.

### Requirements

* Supported platforms: Windows x64, Windows x32, macOS x64, Linux x64, Linux aarch64, Linux arm32
* Downloads ~200 MB on first run, uses ~40 MB total disk space afterwards (excluding game cache)

### Download

Download as [**.zip**](https://github.com/RuneStar/official-client-portable/archive/master.zip) or [**.tar.gz**](https://github.com/RuneStar/official-client-portable/archive/master.tar.gz) and extract to the desired location

### Running

Execute `client.cmd` (Windows Batch file) or `client.command` (Shell script) to launch the client

### jagexappletviewer

`jagexappletviewer.jar`, `jagexappletviewer.png`, and `legal/jagexappletviewer.LICENCSE` have been extracted from the official Windows client using the following method

```sh
curl -O https://www.runescape.com/downloads/OldSchool.msi
cmd.exe /c "msiexec /a OldSchool.msi /qn TARGETDIR=%cd%\msi"
cp msi/jagexlauncher/jagexlauncher/bin/jagexappletviewer.jar jagexappletviewer.jar
cp msi/jagexlauncher/jagexlauncher/oldschool/jagexappletviewer.png jagexappletviewer.png
cp msi/jagexlauncher/jagexlauncher/LICENSE.txt legal/jagexappletviewer.LICENSE
zip -d jagexappletviewer.jar MacOSXHelpers.class
```
