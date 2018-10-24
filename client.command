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

_jre_dir="jre-$_os-$_arch/"

if [ ! -d "$_jre_dir" ]; then
	_jdk_dir="jdk-$_os-$_arch/"
	_temp_jdk_dl="temp-jdk-dl"
	
	curl -Lfo "$_temp_jdk_dl" "https://api.adoptopenjdk.net/v2/binary/releases/openjdk11?openjdk_impl=hotspot&release=latest&type=jdk&heap_size=normal&os=$_os&arch=$_arch"
	
	if [ "$_os" = "windows" ]; then
		_temp_jdk_dir="temp-jdk-dir/"
		unzip -d "$_temp_jdk_dir" "$_temp_jdk_dl"
		cp -r "$_temp_jdk_dir/$(ls $_temp_jdk_dir)" "$_jdk_dir"
		rm -rfv "$_temp_jdk_dir"
	else
		mkdir -p "$_jdk_dir"
		tar -zxf "$_temp_jdk_dl" --strip-components=2 -C "$_jdk_dir"
	fi
	
	rm -v "$_temp_jdk_dl"
	
	"$_jdk_dir/bin/jlink" \
	 -v \
 	 --no-header-files \
	 --no-man-pages \
	 --strip-debug \
	 --compress=2 \
	 --module-path "$_jdk_dir\jmods" \
	 --add-modules java.desktop,java.management \
	 --output "$_jre_dir"
	 
	rm -rv "$_jdk_dir"
fi

"$_jre_dir/bin/java" --version

curl -fO http://www.runescape.com/downloads/jagexappletviewer.jar

mkdir -p cache

"$_jre_dir/bin/java" \
 -jar \
 -Duser.home=cache \
 -Dsun.awt.noerasebackground=true \
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws \
 jagexappletviewer.jar "$(basename "$(pwd)")"

rm -v jagexappletviewer.jar