cd /d "%~dp0"
:: Delete old installer ZIP
del Twrp-recoveryInstaller-3.2.1-2-oreo-Treble.zip >nul
:: Pack Aroma resources
cd "%~dp0\.."
del ramdisk-recovery\treble_manager\aroma_res.zip
cd ___treble_manager
zip -r -1 "%~dp0\..\ramdisk-recovery\treble_manager\aroma_res.zip" *
:: Repack ramdisk
cd /d "%~dp0"
call repack_img.cmd
:: Create installer image
cd /d "%~dp0\.."
zip -r -1 "%~dp0\Twrp-recoveryInstaller-3.2.1-2-oreo-Treble.zip" * -x "___*" -x "ramdisk-recovery/*"
:: Cleanup
del ramdisk-recovery.img
del ramdisk-recovery\treble_manager\aroma_res.zip
