#!/bin/sh

set -e

cd "$(dirname "$0")"

_os=$(uname | tr '[:upper:]' '[:lower:]')
case $_os in
	darwin) _os=mac ;;
	msys*|cygwin*|mingw*) _os=windows ;;
esac

grep -q Microsoft /proc/version && _os=windows

_arch=$(uname -m | tr '[:upper:]' '[:lower:]')
case $_arch in
	x86_64|amd64) _arch=x64 ;;
	x86|i[3456]86) _arch=x32 ;;
	armv8*) _arch=aarch64 ;;
	armv*) _arch=arm32 ;;
esac

_platform="$_os-$_arch"
case $_platform in
	windows-x64|mac-x64|linux-x64|linux-aarch64)
		_java_version=11
		_type=jdk
		;;
	linux-arm32)
		_java_version=10
		_type=jdk
		;;
	windows-x32)
		_java_version=8
		_type=jre
		;;
	*)
		echo "Unsupported platform: $_platform"
		exit 1
		;;
esac

case $_os in
	windows) _exe_extension=.exe ;;
	*) _exe_extension= ;;
esac

_jre_dir="jre-$_java_version-$_platform/"

if [ ! -d "$_jre_dir" ]; then
	_temp_dir="temp/"
	mkdir -p "$_temp_dir"
	
	_temp_jdk_archive="$_temp_dir/$_type-$_java_version-$_platform-archive"
	if [ ! -f "$_temp_jdk_archive" ]; then
		curl -Lfo "$_temp_jdk_archive" "https://api.adoptopenjdk.net/v2/binary/releases/openjdk$_java_version?openjdk_impl=hotspot&release=latest&type=$_type&heap_size=normal&os=$_os&arch=$_arch"
	fi

	_temp_jdk_dir="$_temp_dir/$_type-$_java_version-$_platform/"
	mkdir -p "$_temp_jdk_dir"
	
	case $_os in
		windows)
			unzip -d "$_temp_jdk_dir" "$_temp_jdk_archive"
			_jdk_home="$_temp_jdk_dir/$(ls $_temp_jdk_dir)"
			;;
		linux)
			tar -zxf "$_temp_jdk_archive" --strip-components=1 -C "$_temp_jdk_dir"
			_jdk_home="$_temp_jdk_dir/$(ls $_temp_jdk_dir)"
			;;
		mac)
			tar -zxf "$_temp_jdk_archive" --strip-components=1 -C "$_temp_jdk_dir"
			_jdk_home="$_temp_jdk_dir/$(ls $_temp_jdk_dir)/Contents/Home"
			;;
	esac
	
	case $_type in
		jdk)
			"$_jdk_home/bin/jlink$_exe_extension" -v \
			 --no-header-files \
			 --no-man-pages \
			 --strip-debug \
			 --compress=2 \
			 --module-path "$_jdk_home\jmods" \
			 --add-modules java.desktop,java.management \
			 --output "$_jre_dir"
			;;
		jre)
			cp -r "$_jdk_home" "$_jre_dir/"
			;;
	esac
	
	rm -rfv "$_temp_dir"
fi

curl -fO http://www.runescape.com/downloads/jagexappletviewer.jar

mkdir -p cache

"$_jre_dir/bin/java$_exe_extension" -jar \
 -Duser.home=cache \
 -Dsun.awt.noerasebackground=true \
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws \
 jagexappletviewer.jar "$(basename "$(pwd)")"

rm -v jagexappletviewer.jar