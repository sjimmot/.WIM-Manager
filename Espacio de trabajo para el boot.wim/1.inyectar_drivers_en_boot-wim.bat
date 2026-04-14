@echo off
chcp 65001 >NUL
title Inyectando drivers al boot.wim...

dism.exe /Image:"%~dp0_boot-wim_montado" /Add-Driver /Driver:"%~dp0Drivers a inyectar" /Recurse /ForceUnsigned
