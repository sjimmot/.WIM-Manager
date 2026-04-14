# .WIM-Manager
Utilidad script-paghettizada altamente editable para instalar Windows mediante imágenes .ESD/.WIM por red/PXE (sólo necesitas TFTP, SMB y DHCP).
Es capaz de diferenciar entre equipos (UUID de la placa) por "whitelist", ofreciendo en función de esto diferentes imágenes y opciones de postinstalación.
Hecho con amor y apto para scriptkiddies como yo.

# INFORMACIÓN IMPORTANTE: ANTES DE EMPEZAR...
En este repositorio, y por motivos obvios, no se incluyen los archivos "boot.wim", "boot.sdi", así como los ejecutables "findstr.exe" y "timeout.exe". También debes preparar el archivo "boot.wim" antes de poderlo utilizar mediante unos scripts automatizados que requieren hacerlo en Windows (pues se usa DISM).

Los archivos "findstr.exe" y "timeout.exe" se encuentran en cualquier instalación de Windows o bien dentro del archivo install.esd/install.wim (ábrelo con 7-zip) dentro de "\Windows\System32\".
Estos deben introducirse en "\Espacio de trabajo para el boot.wim\Contenido a inyectar\windows\system32\".

Los archivos "boot.wim" y "boot.sdi" se encuentran en "sources\" y "boot\" de cualquier medio de instalación de Windows 10 u 11.
Mientras que el archivo "boot.sdi" puede ir directamente a la carpeta raíz-compartida del servidor TFTP, el archivo "boot.wim" antes debe ser preparado.
Para preparar el "boot.wim", debes colocarlo en "\Espacio de trabajo para el boot.wim\" y, como mínimo, añadir unos drivers ethernet en la carpeta "\Espacio de trabajo para el boot.wim\Drivers a inyectar", y ejecutar los 5 script ".BAT" en el orden establecido según el nombre de archivo que tienen establecido.
Tras esto, debes mover el archivo a la carpeta raíz-compartida del servidor TFTP.

Tanto el archivo "boot.ipxe" en la carpeta raíz-compartida del servidor TFTP, como el archivo "Terraformador.bat" en \Espacio de trabajo para el boot.wim\Contenido a inyectar\" necesitan ser editados para incluir la IP del servidor TFTP (boot.ipxe), así como la IP del servidor SMB, la ruta del recurso compartido, el usuario y su contraseña (Terraformador.bat).

Por último, debes especificar en el servidor DHCP cuál es el servidor TFTP y qué archivo debe ofrecer en base a la arquitectura del equipo cliente (y si tiene o no cargado IPXE).
Por ejemplo, en mi caso (dnsmasq en un router Xiaomi ejecutando XiaoQiang), tuve que editar el archivo "/etc/dnsmasq.conf" e incluir las siguientes líneas al final:

`dhcp-match=set:bios,option:client-arch,0`
`dhcp-match=set:uefi7,option:client-arch,7`
`dhcp-match=set:uefi9,option:client-arch,9`
`dhcp-userclass=set:ipxe,iPXE`

`dhcp-boot=tag:bios,tag:!ipxe,undionly.kpxe,192.168.1.250,192.168.1.250`
`dhcp-boot=tag:uefi7,tag:!ipxe,snponly-shim.efi,192.168.1.250,192.168.1.250`
`dhcp-boot=tag:uefi9,tag:!ipxe,snponly-shim.efi,192.168.1.250,192.168.1.250`

`dhcp-boot=tag:ipxe,boot.ipxe,192.168.1.250,192.168.1.250`

Se recomienda el uso de "snponly-shim.efi", el cual carga "snponly.efi" aprovechando así los drivers ethernet incluidos en la ROM/UEFI para el proceso temprano de arranque.

# Licencias y uso de software de terceros.
Este repositorio utiliza componentes de terceros para facilitar el arranque por red (iPXE, WimBoot) así como permitir su uso con Secure Boot (shim del repositorio de iPXE).
De acuerdo con las licencias de software libre (GPL y BSD), se detalla a continuación la información legal y la ubicación de los materiales correspondientes.

## 1. iPXE (ipxe.efi y snponly.efi).
- **Licencia:** GNU General Public License versión 2 (GPLv2).
- **Origen:** [https://github.com/ipxe/ipxe](https://github.com/ipxe/ipxe)
- **Cumplimiento:** el código fuente completo y sin modificaciones utilizado para generar el binario incluido se encuentra en este repositorio en: `Otros/src/ipxe-2.0.0.tar.gz`.

## 2. WimBoot (wimboot).
- **Licencia:** GNU General Public License versión 2 (GPLv2).
- **Origen:** [https://github.com/ipxe/wimboot](https://github.com/ipxe/wimboot)
- **Cumplimiento:** el código fuente completo y sin modificaciones utilizado para generar el binario incluido se encuentra en este repositorio en: `Otros/src/wimboot-2.9.0.tar.gz`.

## 3. Shim (shimx64.efi).
- **Licencia:** BSD 2-Clause License.
- **Origen:** [https://github.com/ipxe/shim](https://github.com/ipxe/shim)
- **Cumplimiento:** Aunque la licencia BSD es permisiva, en favor de la transparencia y la reproducibilidad, se incluye el código fuente correspondiente en: `Otros/src/shim-ipxe-16.1.tar.gz`.
