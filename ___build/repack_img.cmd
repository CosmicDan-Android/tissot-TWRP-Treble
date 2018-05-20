@ECHO OFF
CD ..
IF NOT EXIST ramdisk-recovery (
	ECHO [!] Folder 'ramdisk-recovery' does not exist.
	pause
)
@ECHO ON
___build\mkbootfs ramdisk-recovery | ___build\gzip > ramdisk-recovery.img
@ECHO OFF
CD /D "%~dp0"