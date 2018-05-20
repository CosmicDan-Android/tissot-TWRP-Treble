@ECHO OFF
CD ..
IF EXIST ramdisk-recovery (
	ECHO [!] Folder 'ramdisk-recovery' already exists.
	pause
)
MKDIR ramdisk-recovery
CD ramdisk-recovery
@ECHO ON
..\___build\gzip.exe -dc ..\ramdisk-recovery.img | ..\___build\cpio -i
@ECHO OFF
CD /D "%~dp0"