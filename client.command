#!/bin/sh

set -e

cd "$(dirname "$0")"

_os=$(uname | tr '[:upper:]' '[:lower:]')
case $_os in
	darwin) _os=mac ;;
	msys*|cygwin*|mingw*) _os=windows ;;
esac

_arch=$(uname -m | tr '[:upper:]' '[:lower:]')
case $_arch in
	x86_64|amd64) _arch=x64 ;;
	i386|i686) _arch=x32 ;;
esac

_java_version="11"

_jre_dir="jre-$_java_version-$_os-$_arch/"

if [ ! -d "$_jre_dir" ]; then
	_temp_dir="temp/"
	mkdir -p "$_temp_dir"
	
	_temp_jdk_archive="$_temp_dir/jdk-$_java_version-$_os-$_arch-archive"
	curl -Lfo "$_temp_jdk_archive" "https://api.adoptopenjdk.net/v2/binary/releases/openjdk$_java_version?openjdk_impl=hotspot&release=latest&type=jdk&heap_size=normal&os=$_os&arch=$_arch"
	
	_temp_jdk_dir="$_temp_dir/jdk-$_java_version-$_os-$_arch/"
	mkdir -p "$_temp_jdk_dir"
	
	if [ "$_os" = "windows" ]; then
		unzip -d "$_temp_jdk_dir" "$_temp_jdk_archive"
	else
		tar -zxf "$_temp_jdk_archive" --strip-components=1 -C "$_temp_jdk_dir"
	fi
	
	_jdk_home="$_temp_jdk_dir/$(ls $_temp_jdk_dir)"
	
	"$_jdk_home/bin/jlink" -v \
 	 --no-header-files \
	 --no-man-pages \
	 --strip-debug \
	 --compress=2 \
	 --module-path "$_jdk_home\jmods" \
	 --add-modules java.desktop,java.management \
	 --output "$_jre_dir"
	 
	rm -rfv "$_temp_dir"
fi

curl -fO http://www.runescape.com/downloads/jagexappletviewer.jar

mkdir -p cache

"$_jre_dir/bin/java" -jar \
 -Duser.home=cache \
 -Dsun.awt.noerasebackground=true \
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws \
 jagexappletviewer.jar "$(basename "$(pwd)")"
 
rm -v jagexappletviewer.jar