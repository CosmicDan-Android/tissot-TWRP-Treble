@echo off
zip -r -1 "%~dp0\aroma_res.zip" *
adb push aroma_res.zip /treble_manager/
del aroma_res.zip
adb shell /sbin/treble_manager.sh

