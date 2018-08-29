powershell -Command "Invoke-WebRequest -OutFile jagexappletviewer.jar http://www.runescape.com/downloads/jagexappletviewer.jar"
java -jar -Duser.home="%~dp0." -Dsun.awt.noerasebackground=true -Dcom.jagex.configuri=jagex-jav://oldschool.runescape.com/jav_config.ws jagexappletviewer.jar official-client-portable
del jagexappletviewer.jar