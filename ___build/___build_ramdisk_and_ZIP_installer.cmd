cd /d "%~dp0"
del ..\Twrp-recoveryInstaller-3.2.1-2-oreo-Treble.zip >nul
call repack_img.cmd
cd ..
zip -r -1 "%~dp0\Twrp-recoveryInstaller-3.2.1-2-oreo-Treble.zip" * -x "___build*" -x "ramdisk-recovery/*"
del ramdisk-recovery.img
::adb shell mkdir /sdcard1/System/
::adb push TissotTreblizer.zip /sdcard1/System/
pause
