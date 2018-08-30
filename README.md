Saves all game files (cache, preferences, etc) to the current directory

### Running

1. [**Download**](https://github.com/RuneStar/official-client-portable/archive/master.zip) project as `.zip`
2. Extract to the desired location
3. Set-up Java. Requires Java 7+. Options:
	* Use the system's current installed version Java. Works by default without configuration
	* Include a self-contained copy of Java with the following steps:
		1. Download compatible Java JRE binaries to a subdirectory
		2. Inside `client.*` scripts change the value of `_JAVA_COMMAND` to the new Java path such as `"jre-10.0.2\bin\java.exe"`
4. Execute `client.bat` or `client.sh` to launch the client
