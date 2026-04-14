@echo off
chcp 65001 >NUL
title Aplicando cambios al boot.wim de origen, optimizando y exportando el archivo resultante...
DISM /Unmount-Wim /MountDir:"%~dp0_boot-wim_montado" /Commit
DISM /Export-Image /SourceImageFile:"%~dp0boot.wim" /SourceIndex:1 /DestinationImageFile:"%~dp0_BOOT-WIM-FINAL\boot.wim"  /DestinationName:"Microsoft Windows PE (x64)" /Compress:max
DISM /Export-Image /SourceImageFile:"%~dp0boot.wim" /SourceIndex:2 /DestinationImageFile:"%~dp0_BOOT-WIM-FINAL\boot.wim"  /DestinationName:"Microsoft Windows Setup (x64) + .WIM Manager (0.0.1.1)" /Compress:max
