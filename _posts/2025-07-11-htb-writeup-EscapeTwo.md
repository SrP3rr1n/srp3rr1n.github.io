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
