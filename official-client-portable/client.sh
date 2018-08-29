#!/bin/bash
curl http://www.runescape.com/downloads/jagexappletviewer.jar -O
java -jar -Duser.home="$(dirname "$BASH_SOURCE")" -Dsun.awt.noerasebackground=true -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws jagexappletviewer.jar official-client-portable
rm jagexappletviewer.jar