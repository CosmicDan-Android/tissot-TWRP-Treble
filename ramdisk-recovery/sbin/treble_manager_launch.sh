#!/sbin/sh
/treble_manager/aroma 1 0 /treble_manager/aroma_res.zip >/tmp/aroma_log.txt
cp -f /treble_manager/aroma_res.zip.log.txt /sdcard1/treble_manager.log
reboot recovery
