No installation. Saves all game files (cache, preferences, etc) to the current directory. Cross-platform

### Running

1. [**Download**](https://github.com/RuneStar/official-client-portable/archive/master.zip) project as `.zip` and extract to the desired location
2. Set-up Java. Requires Java 7+. Options:
	1. Use the system's current installed version of Java. Works by default without configuration
	2. Include a self-contained copy of Java with the following steps:
		1. Download compatible Java binaries to a subdirectory. Downloads: [**Oracle**](https://www.oracle.com/technetwork/java/javase/downloads/index.html), [**AdoptOpenJDK**](https://adoptopenjdk.net/nightly.html?variant=openjdk10), [**Zulu**](https://www.azul.com/downloads/zulu/)
		2. Inside `client.*` scripts change the value of `_JAVA_COMMAND` to the new Java path such as `"jre-10.0.2\bin\java.exe"`
3. Execute `client.bat` or `client.command` to launch the client
