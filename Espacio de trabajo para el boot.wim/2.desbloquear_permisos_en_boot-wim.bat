@echo off
chcp 65001 >NUL
title Desbloqueando permisos del contenido del boot.wim...
setlocal

set "BASE_DIR=%~dp0_boot-wim_montado"

::Si añades algún nuevo archivo a inyectar y crees que deberías blindar sus permisos, mételo en esta lista.
for %%A in (
    "%BASE_DIR%\Terraformador.bat"
    "%BASE_DIR%\Windows\System32\findstr.exe"
    "%BASE_DIR%\Windows\System32\setup.bmp"
    "%BASE_DIR%\Windows\System32\startnet.cmd"
    "%BASE_DIR%\Windows\System32\timeout.exe"
    "%BASE_DIR%\Windows\System32\winpeshl.ini"
) do (
    echo Editando los permisos del archivo %%~A
    takeown /f "%%~A"
	icacls "%%~A" /grant "*S-1-1-0:(F)"
	icacls "%%~A" /setowner "*S-1-1-0"
    echo.
)
endlocal
