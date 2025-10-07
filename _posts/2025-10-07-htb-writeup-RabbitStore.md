---
layout: single
title: TryHackMe - Rabbit Store
excerpt: "Rabbit Store es una máquina media de Try Hack Me donde se explota una api para obtener acceso privilegiado a un sistema donde pueden cargarse archivos, apartir de aqui se explota un SSRF para obtener un endpoint de la api en especifico, posteriormente se explota un SSTI que permite la ejecución remota de comandos, para la escalación de privilegios se comunica con rabbitqm para obtener la ocntraseña del root"
date: 2025-10-07
classes: wide
header:
  teaser: /assets/images/thm-writeup-RabbitStore/rabbit.png
  teaser_home_page: true
  icon: /assets/images/thm.png 
categories:
  - TryHackMe
  - Web Pentesting
tags:  
  - SSRF
  - API
  - SSTI 
  - Rabbitmq
  - epmd 

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
    background-image: url("/assets/images/thm-writeup-RabbitStore/rabbit.png");
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
    background-image: url("/assets/images/thm-writeup-RabbitStore/rabbit.png");
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

`Rabbit Store` Es una máquina maquina media de Try Hack Me donde se explota una api para obtener acceso privilegiado a un sistema donde pueden cargarse archivos, apartir de aqui se explota un SSRF para obtener un endpoint de la api en especifico, posteriormente se explota un SSTI que permite la ejecución remota de comandos, para la escalación de privilegios se comunica con rabbitqm para obtener la ocntraseña del root. 

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

```bash
Nmap scan report for 10.201.90.204
Host is up, received user-set (0.23s latency).
Scanned at 2025-09-01 18:11:59 EDT for 145s

PORT      STATE SERVICE REASON         VERSION
22/tcp    open  ssh     syn-ack ttl 61 OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
80/tcp    open  http    syn-ack ttl 61 Apache httpd 2.4.52
4369/tcp  open  epmd    syn-ack ttl 61 Erlang Port Mapper Daemon
25672/tcp open  unknown syn-ack ttl 61
Service Info: Host: 127.0.1.1; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Realicé otro escaneo con **Nmap** utilizando la opción `-sVC` para obtener información detallada de los servicios detectados, y logré identificar un dominio `cloudsite.thm` 

```bash
Nmap scan report for 10.201.90.204
Host is up, received user-set (0.24s latency).
Scanned at 2025-09-01 18:15:35 EDT for 151s

PORT      STATE SERVICE REASON         VERSION
22/tcp    open  ssh     syn-ack ttl 61 OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 3f:da:55:0b:b3:a9:3b:09:5f:b1:db:53:5e:0b:ef:e2 (ECDSA)
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBXuyWp8m+y9taS8DGHe95YNOsKZ1/LCOjNlkzNjrnqGS1sZuQV7XQT9WbK/yWAgxZNtBHdnUT6uSEZPbfEUjUw=
|   256 b7:d3:2e:a7:08:91:66:6b:30:d2:0c:f7:90:cf:9a:f4 (ED25519)
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcGp6ztslpYtKYBl8IrBPBbvf3doadnd5CBsO+HFg5M
80/tcp    open  http    syn-ack ttl 61 Apache httpd 2.4.52
|_http-title: Did not follow redirect to http://cloudsite.thm/
|_http-server-header: Apache/2.4.52 (Ubuntu)
| http-methods: 
|_  Supported Methods: GET HEAD POST OPTIONS
4369/tcp  open  epmd    syn-ack ttl 61 Erlang Port Mapper Daemon
| epmd-info: 
|   epmd_port: 4369
|   nodes: 
|_    rabbit: 25672
25672/tcp open  unknown syn-ack ttl 61
Service Info: Host: 127.0.1.1; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
## Enumeración WEB 

El sitio web de la máquina es el siguiente:

![](/assets/images/thm-writeup-RabbitStore/web.png)

Lo primero que realicé fue revisar las tecnologías implementadas con Wappalyzer.

![](/assets/images/thm-writeup-RabbitStore/wa.png)

Realicé un escaneo de archivos y directorios, pero no encontré ninguno interesante.

```bash
┌──(root㉿kali)-[/home/kali]
└─# gobuster dir -u http://cloudsite.thm/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,txt,html
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://cloudsite.thm/
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Extensions:              php,txt,html
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/index.html           (Status: 200) [Size: 18451]
/.html                (Status: 403) [Size: 278]
/blog.html            (Status: 200) [Size: 10939]
/services.html        (Status: 200) [Size: 9358]
/contact_us.html      (Status: 200) [Size: 9914]
/assets               (Status: 301) [Size: 315] [--> http://cloudsite.thm/assets/]
/about_us.html        (Status: 200) [Size: 9992]
/javascript           (Status: 301) [Size: 319] [--> http://cloudsite.thm/javascript/]
```
Al acceder al login encontré otro subdominio, así que lo agregué a /etc/hosts para que el inicio de sesión cargara correctamente.

![](/assets/images/thm-writeup-RabbitStore/burp.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# cat /etc/hosts                                                                                         
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.201.6.196   cloudsite.thm storage.cloudsite.thm
```
![](/assets/images/thm-writeup-RabbitStore/login.png)

Intente ingresar con credenciales por defecto pero no tuve éxito, así que cree una cuenta y pude ingresar al portal, si embargo, me encontré con un mensaje indicando este servicio es solo para usuarios internos de la organización  y sus clientes, si es cliente solicite al administrador que active su suscripción.

![](/assets/images/thm-writeup-RabbitStore/mensaje.png)

Al capturar la petición de autenticación, observé que el sitio usa una API y que, tras autenticarse, devuelve un JSON Web Token (JWT) para el usuario.

![](/assets/images/thm-writeup-RabbitStore/auth.png)

Al analizar el token en jwt.io, observé que incluye el atributo suscripción con el valor inactivo.

![](/assets/images/thm-writeup-RabbitStore/jwt.png)

En ese punto capturé la petición de registro, añadiendo el atributo suscripción con valor activo.

![](/assets/images/thm-writeup-RabbitStore/subs.png)

Esto me permitió ingresar al dashboard con la suscripción activada, donde hay una funcionalidad para la carga de archivos.

![](/assets/images/thm-writeup-RabbitStore/up.png)

Realicé otro escaneo de directorios a partir de la ruta api para encontrar otros endpoints.

```bash
┌──(root㉿kali)-[/home/kali]
└─# gobuster dir -u http://storage.cloudsite.thm/api/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt       
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://storage.cloudsite.thm/api/
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/login                (Status: 405) [Size: 36]
/register             (Status: 405) [Size: 36]
/docs                 (Status: 403) [Size: 27]
/uploads              (Status: 401) [Size: 32]
/Login                (Status: 405) [Size: 36]
/Docs                 (Status: 403) [Size: 27]
/Register             (Status: 405) [Size: 36]
```
Encontré algunos endpoints; sin embargo, aún no tengo acceso a ellos.

![](/assets/images/thm-writeup-RabbitStore/denied.png)

## SSRF (Server Side Request Forgery

En este punto intenté subir distintos tipos de archivo, pero no parece vulnerable. Más abajo hay otra sección para subir archivos mediante una URL.

![](/assets/images/thm-writeup-RabbitStore/url.png)

Realicé una prueba con un servidor temporal en Python, ingresando mi IP y llamando el archivo test.txt; la petición se obtuvo correctamente, lo que indica un posible SSRF (Server-Side Request Forgery).

![](/assets/images/thm-writeup-RabbitStore/test.png)

```bash
┌──(root㉿kali)-[/opt]
└─# python -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.201.51.132 - - [02/Sep/2025 02:19:31] "GET /test.txt HTTP/1.1" 200 -
```

Algo que puede realizarse mediante un SSRF es una enumeración de puertos internos del sistema, primero genere una lista con los 65535 puertos

```bash
┌──(root㉿kali)-[/home/kali]
└─# for port in {1..65535};do echo $port >> ports.txt;done
```
