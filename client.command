#!/bin/sh

set -eu

download_file() {
	if command -v curl >/dev/null
	then
		curl -Lfo "$@"
	elif command -v wget >/dev/null
	then
		wget -O "$@"
	else
		echo 'missing required command: curl or wget'
		exit 1
	fi
}

cd -- "$(dirname -- "${BASH_SOURCE:-$0}")"

if grep Microsoft /proc/version >/dev/null 2>&1
then
	os=windows
else
	os=$(uname | tr '[:upper:]' '[:lower:]')
	case $os in
		darwin) os=mac ;;
		msys*|cygwin*|mingw*) os=windows ;;
	esac
fi

arch=$(uname -m | tr '[:upper:]' '[:lower:]')
case $arch in
	x86_64|amd64) arch=x64 ;;
	x86|i[3456]86) arch=x32 ;;
	armv8*) arch=aarch64 ;;
	armv*) arch=arm ;;
esac

platform=$os-$arch
case $platform in
	windows-x64|windows-x32|mac-x64|linux-x64|linux-aarch64|linux-arm) ;;
	*)
		echo "unsupported platform: $platform"
		exit 1
		;;
esac

case $os in
	windows)
		exe_extension=.exe
		archive_extension=.zip
		;;
	*)
		exe_extension=
		archive_extension=.tar.gz
		;;
esac

java_version=11
jre_dir=jre-$platform/

if test ! -d "$jre_dir"
then
	temp_dir=temp/
	mkdir -p "$temp_dir"
	jdk_archive=$temp_dir/jdk-$java_version-$platform$archive_extension
	if test ! -f "jdk_archive"
	then
		jdk_archive_url=https://api.adoptopenjdk.net/v3/binary/latest/$java_version/ga/$os/$arch/jdk/hotspot/normal/adoptopenjdk
		download_file "$jdk_archive" "$jdk_archive_url"
	fi
	jdk_dir=$temp_dir/jdk-$java_version-$platform/
	mkdir -p "$jdk_dir"
	case $os in
		windows)
			unzip -o "$jdk_archive" -d "$jdk_dir"
			jdk_home="$jdk_dir/*/"
			;;
		linux)
			tar -zxf "$jdk_archive" -C "$jdk_dir"
			jdk_home="$jdk_dir/*/"
			;;
		mac)
			tar -zxf "$jdk_archive" -C "$jdk_dir"
			jdk_home="$jdk_dir/*/Contents/Home/"
			;;
	esac
	jdk_home=$(set -- $jdk_home; printf %s "$1")

	"$jdk_home/bin/jlink$exe_extension" \
		--verbose \
		--no-header-files \
		--no-man-pages \
		--strip-debug \
		--compress=2 \
		--module-path "$jdk_home/jmods" \
		--add-modules java.desktop,java.management \
		--output "$jre_dir"

	rm -rf "$temp_dir"
fi

mkdir -p cache

"$jre_dir/bin/java$exe_extension" \
	-Duser.home=cache \
	-Dsun.awt.noerasebackground=true \
	-Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws \
	-jar jagexappletviewer.jar \
	"$(basename "$PWD")"
