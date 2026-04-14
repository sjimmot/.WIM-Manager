@echo off
chcp 65001 >NUL
title Inyectando drivers al boot.wim...

xcopy "%~dp0Contenido a inyectar\*" "%~dp0_boot-wim_montado\" /E /H /R /Y
