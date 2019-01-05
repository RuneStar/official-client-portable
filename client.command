#!/bin/sh

set -eu

download_file() {
	if type curl >/dev/null 2>&1
	then
		curl -Lfo "$@"
	else
		wget -O "$@"
	fi
}

cd "$(dirname "$0")"

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
esac

platform="$os-$arch"
case $platform in
	windows-x64|windows-x32|mac-x64|linux-x64|linux-aarch64) ;;
	*)
		printf "Unsupported platform: %s\n" "$platform"
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

jre_dir="jre-$java_version-$platform/"

if test ! -d "$jre_dir"
then
	temp_dir="temp/"
	mkdir -p "$temp_dir"
	
	temp_jdk_archive="$temp_dir/jdk-$java_version-$platform$archive_extension"
	if test ! -f "$temp_jdk_archive"
	then
		download_file "$temp_jdk_archive" "https://api.adoptopenjdk.net/v2/binary/nightly/openjdk$java_version?openjdk_impl=hotspot&release=latest&type=jdk&heap_size=normal&os=$os&arch=$arch"
	fi

	temp_jdk_dir="$temp_dir/jdk-$java_version-$platform/"
	mkdir -p "$temp_jdk_dir"
	case $os in
		windows)
			unzip -o "$temp_jdk_archive" -d "$temp_jdk_dir"
			temp_jdk_home="$temp_jdk_dir/$(ls $temp_jdk_dir)"
			;;
		linux)
			tar -zxf "$temp_jdk_archive" --strip-components=1 -C "$temp_jdk_dir"
			temp_jdk_home="$temp_jdk_dir"
			;;
		mac)
			tar -zxf "$temp_jdk_archive" --strip-components=1 -C "$temp_jdk_dir"
			temp_jdk_home="$temp_jdk_dir/Contents/Home"
			;;
	esac

	"$temp_jdk_home/bin/jlink$exe_extension" \
	 --verbose \
	 --no-header-files \
	 --no-man-pages \
	 --strip-debug \
	 --compress=1 \
	 --module-path "$temp_jdk_home\jmods" \
	 --add-modules java.desktop,java.management \
	 --output "$jre_dir"

	rm -rfv "$temp_dir"
fi

if test ! -f jagexappletviewer.jar
then
	download_file jagexappletviewer.jar http://www.runescape.com/downloads/jagexappletviewer.jar
fi

if test "$os" = mac
then
	zip -d jagexappletviewer.jar MacOSXHelpers.class || true
fi

mkdir -p cache

"$jre_dir/bin/java$exe_extension" \
 -Duser.home=cache \
 -Dsun.awt.noerasebackground=true \
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws \
 -jar jagexappletviewer.jar \
 "$(basename "$(pwd)")"