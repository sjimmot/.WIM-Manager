
@echo off
chcp 65001 >NUL
setlocal ENABLEDELAYEDEXPANSION

:: Detectando el directorio de activos, priorizando primero la red (A:), y por último el resto de unidades...
for %%A in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%A:\colonizador.bat" set "unidad_de_activos=%%A:"
if exist "%unidad_de_activos%\colonizador.bat" goto unidad_de_activos_encontrada


:unidad_de_activos_no_encontrada
title .WIM Manager - ERROR - Unidad de activos NO encontrada.
mode con:cols=81 lines=27
echo            _
echo           / \                                                        /¨¨¨¨\
echo          / ^| \        /¨¨¨¨¨  /¨¨¨¨¨\  /¨¨¨¨¨\  /¨¨¨¨¨\  /¨¨¨¨¨\     \    ^|
echo         /  ^|  \       ^|       ^|     ^|  ^|     ^|  ^|     ^|  ^|     ^|      \   \
echo        /   ^|   \      ^|———    ^|/————/  ^|/————/  ^|     ^|  ^|/————/       \   \
echo       /    ^|    \     ^|       ^| ¨¨\    ^| ¨¨\    ^|     ^|  ^| ¨¨\          \___\
echo      /           \    \_____  ^|    ¨\  ^|    ¨\  \_____/  ^|    ¨\         ^|¨¨^|
echo     /      o      \                                                       ¨¨
echo    /               \   ^> Y fuerte, además: no se ha encontrado ninguna unidad
echo    ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨     de activos. Verifica que, por favor, estos se encuen-
echo                          tran en la raíz tal y como en el siguiente ejemplo:
echo.
echo  ------------------------------------------------------------------------------- 
echo.
echo   [-] Unidad de activos (red, BD-R, pendrive...)
echo    ^|-[^+] scripts_genericos_de_diskpart
echo    ^|
echo    ^|-[^+] HWConfig1 ^<-----------------------------------------------------------
echo    ^|-[^+] HWConfig2 ^<-- Carpetas con el nombre de las entradas en la whitelist ^|
echo    ^|                   ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
echo    ^| (...)
echo    ^|
echo    ^|- Colonizador.bat
echo    ^|- whitelist.txt
echo.
echo " ➤  Pulsa una tecla para reiniciar."
pause >nul
wpeutil reboot


:unidad_de_activos_encontrada
:: Iniciando y/o reseteando variables básicas...
for /f "tokens=2 delims==" %%B in ('wmic csproduct get UUID /value ^| findstr /i "UUID"') do set "uuid_local=%%B"
set "uuid_encontrado=0"
set "config_de_hw="
set "nombre_host="
set "uuid_y_config_encontradas=0"
set "leyendo_seccion=0"
set "ultima_posicion=menu"
set "entrada_seleccionada="
set "ajustessecretillos=0"
set "disco="
set "disco_preliminar="
set "error_ticket_id_desconocido="
set "checkintegrity=0"
set "checkintegrity_arg="
set "checkintegrity_estado=deshabilitado"
set "checkintegrity_por_defecto=deshabilitado"

:: Comprobando la existencia de la whitelist y comparando el UUID...
cls
title .WIM Manager - Obteniendo whitelist.txt, comparando UUIDs e importando configuración...
mode con:cols=81 lines=9
echo.
echo                [^|] Obteniendo whitelist.txt y comparando UUIDs...
echo                [ ] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
timeout /t 1 >nul
echo.
echo                [/] Obteniendo whitelist.txt y comparando UUIDs...
echo                [ ] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
timeout /t 1 >nul
echo.
echo                [—] Obteniendo whitelist.txt y comparando UUIDs...
echo                [ ] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
timeout /t 1 >nul
echo.
echo                [\] Obteniendo whitelist.txt y comparando UUIDs...
echo                [ ] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
if exist A:\whitelist.ini goto whitelist_encontrada


:whitelist_no_encontrada
title .WIM Manager - ERROR - Archivo whitelist.txt no encontrado.
mode con:cols=81 lines=12
echo.
echo                [X] Obteniendo whitelist.txt y comparando UUIDs...
echo                [?] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
echo.
echo             ^> El archivo whitelist.txt NO ha sido encontrado en "%unidad_de_activos%\".
echo                       Pulsa cualquier tecla para reiniciar.
pause >nul
wpeutil reboot


:whitelist_encontrada
:: Primera parte verdaderamente compleja. Aquí se intenta encontrar la cabecera de turno extraida justo después del UUID en la lista superior. Dicha cabecera también se encuentra al lado del nombre de host final.
set "whitelist=%unidad_de_activos%\whitelist.ini"

if exist "%whitelist%" (
	REM Se utiliza findstr con el modificador /b, entre otros, para buscar la línea que 
	REM empieza exactamente con el UUID local. El bucle se ejecuta hasta que encuentra esa línea.
	for /F "tokens=1,2* delims==" %%C in ('findstr /I /B /C:"%uuid_local%" "%whitelist%"') do (
        
        REM Si entramos aquí, es que YA hemos encontrado el UUID. No hace falta seguir.
        REM Almacenamos el resultado en una variable nueva.
		set "uuid_encontrado=1"
        
        REM %%C es el UUID (que ya sabemos que coincide)
        REM %%D es el resto de la línea (ej: HWConfig1,PC-DE-SAMU)
        REM Le decimos con delims que en esa línea, los diferentes valores están delimitados por una coma.

		for /F "tokens=1,2 delims=," %%E in ("%%D") do (
			set "nombre_host=%%F"
			set "hardware=%%E"
			set "config_de_hw=%unidad_de_activos%\_cfgs\%%E.ini"
		)
	)
)
if "%uuid_encontrado%"=="1" (
	if not "%hardware%"==""	(
		if not "%nombre_host%"==""	(
			goto uuid_encontrado
		)
	)
)
if "%uuid_encontrado%" EQU "1" goto uuid_encontrado_pero_sin_configuracion
goto uuid_no_encontrado


:uuid_no_encontrado
set "ticket_id_introducidoxd="
set "ultima_posicion=uuid_no_encontrado"
set "lineas=20"
if not "%error_ticket_id_desconocido%"=="" set /a lineas+=2
mode con:cols=81 lines=%lineas%
cls
title .WIM Manager - ERROR - El UUID no se ha encontrado en whitelist.txt.
echo.
echo                [-] Obteniendo whitelist.txt y comparando UUIDs...
echo                [?] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              Hardware irreconocible.
echo                     ========================================
echo.
echo  EL INSTALADOR NO RECONOCE este equipo. Sin embargo, puedes tratar de instalar
echo     una imagen ya sea personalizada, o bien genérica para más de un equipo,
echo                siempre y cuando tengas el ID/ticket para ello.
echo.
echo  IMPORTANTE: Desconecta ahora todo medio que sea prescindible como tarjetas SD,
echo  pendrives, discos duros externos etc y considera reiniciar y volver sin ellos.
echo.
if not "%error_ticket_id_desconocido%"=="" echo  %error_ticket_id_desconocido% & echo.
set /p ticket_id_introducido=" ➤  Escribe un ticket/ID válido, o bien R para reiniciar, y apreta INTRO: "
if /I "%ticket_id_introducido%"=="R" wpeutil reboot
goto obtener_configuracion_forzada_mediante_ticket_id


:uuid_encontrado
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [^|] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
timeout /t 1 >nul
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [/] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
timeout /t 1 >nul
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [—] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
timeout /t 1 >nul
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [\] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo                     ========================================
for /F "usebackq eol=; tokens=*" %%H in ("%config_de_hw%") do (
	set "LINEA=%%H"    
	REM Comprobamos si la línea es una cabecera de sección (empieza por corchete)
	if "!LINEA:~0,1!"=="[" (
		REM Comprobamos si es LA cabecera que buscamos
		if /I "!LINEA!"=="[%hardware%]" (
			set "uuid_y_config_encontradas=1"
			set "leyendo_seccion=1"
		) else (
			REM Si es cualquier otra cabecera (ej: [HWConfig2]), dejamos de leer
			set "leyendo_seccion=0"
		)
	) else (
		REM Si estamos dentro de la sección correcta (flag activada), importamos
		if "!leyendo_seccion!"=="1" (
			for /F "tokens=1* delims==" %%G in ("!LINEA!") do (
				if not "%%G"=="" (
					REM Importamos la variable al entorno
					set "%%G=%%H"
				)
			)
		)
	)
)
set "ticket_id_actual=%hardware%"
if "%uuid_y_config_encontradas%"=="1" goto toquecito_final_a_la_importacion_de_configuracion
goto uuid_encontrado_pero_sin_configuracion

:uuid_encontrado_pero_sin_configuracion
set "op="
set "ultima_posicion=uuid_encontrado_pero_sin_configuracion"
set "lineas=21"
if not "%error_ticket_id_desconocido%"=="" set /a lineas+=2
mode con:cols=81 lines=%lineas%
cls
title .WIM Manager - ERROR - Configuración no asociada al UUID.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [X] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                      Hardware reconocible pero sin entrada.
echo                     ========================================
echo.
echo  El instalador RECONOCE este equipo, pero no hay especificada ninguna config.
echo   asociada al UUID del mismo. Por favor, revisa el archivo "whitelist.txt".
echo.
echo    Puedes, sin embargo, tratar de instalar una imagen ya sea personalizada, o
echo  genérica para más de un equipo siempre y cuando tengas el ID/ticket para ello.
echo.
echo  IMPORTANTE: Desconecta ahora todo medio que sea prescindible como tarjetas SD,
echo  pendrives, discos duros externos etc y considera reiniciar y volver sin ellos.
echo.
if not "%error_ticket_id_desconocido%"=="" echo   %error_ticket_id_desconocido% & echo.
set /p ticket_id_introducido=" ➤  Escribe un ticket/ID válido, o bien R para reiniciar, y apreta INTRO: "
if /I "%ticket_id_introducido%"=="R" wpeutil reboot
goto obtener_configuracion_forzada_mediante_ticket_id


:uuid_y_config_encontradas
mode con:cols=81 lines=17
cls
title .WIM Manager - UUID VALIDO.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [√] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              %nombre_host% (%ticket_id_actual%)
echo                               Hardware reconocido.
echo                     ========================================
echo.
echo  IMPORTANTE: Desconecta ahora todo medio que sea prescindible como tarjetas SD,
echo  pendrives, discos duros externos etc y considera reiniciar y volver sin ellos.
echo.
echo               Luego simplemente presiona una tecla para continuar.
pause >nul
if %omitir_seleccion_manual_de_disco%=="1" set "disco=%numero_de_disco_preseleccionado%" & goto menu
goto pillodisco


:obtener_configuracion_forzada_mediante_ticket_id
set "ticket_id_introducido_es_correcto=0"
if not exist "%unidad_de_activos%\_cfgs\%ticket_id_introducido%.ini" goto ticket_id_introducido_no_existe
for /F "usebackq eol=; tokens=*" %%H in ("%unidad_de_activos%\_cfgs\%ticket_id_introducido%.ini") do (
	set "LINEA=%%H"
	REM Comprobamos si la línea es una cabecera de sección (empieza por corchete)
	if "!LINEA:~0,1!"=="[" (
		REM Comprobamos si es LA cabecera que buscamos
		if /I "!LINEA!"=="[%ticket_id_introducido%]" (
			set "leyendo_seccion=1"
			set "ticket_id_introducido_es_correcto=1"
		) else (
			REM Si es cualquier otra cabecera (ej: [HWConfig2]), dejamos de leer
			set "leyendo_seccion=0"
		)
	) else (
		REM Si estamos dentro de la sección correcta (flag activada), importamos
		if "!leyendo_seccion!"=="1" (
			for /F "tokens=1* delims==" %%G in ("!LINEA!") do (
				if not "%%G"=="" (
					REM Importamos la variable al entorno
					set "%%G=%%H"
				)
			)
		)
	)
)
set "ticket_id_actual=%ticket_id_introducido%"
if "%ticket_id_introducido_es_correcto%"=="1" goto toquecito_final_a_la_importacion_de_configuracion_forzada_mediante_ticket_id
:ticket_id_introducido_no_existe
set "ticket_id_introducido="
set "error_ticket_id_desconocido=(X) No se reconoce este ID/ticket. ¿Está bien escrito?"
goto %ultima_posicion%


:comprobacion_del_nombre_de_host_para_inyeccion
set "nombre_host_errado=0"
if "%nombre_host%"=="" set "nombre_host_errado=1"
if not "%nombre_host:~15,1%"=="" set "nombre_host_errado=2"
echo %nombre_host%| findstr /r /i "[^a-z0-9-]" >nul
if %errorlevel% equ 0 set "nombre_host_errado=3"
if "%se_esta_intentando_corregir_el_nombre_de_host%"=="1" goto toquecito_final_a_la_inyeccion_de_nombre_de_host


:toquecito_final_a_la_importacion_de_configuracion
if "%ea%"=="0" set "ea_arg= " & set "ea_estado=deshabilitado" & set "ea_por_defecto=deshabilitado"
if "%ea%"=="1" set "ea_arg=/EA" & set "ea_estado=habilitado" & set "ea_por_defecto=habilitado"
if "%compact%"=="0" set "compact_arg= " & set "compact_estado=deshabilitado" & set "compact_por_defecto=deshabilitado"
if "%compact%"=="1" set "compact_arg=/Compact" & set "compact_estado=habilitado" & set "compact_por_defecto=habilitado"
if "%instalacion_desatendida%"=="1" (
	if "%numero_de_sistema_preseleccionado%" GEQ "1" (
		if "%numero_de_variante_de_sistema_preseleccionada%" GEQ "1" (
			if "%omitir_seleccion_manual_de_disco%"=="1" (
				if defined numero_de_disco_preseleccionado (
					goto bypass_por_instalacion_desatendida
				)
			)
		)
	)
)
goto uuid_y_config_encontradas


:toquecito_final_a_la_importacion_de_configuracion_forzada_mediante_ticket_id
set "ultima_posicion=menu"
set "error_ticket_id_desconocido="
set "mostrar_id_personalizado=1"
if %ea% EQU 0 set "ea_arg= " & set "ea_estado=deshabilitado" & set "ea_por_defecto=deshabilitado"
if %ea% EQU 1 set "ea_arg=/EA" & set "ea_estado=habilitado" & set "ea_por_defecto=habilitado"
if %compact% EQU 0 set "compact_arg= " & set "compact_estado=deshabilitado" & set "compact_por_defecto=deshabilitado"
if %compact% EQU 1 set "compact_arg=/Compact" & set "compact_estado=habilitado" & set "compact_por_defecto=habilitado"
goto pillodisco


:bypass_por_instalacion_desatendida
mode con:cols=81 lines=14
cls
title .WIM Manager - UUID VALIDO.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [√] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              %nombre_host% (%ticket_id_actual%)
echo                               Hardware reconocido.
echo                     ========================================
echo.
echo " ➤ La instalación está configurada como desatendida, por lo que empezará en 5"
timeout /t 1 >nul
title .WIM Manager - UUID VALIDO.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [√] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              %nombre_host% (%ticket_id_actual%)
echo                               Hardware reconocido.
echo                     ========================================
echo.
echo " ➤ La instalación está configurada como desatendida, por lo que empezará en 4."
timeout /t 1 >nul
title .WIM Manager - UUID VALIDO.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [√] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              %nombre_host% (%ticket_id_actual%)
echo                               Hardware reconocido.
echo                     ========================================
echo.
echo " ➤ La instalación está configurada como desatendida, por lo que empezará en 3.."
timeout /t 1 >nul
title .WIM Manager - UUID VALIDO.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [√] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              %nombre_host% (%ticket_id_actual%)
echo                               Hardware reconocido.
echo                     ========================================
echo.
echo " ➤ La instalación está configurada como desatendida, por lo que empezará en 2..."
timeout /t 1 >nul
title .WIM Manager - UUID VALIDO.
echo.
echo                [√] Obteniendo whitelist.txt y comparando UUIDs...
echo                [√] Importando configuración desde whitelist.txt...
echo.
echo                     ========================================
echo                               UUID de este equipo:
echo                       %uuid_local%
echo.
echo                              %nombre_host% (%ticket_id_actual%)
echo                               Hardware reconocido.
echo                     ========================================
echo.
echo " ➤ La instalación está configurada como desatendida, por lo que empezará en 1...."
timeout /t 1 >nul
set "num_so=%numero_de_sistema_preseleccionado%"
set "num_var=%numero_de_variante_de_sistema_preseleccionada%"
set "disco=%numero_de_disco_preseleccionado%"
goto toquecito_final_a_la_inyeccion_de_nombre_de_host


:pillodisco
set "op="
set "disco_preliminar="
set "disco="
mode con:cols=81 lines=40
cls
title .WIM Manager - !sistema%num_so%_nombre!%separador_si_hay_SO_seleccionado%Lista de discos: seleccionando...
echo ---------------------------------------------------------------------------------
echo.
echo       Antes de empezar nada, debes identificar cual es el disco donde tienes
echo     instalado Windows. Justo debajo tienes una lista de los discos conectados:
echo.
echo      Guíate por la capacidad del disco. Un paso más adelante verás una lista de
echo   las particiones que contiene el mismo. Por último, tendrás que confirmar si el
echo   disco seleccionado es el correcto o, si por el contrario, prefieres pensártelo
echo                                       mejor.
echo.
echo  También puedes seleccionar otro disco, nada te lo impide. Sin embargo, el disco
echo           se formateará; asegúrate de que está vacío o existe respaldo.
echo.
echo ---------------------------------------------------------------------------------
echo.
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\mostrar_discos.txt
echo.
set /p disco_preliminar=" ➤  Escoge un disco para marcar y ver sus particiones, y apreta INTRO (0-9): "
for /L %%i in (0,1,9) do (if "%disco_preliminar%"=="%%i" goto pillodisco_particiones)
goto pillodisco


:pillodisco_particiones
set "op="
mode con:cols=81 lines=40
cls
title .WIM Manager - !sistema%num_so%_nombre!%separador_si_hay_SO_seleccionado%Lista de particiones: seleccionando...
echo ---------------------------------------------------------------------------------
echo.
echo    Ahora que has seleccionado un disco, y en caso de querer sobreescribir una
echo   instalación ya existente, comprueba que este contiene AL MENOS 4 PARTICIONES,
echo                     y cada una con las siguientes etiquetas:
echo               "Sistema", "Reservado", "Recuperación" y "Principal".
echo.
echo  Cuidado con las quintas, sextas y demás particiones: no forman parte de una
echo  instalación normal de Windows, y muy probablemente se hayan creado después.
echo    borrarlas mediante su reparticionado podría suponer la pérdida de datos.
echo.
echo ---------------------------------------------------------------------------------
echo.
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\mostrar_particiones_disco%disco_preliminar%.txt
echo.
set /p op=" ➤  ¿Es este el disco deseado? Escribe SI o NO, y apreta INTRO: "
echo %op%| findstr /I "SI SÍ" >nul && goto pillodisco_confirmado
echo %op%| findstr /I "NO" >nul && goto pillodisco
goto pillodisco_particiones


:pillodisco_confirmado
set "disco=%disco_preliminar%"
set "disco_preliminar="
goto %ultima_posicion%


:ajustessecretillos_menu
set "op="
mode con:cols=81 lines=41
cls
title .WIM Manager - ★ AJUSTES SECRETOS.
echo ---------------------------------------------------------------------------------
echo.
echo       Instalador desatendido y automatizado para dummies here^^! Level 5^^!
echo.
echo     Estás en los ajustes ultrasecretíííísimos... aunque, quizás, ya no tanto.
echo     Pese a que he hecho un esfuerzo por explicar todos ellos de ellos, puede
echo                   que no comprendas del todo para qué sirven.
echo.
echo                      Y en ese caso...
echo                                    ¡...MEJOR NO TOQUES NADA^^!
echo.
echo ---------------------------------------------------------------------------------
echo.
echo    ##########################     Script-paghettizado por: Samuel Jimenez Motos
echo    # SELECCIONA UNA OPCIÓN: #                                         (0.0.1.1)
echo    ##########################
echo.
echo.
echo  1 - Activar/desactivar el uso del modo compacto (estado: %compact_estado%).
echo      (^^!) Esta opción permite ahorrar unos cuantos gigabytes en la partición
echo          "C:\". Consiste en comprimir los archivos del sistema, y por lo
echo          general, su uso es bastante seguro. Ajuste %compact_por_defecto% por defecto.
echo.
echo.
echo  2 - Activar/desactivar los atributos extendidos (estado: %ea_estado%).
echo      (^^!) Esta opción permite retener toda la información adicional relacionada
echo          con marcas de confianza y de seguridad en el sistema de archivos.
echo          Ajuste %ea_por_defecto% por defecto.
echo.
echo.
echo  3 - Activar/desactivar la comprobación de integridad (estado: %checkintegrity_estado%).
echo      (^^!) Esta opción comprobará la integridad de las imágenes .WIM y .ESD
echo          antes de aplicarlas. Puede reducir considerablemente la velocidad de
echo          aplicación de la imagen. Ajuste %checkintegrity_por_defecto% por defecto.
echo.
echo.
echo  C - ★ Abrir un Símbolo del sistema (a.k.a cmd.exe o consola de comandos).
echo  X - Volver al menú principal.
echo.
set /p op=" ➤  Escoge una opción escribiendo el caracter y apretando INTRO: "
if "%op%"=="1" goto interruptor_compact
if "%op%"=="2" goto interruptor_ea
if "%op%"=="3" goto interruptor_checkintegrity
if /I "%op%"=="C" goto cmd
if /I "%op%"=="X" goto %ultima_posicion%
goto ajustessecretillos_menu


:menu_imagen_personalizada
title .WIM Manager - Especificando un ticket / ID personalizado...
set "ultima_posicion=menu_imagen_personalizada"
set "ticket_id_introducido="
set "lineas=11"
if not "%error_ticket_id_desconocido%"=="" set /a lineas+=2
mode con:cols=81 lines=%lineas%
echo.
echo  ------------------------------------------------------------------------------- 
echo   ★ Establecer un ticket/ID personalizado.
echo  ------------------------------------------------------------------------------- 
echo.
echo   Esta acción puede acarrear problemas inesperados. Instalar la imagen de otro
echo   equipo puede provocar un comportamiento inesperado tanto en local como en la
echo                                        red.
echo.
if not "%error_ticket_id_desconocido%"=="" echo  %error_ticket_id_desconocido% & echo.
set /p ticket_id_introducido=" ➤  Escribe un ticket/ID válido o bien M para volver al menú, y apreta INTRO: "
if /I "%ticket_id_introducido%"=="M" if defined ticket_id_actual goto restaurar_anterior_ticket_y_al_menu
goto obtener_configuracion_forzada_mediante_ticket_id


:restaurar_anterior_ticket_y_al_menu
set "ticket_id_introducido=%ticket_id_actual%"
set "ticket_id_introducido_es_correcto=1"
set "error_ticket_id_desconocido="
goto menu


:interruptor_ea
if "%ea%"=="1" (set "ea_arg=" & set "ea=0" & set "ea_estado=deshabilitado") else (set "ea_arg=/EA" & set "ea=1" & set "ea_estado=habilitado")
goto ajustessecretillos_menu

:interruptor_compact
if "%compact%"=="1" (set "compact_arg=" & set "compact=0" & set "compact_estado=deshabilitado") else (set "compact_arg=/Compact" & set "compact=1" & set "compact_estado=habilitado")
goto ajustessecretillos_menu

:interruptor_checkintegrity
if "%checkintegrity%"=="1" (set "checkintegrity_arg=" & set "checkintegrity=0" & set "checkintegrity_estado=deshabilitado") else (set "checkintegrity_arg=/CheckIntegrity" & set "checkintegrity=1" & set "checkintegrity_estado=habilitado")
goto ajustessecretillos_menu


:menu
set "%instalacion_desatendida%"=="0"
set "%numero_de_sistema_preseleccionado%"=="0"
set "%numero_de_variante_de_sistema_preseleccionada%"=="0"
set "%instalacion_desatendida_reiniciar_automaticamente_al_finalizar%"=="0"
set "op="
set "num_so="
set "separador_si_hay_SO_seleccionado="
set "ultima_posicion=menu"
set "lineas=22"
if "%cantidad_de_sistemas_operativos%" EQU "2" set /a lineas+=4
if "%cantidad_de_sistemas_operativos%" EQU "3" set /a lineas+=7
if "%cantidad_de_sistemas_operativos%" EQU "4" set /a lineas+=10
if "%ajustessecretillos%"=="1" set /a lineas+=2
if "%mostrar_id_personalizado%"=="1" set /a lineas+=2
mode con:cols=81 lines=%lineas%
cls
title .WIM Manager - MENÚ PRINCIPAL.
echo ---------------------------------------------------------------------------------
echo.
echo         Instalador desatendido y automatizado para dummies here^^! Level 5^^!
echo.
echo    Depende qué sistema escojas, la imagen podría contener diferentes ajustes y 
echo   variantes del mismo sistema en función del archivo ".ini" de la configuración
if "%ajustessecretillos%"=="0" echo                       de hardware correspondiente a tu UUID.
if "%ajustessecretillos%"=="1" echo     de hardware correspondiente a tu UUID, o bien del ticket/ID especificado,
if "%ajustessecretillos%"=="1" echo     ya sea una configuración de hardware forzada, o una imagen personalizada.
echo.
echo ---------------------------------------------------------------------------------
echo.
echo    ##########################     Script-paghettizado por: Samuel Jimenez Motos
echo    # SELECCIONA UNA OPCIÓN: #                                         (0.0.1.1)
echo    ##########################
echo.
echo  1 - Instalar %sistema1_nombre%.
echo      %sistema1_descripcion%
echo.
if "%cantidad_de_sistemas_operativos%" LSS "2" goto no_hay_mas_sistemas
echo  2 - Instalar %sistema2_nombre%.
echo      %sistema2_descripcion%
echo.
if "%cantidad_de_sistemas_operativos%" LSS "3" goto no_hay_mas_sistemas
echo  3 - Instalar %sistema3_nombre%.
echo      %sistema3_descripcion%
echo.
if "%cantidad_de_sistemas_operativos%" LSS "4" goto no_hay_mas_sistemas
echo  4 - Instalar %sistema4_nombre%.
echo      %sistema4_descripcion%
echo.
:no_hay_mas_sistemas
if "%mostrar_id_personalizado%"=="1" echo. & echo  O - ★ Especificar un id/ticket personalizado (usando: %ticket_id_actual%).
if "%ajustessecretillos%"=="1" echo  X - ★ Ajustes secretos.
echo.
echo  D - Escoger otro disco como target (actualmente seleccionado el disco: %disco%).
echo  R - Reiniciar.
echo.
set /p num_so=" ➤  Escoge una opción escribiendo el caracter y apretando INTRO: "

if "%num_so%"=="1" goto filtro_preparador_de_sistema_escogido
if "%num_so%"=="2" if "%cantidad_de_sistemas_operativos%" GEQ "2" goto filtro_preparador_de_sistema_escogido
if "%num_so%"=="3" if "%cantidad_de_sistemas_operativos%" GEQ "3" goto filtro_preparador_de_sistema_escogido
if "%num_so%"=="4" if "%cantidad_de_sistemas_operativos%" GEQ "4" goto filtro_preparador_de_sistema_escogido
if /I "%num_so%"=="D" goto pillodisco
if /I "%num_so%"=="R" goto reiniciar
if "%num_so%"=="plusultra" set "mostrar_id_personalizado=1" & goto menu
if /I "%num_so%"=="O" if "%mostrar_id_personalizado%"=="1" goto menu_imagen_personalizada
if "%num_so%"=="betyouneverseen" set "ajustessecretillos=1" & set "mostrar_id_personalizado=1" & goto menu
if "%num_so%"=="nahbroucrazygetmeouttahereffs" set "ajustessecretillos=0" & set "mostrar_id_personalizado=0" & goto menu
if /I "%num_so%"=="X" if "%ajustessecretillos%"=="1" goto ajustessecretillos_menu
goto menu

:filtro_preparador_de_sistema_escogido
if "!sistema%num_so%_variantes!"=="1" if "!sistema%num_so%_variante1_indice_de_imagen!" GEQ "1" set "num_var=1" & goto formateo_readytoflyonazipline
if "!sistema%num_so%_variantes!" GEQ "2" goto menu_sistema_escogido_contiene_variantes


:menu_sistema_escogido_contiene_variantes
set "ultima_posicion=menu_sistema_escogido_contiene_variantes"
set "op="
set "num_var="
set "separador_si_hay_SO_seleccionado= - "
set "lineas=25"
if "!sistema%num_so%_variantes!" GEQ "3" set /a lineas+=3
if "!sistema%num_so%_variantes!" GEQ "4" set /a lineas+=3
if "%mostrar_id_personalizado%"=="1" set /a lineas+=2
if "%ajustessecretillos%"=="1" set /a lineas+=1
if "%cantidad_de_sistemas_operativos%" GEQ "2" set /a lineas+=1
mode con:cols=81 lines=%lineas%
cls
title .WIM Manager - !sistema%num_so%_nombre! - Seleccionando variante...
echo ---------------------------------------------------------------------------------
echo.
echo         Instalador desatendido y automatizado para dummies here^^! Level 5^^!
echo.
echo              Este sistema operativo seleccionado contiene variantes.
echo                            Debes escoger entre ellas.
echo.
echo ---------------------------------------------------------------------------------
echo.
echo    ##########################     Script-paghettizado por: Samuel Jimenez Motos
echo    # SELECCIONA UNA OPCIÓN: #                                         (0.0.1.1)
echo    ##########################
echo.
echo  1 - Realizar una instalación !sistema%num_so%_variante1_nombre!.
echo      !sistema%num_so%_variante1_descripcion!
echo.
echo  2 - Realizar una instalación !sistema%num_so%_variante2_nombre!.
echo      !sistema%num_so%_variante2_descripcion!
echo.
if "!sistema%num_so%_variantes!" GEQ "3" echo  3 - Realizar una instalación !sistema%num_so%_variante3_nombre!. & echo      !sistema%num_so%_variante3_descripcion! & echo.
if "!sistema%num_so%_variantes!" GEQ "4" echo  4 - Realizar una instalación !sistema%num_so%_variante4_nombre!. & echo      !sistema%num_so%_variante4_descripcion! &echo.
if "%mostrar_id_personalizado%"=="1" echo. & echo  O - ★ Especificar un id/ticket de imagen personalizada.
if "%ajustessecretillos%"=="1" echo  X - ★ Ajustes secretos.
echo.
echo  D - Escoger otro disco como target (actualmente seleccionado el disco: %disco%).
if "%cantidad_de_sistemas_operativos%" GEQ "2" echo  V - Escoger otra versión (actual: !sistema%num_so%_nombre!).
echo  R - Reiniciar.
echo.
set /p num_var="▣ Escoge una opción. Ahora, pulsa el número y apreta la tecla *Enter*: "
if "%num_var%"=="1" goto formateo_readytoflyonazipline
if "%num_var%"=="2" goto formateo_readytoflyonazipline
if "%num_var%"=="3" goto formateo_readytoflyonazipline
if "%num_var%"=="4" goto formateo_readytoflyonazipline
if /I "%num_var%"=="D" goto pillodisco
if /I "%num_var%"=="V" if "%cantidad_de_sistemas_operativos%" GEQ "2" goto menu
if /I "%num_var%"=="M" if "%cantidad_de_sistemas_operativos%" GEQ "2" goto menu
if /I "%num_var%"=="R" goto reiniciar
if /I "%num_var%"=="O" if "%ajustessecretillos%"=="1" goto menu_imagen_personalizada
if /I "%num_var%"=="X" if "%ajustessecretillos%"=="1" goto ajustessecretillos_menu
if "%num_var%"=="betyouneverseen" set "ajustessecretillos=1" & goto menu_sistema_escogido_contiene_variantes
goto menu_sistema_escogido_contiene_variantes

:toquecito_final_a_la_inyeccion_de_nombre_de_host
if not "%nombre_host%"=="" goto formateo_readytoflyonazipline
if "!sistema%num_so%_variante%num_var%_inyectar_nombre_de_host!"=="0" goto formateo_readytoflyonazipline
if "%nombre_host_errado%"=="0" goto formateo_readytoflyonazipline
goto corregir_nombre_de_host


:corregir_nombre_de_host
title .WIM Manager - ERROR - Nombre de host incorrecto.
set "se_esta_intentando_corregir_el_nombre_de_host=1"
set "lineas=20"
if "%nombre_host_errado%" EQU "3" set /a lineas+=1
mode con:cols=81 lines=%lineas%
echo            _
echo           / \                                                        /¨¨¨¨\
echo          / ^| \        /¨¨¨¨¨  /¨¨¨¨¨\  /¨¨¨¨¨\  /¨¨¨¨¨\  /¨¨¨¨¨\     \    ^|
echo         /  ^|  \       ^|       ^|     ^|  ^|     ^|  ^|     ^|  ^|     ^|      \   \
echo        /   ^|   \      ^|———    ^|/————/  ^|/————/  ^|     ^|  ^|/————/       \   \
echo       /    ^|    \     ^|       ^| ¨¨\    ^| ¨¨\    ^|     ^|  ^| ¨¨\          \___\
echo      /           \    \_____  ^|    ¨\  ^|    ¨\  \_____/  ^|    ¨\         ^|¨¨^|
echo     /      o      \                                                       ¨¨
echo    /               \   ^> Y de los gordos, además: la inyección del nombre de host
echo    ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨     está activada, pero este valor contiene un error en el
echo                          archivo "whitelist.txt"
echo.
echo  ------------------------------------------------------------------------------- 
echo.
echo.
echo   ...y este es el error detectado:
if "%nombre_host_errado%" EQU "1" echo       El campo está vacío. Totalmente vacío.
if "%nombre_host_errado%" EQU "2" echo       El nombre excede los 15 caracteres.
if "%nombre_host_errado%" EQU "3" echo       El nombre sólo puede contener caracteres 
if "%nombre_host_errado%" EQU "3" echo       de la A a la Z, números y/o guiones "-".
echo.
echo.
set /p nombre_host=" ➤  Escribe un nombre de host válido EN MAYÚSCULAS y apreta INTRO: "
goto comprobacion_del_nombre_de_host_para_inyeccion


:formateo_readytoflyonazipline
set "op="
set "lineas=17"
if "!sistema%num_so%_variante%num_var%_omitir_imagen_efi!" EQU "1" set /a lineas+=2
if "!sistema%num_so%_variante%num_var%_omitir_imagen_winre!" EQU "1" set /a lineas+=2
if "!sistema%num_so%_variante%num_var%_omitir_actualizar_bcd!" EQU "1" set /a lineas+=2
mode con:cols=81 lines=%lineas%
cls
title .WIM Manager - Breve resumen previo al formateo.
echo.
echo  ------------------------------------------------------------------------------- 
echo         Estás a punto de formatear. ¿La información de abajo es correcta?
echo  ------------------------------------------------------------------------------- 
echo.
echo         Quieres instalar:
echo             !sistema%num_so%_nombre!
echo.
echo         Usando la variante:
echo             !sistema%num_so%_variante%num_var%_nombre!
echo.
echo         En el disco:
echo             %disco%
echo.
if "!sistema%num_so%_variante%num_var%_omitir_imagen_efi!" EQU "1" echo         (i) La config. actual omite la imagen "EFI".
if "!sistema%num_so%_variante%num_var%_omitir_imagen_efi!" EQU "1" echo.
if "!sistema%num_so%_variante%num_var%_omitir_imagen_winre!" EQU "1" echo         (i) La config. actual omite la imagen "WinRE"
if "!sistema%num_so%_variante%num_var%_omitir_imagen_winre!" EQU "1" echo.
if "!sistema%num_so%_variante%num_var%_omitir_actualizar_bcd!" EQU "1" echo         (i) La config. actual omite la actualización de las entradas del BCD.
if "!sistema%num_so%_variante%num_var%_omitir_actualizar_bcd!" EQU "1" echo.
echo.
if "%instalacion_desatendida%"=="1" (
	if "%numero_de_sistema_preseleccionado%" GEQ "1" (
		if "%numero_de_variante_de_sistema_preseleccionada%" GEQ "1" (
			if "%omitir_seleccion_manual_de_disco%"=="1" (
				if defined numero_de_disco_preseleccionado (
					goto formateo_readytoflyonazipline_go
				)
			)
		)
	)
)
set /p op=" ➤  Repito la pregunta, ¿es correcto? Responde SÍ o NO, y apreta INTRO: "
echo %op%| findstr /I "SI SÍ" >nul && goto formateo_readytoflyonazipline_go
echo %op%| findstr /I "NO" >nul && goto formateo_readytoflyonazipline_cancelado
goto formateo_readytoflyonazipline

:formateo_readytoflyonazipline_cancelado
set "op="
set "num_so="
set "num_var="
mode con:cols=81 lines=14
cls
title .WIM Manager - Cancelando formateo...
echo.
echo ---------------------------------------------------------------------------------
echo                                Formateo cancelado.
echo ---------------------------------------------------------------------------------
echo.
echo.
echo.
echo.
echo                            Volviendo al menú principal
echo.
echo.
echo.
echo.
timeout /t 1 >nul
cls
title .WIM Manager - Cancelando formateo...
echo.
echo ---------------------------------------------------------------------------------
echo                                Formateo cancelado.
echo ---------------------------------------------------------------------------------
echo.
echo.
echo.
echo.
echo                            Volviendo al menú principal.
echo.
echo.
echo.
echo.
timeout /t 1 >nul
cls
title .WIM Manager - Cancelando formateo...
echo.
echo ---------------------------------------------------------------------------------
echo                                Formateo cancelado.
echo ---------------------------------------------------------------------------------
echo.
echo.
echo.
echo.
echo                           Volviendo al menú principal..
echo.
echo.
echo.
echo.
timeout /t 1 >nul
cls
title .WIM Manager - Cancelando formateo...
echo.
echo ---------------------------------------------------------------------------------
echo                                Formateo cancelado.
echo ---------------------------------------------------------------------------------
echo.
echo.
echo.
echo.
echo                           Volviendo al menú principal...
echo.
echo.
echo.
echo.
timeout /t 1 >nul
cls
title .WIM Manager - Cancelando formateo...
echo.
echo ---------------------------------------------------------------------------------
echo                                Formateo cancelado.
echo ---------------------------------------------------------------------------------
echo.
echo.
echo.
echo.
echo                          Volviendo al menú principal....
echo.
echo.
echo.
echo.
timeout /t 1 >nul
cls
title .WIM Manager - Cancelando formateo...
echo.
echo ---------------------------------------------------------------------------------
echo                                Formateo cancelado.
echo ---------------------------------------------------------------------------------
echo.
echo.
echo.
echo.
echo                          Volviendo al menú principal.....
echo.
echo.
echo.
echo.
timeout /t 1 >nul
goto menu


:formateo_readytoflyonazipline_go
mode con:cols=81 lines=14
set "progreso_total=6"
if "!sistema%num_so%_variante%num_var%_omitir_imagen_efi!"=="1" set /a progreso_total-=2
if "!sistema%num_so%_variante%num_var%_omitir_imagen_winre!"=="1" set /a progreso_total-=1
if "!sistema%num_so%_variante%num_var%_omitir_actualizar_bcd!"=="1" set /a progreso_total-=1
if "!sistema%num_so%_variante%num_var%_inyectar_nombre_de_host!"=="1" set /a progreso_total+=1
if "!sistema%num_so%_variante%num_var%_inyectar_unattend-xml!"=="1" set /a progreso_total+=1
if "!sistema%num_so%_variante%num_var%_inyectar_ajustes_de_UEFI!"=="1" set /a progreso_total+=1
set "progreso_actual=1"
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Ejecutando scripts de diskpart...
echo ---------------------------------------------------------------------------------
echo.
echo   ...
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco0.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco1.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco2.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco3.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco4.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco5.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco6.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco7.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco8.txt >nul
diskpart /s %unidad_de_activos%\_archivos_comunes\diskpart\desmontar_disco9.txt >nul
diskpart /s %unidad_de_activos%\%ticket_id_actual%\diskpart\disco%disco%\!sistema%num_so%_variante%num_var%_script_de_diskpart! >nul


if "!sistema%num_so%_variante%num_var%_omitir_imagen_efi!"=="1" goto salto_a_aplicacion_de_img_winre_para_omitir_imagen_efi
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Aplicando imagen "!sistema%num_so%_archivo_efi!" en la partición Z: ...
echo ---------------------------------------------------------------------------------
DISM /Apply-Image /ImageFile:%unidad_de_activos%\%ticket_id_actual%\!sistema%num_so%_archivo_efi! /Index:1 /ApplyDir:Z:\ %ea_arg% %checkintegrity_arg%


:salto_a_aplicacion_de_img_winre_para_omitir_imagen_efi
if "!sistema%num_so%_variante%num_var%_omitir_imagen_winre!"=="1" goto salto_a_aplicacion_de_actualizacion_bcd_para_omitir_imagen_winre
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Aplicando imagen "!sistema%num_so%_archivo_winre!" en la partición R: ...
echo ---------------------------------------------------------------------------------
DISM /Apply-Image /ImageFile:%unidad_de_activos%\%ticket_id_actual%\!sistema%num_so%_archivo_winre! /Index:1 /ApplyDir:R:\ %checkintegrity_arg%


:salto_a_aplicacion_de_actualizacion_bcd_para_omitir_imagen_winre
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Aplicando imagen "!sistema%num_so%_archivo_windows!" en la partición C: ...
echo ---------------------------------------------------------------------------------
DISM /Apply-Image /ImageFile:%unidad_de_activos%\%ticket_id_actual%\!sistema%num_so%_archivo_windows! /Index:!sistema%num_so%_variante%num_var%_indice_de_imagen! /ApplyDir:C:\ %ea_arg% %compact_arg% %checkintegrity_arg%

if "!sistema%num_so%_variante%num_var%_omitir_actualizar_bcd!"=="1" goto salto_a_aplicacion_de_actualizacion_bcd_para_omitir_actualizacion_del_bcd
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Actualizando entradas del almacén BCD ...
echo ---------------------------------------------------------------------------------
echo.
timeout /t 1 >nul
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {memdiag} device partition=Z:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_winre!} device "ramdisk=[R:]\Recovery\WindowsRE\Winre.wim,{!sistema%num_so%_variante%num_var%_bcd_uuid_winre_boot-sdi!}"
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_winre!} osdevice "ramdisk=[R:]\Recovery\WindowsRE\Winre.wim,{!sistema%num_so%_variante%num_var%_bcd_uuid_winre_boot-sdi!}"
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_winre_boot-sdi!} ramdisksdidevice partition=R:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_hibernacion!} device partition=C:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_hibernacion!} filedevice partition=C:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_hibernacion!} "custom:21000026" partition=C:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_windows!} device partition=C:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_windows!} osdevice partition=C:
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_windows!} description "!sistema%num_so%_variante%num_var%_bcd_descripcion_windows!" 
bcdedit /store Z:\EFI\Microsoft\Boot\BCD /set {!sistema%num_so%_variante%num_var%_bcd_uuid_windows!} resumeobject {!sistema%num_so%_variante%num_var%_bcd_uuid_hibernacion!}
timeout /t 1 >nul


:salto_a_inyeccion_del_nombre_de_host_para_omitir_actualizacion_del_bcd
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Inyectando nombre de host ...
echo ---------------------------------------------------------------------------------
echo.
timeout /t 1 >nul
reg load HKLM\TEMPORAL_WM C:\Windows\System32\config\SYSTEM
reg add "HKLM\TEMPORAL_WM\ControlSet001\Control\ComputerName\ComputerName" /v "ComputerName" /t REG_SZ /d "%nombre_host%" /f
reg add "HKLM\TEMPORAL_WM\ControlSet001\Services\Tcpip\Parameters" /v "Hostname" /t REG_SZ /d "%nombre_host%" /f
reg add "HKLM\TEMPORAL_WM\ControlSet001\Services\Tcpip\Parameters" /v "NV Hostname" /t REG_SZ /d "%nombre_host%" /f
reg unload HKLM\TEMPORAL_WM
timeout /t 1 >nul


:salto_a_inyeccion_del_unattend-xml_para_omitir_inyeccion_del_nombre_de_host
if "!sistema%num_so%_variante%num_var%_inyectar_unattend-xml!"=="0" goto salto_a_inyeccion_de_ajustes_de_UEFI_para_omitir_inyeccion_del_unattend-xml
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Inyectando unattend.xml ...
echo ---------------------------------------------------------------------------------
DISM /Image:C:\ /Apply-Unattend:%unidad_de_activos%\%ticket_id_actual%\!sistema%num_so%_variante%num_var%_inyectar_unattend-xml_nombre_real!


:salto_a_inyeccion_de_ajustes_de_UEFI_para_omitir_inyeccion_del_unattend-xml
if "!sistema%num_so%_variante%num_var%_inyectar_ajustes_de_UEFI!"=="0" goto finalizando
set /a progreso_actual+=1
cls
title .WIM Manager - TRABAJANDO... (%progreso_actual%/%progreso_total%)
echo.
echo ---------------------------------------------------------------------------------
echo  (%progreso_actual%/%progreso_total%) Inyectando ajustes de UEFI (!sistema%num_so%_variante%num_var%_inyectar_ajustes_de_UEFI_nombre_real_de_nvram-txt!)...
echo ---------------------------------------------------------------------------------
echo.
%unidad_de_activos%\_SCEWIN\SCEWIN_64.exe /i /s !sistema%num_so%_variante%num_var%_inyectar_ajustes_de_UEFI_nombre_real_de_nvram-txt!
goto finalizando


:finalizando
if "%instalacion_desatendida%"=="1" (
	if "%numero_de_sistema_preseleccionado%" GEQ "1" (
		if "%numero_de_variante_de_sistema_preseleccionada%" GEQ "1" (
			if "%omitir_seleccion_manual_de_disco%"=="1" (
				if defined numero_de_disco_preseleccionado (
					if "%instalacion_desatendida_reiniciar_automaticamente_al_finalizar%"=="1" (
						goto menu_terminado_desatendido
					)
				)
			)
		)
	)
)
goto menu_terminado


:cmd
mode con:cols=100 lines=45
cls
title .WIM Manager - CMD
echo.
echo.
echo             _________________________        Recuerda escribir:
echo            ^| CMD.EXE          _ [] X ^|
echo            ^|¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨^|          \\  /¨¨¨¨¨  \   /¨ /¨¨¨¨¨\ /¨¨¨¨¨\  //
echo            ^|  /¨¨¨\   \              ^|              ^|        \ /      ^|       ^|
echo            ^| ^|      ·  \    \        ^|              ^|---      X       ^|       ^|
echo            ^| ^|      ·   \   /        ^|              ^|        / \      ^|       ^|
echo            ^|  \___/      \     _____ ^|              \_____ _/   \  \_____/    ^|
echo            ^|                         ^|
echo            ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨                        ...para salir sin reiniciar.
cmd.exe
goto %ultima_posicion%


:reiniciar
net use A: /delete /y >nul
wpeutil reboot
goto menu


:menu_terminado
set "lineas=22"
mode con:cols=81 lines=%lineas%
if "%ajustessecretillos%"=="1" set /a progreso_total+=2
title [COMPLETADO] .WIM Manager - COMPLETADO - Preparado para reiniciar.
cls
echo ---------------------------------------------------------------------------------
echo                _
echo               //                                                        /¨¨¨¨\
echo              //  /¨¨¨¨¨\ /¨¨¨¨¨\ /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\\    ^|
echo             //   ^| [ ] ^| ^|       ^| [ ] ^| ^|     ^| ^| [ ] ^| ^|     ^| ^|     ^| \   \
echo            //    ^|\___/^| ^|       ^|\___/^| ^|  --^<  ^|\___/^| ^|     ^| ^|     ^|  \   \
echo  _-       //     ^|/   \^| ^|       ^|/   \^| ^|     ^| ^|/   \^| ^|     ^| ^|     ^|   \___\
echo   \\     //      ^|     ^| \_____/ ^|     ^| ^|_____/ ^|     ^| ^|_____/ \_____/    ^|¨¨^|
echo    \\   //                                                                   ¨¨
echo     \\ //         ^> La instalación ha finalizado. Via libre para reiniciar.
echo      \//
echo ---------------------------------------------------------------------------------
echo.
echo    ##########################     Script-paghettizado por: Samuel Jimenez Motos
echo    # SELECCIONA UNA OPCIÓN: #                                         (0.0.1.1)
echo    ##########################
echo.
if "%ajustessecretillos%"=="1" echo  C - ★ Abrir un Símbolo del sistema (a.k.a cmd.exe o consola de comandos). & echo.
echo  R - Reiniciar.
echo  M - Volver al menú principal.
echo.
set /p op=" ➤  Escoge una opción escribiendo el caracter y apretando INTRO: "
if /I "%op%"=="R" goto reiniciar
if "%ajustessecretillos%"=="1" if /I "%op%"=="C" goto cmd
if /I "%op%"=="M" goto menu
goto menu_terminado

:menu_terminado_desatendido
title .WIM Manager - COMPLETADO - Reiniciando en 5 segundos...
set "lineas=11"
mode con:cols=100 lines=%lineas%
cls
echo                _
echo               //                                                                           /¨¨¨¨\
echo              //  /¨¨¨¨¨\ /¨¨¨¨¨ /¨¨¨¨¨\ ^|\   /^| ¨¨¨^|¨¨¨ ^|\    ^| /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\    \    ^|
echo             //      ^|    ^|      ^|     ^| ^| \ / ^|    ^|    ^| \   ^| ^| [ ] ^| ^|     ^| ^|     ^|     \   \
echo            //       ^|    ^|———   ^|/————/ ^|  v  ^|    ^|    ^|  \  ^| ^|\___/^| ^|     ^| ^|     ^|      \   \
echo  _-       //        ^|    ^|      ^| ¨¨\   ^|     ^|    ^|    ^|   \ ^| ^|/   \^| ^|     ^| ^|     ^|       \___\
echo   \\     //         ^|    \_____ ^|    ¨\ ^|     ^| ___^|___ ^|    \^| ^|     ^| ^|_____/ \_____/        ^|¨¨^|
echo    \\   //                                                                                      ¨¨
echo     \\ //         ^> La instalación desatendida ha finalizado. Reiniciando en 5 segundos...
echo      \//
timeout /t 1 >nul
title .WIM Manager - COMPLETADO - Reiniciando en 4 segundos...
set "lineas=11"
mode con:cols=100 lines=%lineas%
cls
echo                _
echo               //                                                                           /¨¨¨¨\
echo              //  /¨¨¨¨¨\ /¨¨¨¨¨ /¨¨¨¨¨\ ^|\   /^| ¨¨¨^|¨¨¨ ^|\    ^| /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\    \    ^|
echo             //      ^|    ^|      ^|     ^| ^| \ / ^|    ^|    ^| \   ^| ^| [ ] ^| ^|     ^| ^|     ^|     \   \
echo            //       ^|    ^|———   ^|/————/ ^|  v  ^|    ^|    ^|  \  ^| ^|\___/^| ^|     ^| ^|     ^|      \   \
echo  _-       //        ^|    ^|      ^| ¨¨\   ^|     ^|    ^|    ^|   \ ^| ^|/   \^| ^|     ^| ^|     ^|       \___\
echo   \\     //         ^|    \_____ ^|    ¨\ ^|     ^| ___^|___ ^|    \^| ^|     ^| ^|_____/ \_____/        ^|¨¨^|
echo    \\   //                                                                                      ¨¨
echo     \\ //         ^> La instalación desatendida ha finalizado. Reiniciando en 4 segundos...
echo      \//
timeout /t 1 >nul
title .WIM Manager - COMPLETADO - Reiniciando en 3 segundos...
set "lineas=11"
mode con:cols=100 lines=%lineas%
cls
echo                _
echo               //                                                                           /¨¨¨¨\
echo              //  /¨¨¨¨¨\ /¨¨¨¨¨ /¨¨¨¨¨\ ^|\   /^| ¨¨¨^|¨¨¨ ^|\    ^| /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\    \    ^|
echo             //      ^|    ^|      ^|     ^| ^| \ / ^|    ^|    ^| \   ^| ^| [ ] ^| ^|     ^| ^|     ^|     \   \
echo            //       ^|    ^|———   ^|/————/ ^|  v  ^|    ^|    ^|  \  ^| ^|\___/^| ^|     ^| ^|     ^|      \   \
echo  _-       //        ^|    ^|      ^| ¨¨\   ^|     ^|    ^|    ^|   \ ^| ^|/   \^| ^|     ^| ^|     ^|       \___\
echo   \\     //         ^|    \_____ ^|    ¨\ ^|     ^| ___^|___ ^|    \^| ^|     ^| ^|_____/ \_____/        ^|¨¨^|
echo    \\   //                                                                                      ¨¨
echo     \\ //         ^> La instalación desatendida ha finalizado. Reiniciando en 3 segundos...
echo      \//
timeout /t 1 >nul
title .WIM Manager - COMPLETADO - Reiniciando en 2 segundos...
set "lineas=11"
mode con:cols=100 lines=%lineas%
cls
echo                _
echo               //                                                                           /¨¨¨¨\
echo              //  /¨¨¨¨¨\ /¨¨¨¨¨ /¨¨¨¨¨\ ^|\   /^| ¨¨¨^|¨¨¨ ^|\    ^| /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\    \    ^|
echo             //      ^|    ^|      ^|     ^| ^| \ / ^|    ^|    ^| \   ^| ^| [ ] ^| ^|     ^| ^|     ^|     \   \
echo            //       ^|    ^|———   ^|/————/ ^|  v  ^|    ^|    ^|  \  ^| ^|\___/^| ^|     ^| ^|     ^|      \   \
echo  _-       //        ^|    ^|      ^| ¨¨\   ^|     ^|    ^|    ^|   \ ^| ^|/   \^| ^|     ^| ^|     ^|       \___\
echo   \\     //         ^|    \_____ ^|    ¨\ ^|     ^| ___^|___ ^|    \^| ^|     ^| ^|_____/ \_____/        ^|¨¨^|
echo    \\   //                                                                                      ¨¨
echo     \\ //         ^> La instalación desatendida ha finalizado. Reiniciando en 2 segundos...
echo      \//
timeout /t 1 >nul
title .WIM Manager - COMPLETADO - Reiniciando en 1 segundos...
set "lineas=11"
mode con:cols=100 lines=%lineas%
cls
echo                _
echo               //                                                                           /¨¨¨¨\
echo              //  /¨¨¨¨¨\ /¨¨¨¨¨ /¨¨¨¨¨\ ^|\   /^| ¨¨¨^|¨¨¨ ^|\    ^| /¨¨¨¨¨\ ^|¨¨¨¨¨\ /¨¨¨¨¨\    \    ^|
echo             //      ^|    ^|      ^|     ^| ^| \ / ^|    ^|    ^| \   ^| ^| [ ] ^| ^|     ^| ^|     ^|     \   \
echo            //       ^|    ^|———   ^|/————/ ^|  v  ^|    ^|    ^|  \  ^| ^|\___/^| ^|     ^| ^|     ^|      \   \
echo  _-       //        ^|    ^|      ^| ¨¨\   ^|     ^|    ^|    ^|   \ ^| ^|/   \^| ^|     ^| ^|     ^|       \___\
echo   \\     //         ^|    \_____ ^|    ¨\ ^|     ^| ___^|___ ^|    \^| ^|     ^| ^|_____/ \_____/        ^|¨¨^|
echo    \\   //                                                                                      ¨¨
echo     \\ //         ^> La instalación desatendida ha finalizado. Reiniciando en 1 segundos...
echo      \//
timeout /t 1 >nul
wpeutil reboot