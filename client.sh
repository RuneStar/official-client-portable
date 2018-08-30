#!/bin/bash

set -e

_JAVA_COMMAND=java

cd "$(dirname "$BASH_SOURCE")"

_DIR_BASENAME="$(basename "$(pwd)")"

$_JAVA_COMMAND --version

curl http://www.runescape.com/downloads/jagexappletviewer.jar -O

mkdir -p cache

$_JAVA_COMMAND -jar \
 -Duser.home=cache \
 -Dsun.awt.noerasebackground=true \
 -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws \
 jagexappletviewer.jar $_DIR_BASENAME

rm jagexappletviewer.jar