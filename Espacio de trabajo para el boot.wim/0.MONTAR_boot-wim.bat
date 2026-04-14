@echo off
chcp 65001 >NUL
title Montando el archivo boot.wim...

dism /Unmount-Image /MountDir:"%~dp0_boot-wim_montado" /Discard 2>nul
dism /Cleanup-Mountpoints 2>nul
rmdir /s /q "%~dp0_boot-wim_montado" 2>nul
mkdir "%~dp0_boot-wim_montado" 2>nul
dism /Mount-Image /ImageFile:"%~dp0boot.wim" /Index:2 /MountDir:"%~dp0_boot-wim_montado"
del "%~dp0_boot-wim_montado\setup.exe" /F /Q
