cd /d "%~dp0"
call ___build_ramdisk_and_ZIP_installer.cmd
cd /d "%~dp0"
adb shell mkdir /sdcard1/System/
adb push Twrp-recoveryInstaller-3.2.1-2-oreo-Treble.zip /sdcard1/System/
