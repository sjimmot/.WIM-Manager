@echo off
chcp 65001 >NUL
title Bloqueando permisos del contenido del boot.wim...
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
    icacls "%%~A" /inheritance:r    
    icacls "%%~A" /grant "*S-1-15-2-2:(RX)"
    icacls "%%~A" /grant "*S-1-15-2-1:(RX)"
    icacls "%%~A" /grant "*S-1-5-32-545:(RX)"
    icacls "%%~A" /grant "*S-1-5-18:(RX)"
    icacls "%%~A" /grant "*S-1-5-32-544:(RX)"
    icacls "%%~A" /grant "*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(F)"
	icacls "%%~A" /setowner "*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464"
	icacls "%%~A" /remove "*S-1-1-0"
)
endlocal
