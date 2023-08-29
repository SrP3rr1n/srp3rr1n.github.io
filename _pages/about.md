---
layout: splash
title: "Whoami"
permalink: /about/
date: 2019-02-15
---
<html>
 <link rel="shortcut icon" type="image/x-icon" href="/assets/images/candado.png" />
<style>
@import "compass/css3";

@import url(https://fonts.googleapis.com/css?family=Share+Tech+Mono);



#.info {
  color: white;
  font:1em/1 sans-serif;
  text-align: center;
}

#.info a{
  color: white;
}

svg{
  width: 600px;
  height: 120px;
  display: block;
  position: relative;
  overflow: hidden; 
  margin: 0 auto;
 background:#050D1A; 
}

@media (max-width: 767.5px) {
svg{
  width: 300px;
  height: 60px;
  display: block;
  position: relative;
  overflow: hidden;
  margin: 0 auto;
 background:#050D1A;

}
}

@media (max-width: 575.5px){

svg{
  width: 300px;
  height: 60px;
  display: block;
  position: relative;
  overflow: hidden;
  margin: 0 auto;
 background:#050D1A;
 
}
}

}
</style>
<body>

<svg version="1.1" id="Ebene_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="600px" height="100px" viewBox="0 0 600 100">
<style type="text/css">

<![CDATA[

	text {
		filter: url(#filter);
		fill: white;
    	font-family: 'Share Tech Mono', sans-serif;
    	font-size: 100px;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
     		}
]]>
</style>
	<defs>

		<filter id="filter">
		    <feFlood flood-color="#050D1A" result="black" />
		    <feFlood flood-color="red" result="flood1" />
		    <feFlood flood-color="limegreen" result="flood2" />
			<feOffset in="SourceGraphic" dx="3" dy="0" result="off1a"/>
			<feOffset in="SourceGraphic" dx="2" dy="0" result="off1b"/>
			<feOffset in="SourceGraphic" dx="-3" dy="0" result="off2a"/>
			<feOffset in="SourceGraphic" dx="-2" dy="0" result="off2b"/>
		    <feComposite in="flood1" in2="off1a" operator="in"  result="comp1" />
		    <feComposite in="flood2" in2="off2a" operator="in" result="comp2" />

 		  	<feMerge x="0" width="100%" result="merge1">
				<feMergeNode in = "black" />
				<feMergeNode in = "comp1" />
				<feMergeNode in = "off1b" />

				<animate 
					attributeName="y" 
		    		id = "y"
		    		dur ="4s"
		    		
		    		values = '104px; 104px; 30px; 105px; 30px; 2px; 2px; 50px; 40px; 105px; 105px; 20px; 6ßpx; 40px; 104px; 40px; 70px; 10px; 30px; 104px; 102px'

		    		keyTimes = '0; 0.362; 0.368; 0.421; 0.440; 0.477; 0.518; 0.564; 0.593; 0.613; 0.644; 0.693; 0.721; 0.736; 0.772; 0.818; 0.844; 0.894; 0.925; 0.939; 1'

		    		repeatCount = "indefinite" />
 
				<animate attributeName="height" 
		    		id = "h" 
		    		dur ="4s"
		    		
		    		values = '10px; 0px; 10px; 30px; 50px; 0px; 10px; 0px; 0px; 0px; 10px; 50px; 40px; 0px; 0px; 0px; 40px; 30px; 10px; 0px; 50px'

		    		keyTimes = '0; 0.362; 0.368; 0.421; 0.440; 0.477; 0.518; 0.564; 0.593; 0.613; 0.644; 0.693; 0.721; 0.736; 0.772; 0.818; 0.844; 0.894; 0.925; 0.939; 1'

		    		repeatCount = "indefinite" />
		    </feMerge>
 			

 			<feMerge x="0" width="100%" y="60px" height="65px" result="merge2">
				<feMergeNode in = "black" />
				<feMergeNode in = "comp2" />
				<feMergeNode in = "off2b" />

				<animate attributeName="y" 
		    		id = "y"
		    		dur ="4s"
		    		values = '103px; 104px; 69px; 53px; 42px; 104px; 78px; 89px; 96px; 100px; 67px; 50px; 96px; 66px; 88px; 42px; 13px; 100px; 100px; 104px;' 

		    		keyTimes = '0; 0.055; 0.100; 0.125; 0.159; 0.182; 0.202; 0.236; 0.268; 0.326; 0.357; 0.400; 0.408; 0.461; 0.493; 0.513; 0.548; 0.577; 0.613; 1'

 		    		repeatCount = "indefinite" />
 
				<animate attributeName="height" 
		    		id = "h"
		    		dur = "4s"
					
					values = '0px; 0px; 0px; 16px; 16px; 12px; 12px; 0px; 0px; 5px; 10px; 22px; 33px; 11px; 0px; 0px; 10px'

		    		keyTimes = '0; 0.055; 0.100; 0.125; 0.159; 0.182; 0.202; 0.236; 0.268; 0.326; 0.357; 0.400; 0.408; 0.461; 0.493; 0.513;  1'
		    		 
		    		repeatCount = "indefinite" />
		    </feMerge>
			
		 	<feMerge>
 				<feMergeNode in="SourceGraphic" />	

				<feMergeNode in="merge1" /> 
 			<feMergeNode in="merge2" />

		    </feMerge>
	    </filter>

	</defs>

<g>
	<text x="0" y="100">$~: whoami</text>
</g>
</svg>
</body>
</html>


<br>

Soy un entusiasta en el área de la seguridad de la información, actualmente trabajo como analista de ciberseguridad en realizando actividades relacionadas a la seguridad ofensiva y pruebas de penetración. Interesado en consolidarme y aumentar mis conocimientos y técnicas sobre la seguridad ofensiva y el pentesting, .

## Diplomados

Actualmente dispongo de los siguientes diplomados:

- Diplomado en Seguridad Informática - Universidad Nacional Autónoma de México

## Certificaciones
Actualmente dispongo de las siguientes certificaciones:

- eJPT (eLearnSecurity Junior Penetration Tester)


## Hack The Box Pro Labs
Actualmente dispongo de los siguientes Pro Labs de Hack The Box:
- Dante
- Genesis

## Cursos
- Taller de Pruebas de Penetración (Pentest)
- Taller de Aplicaciones Criptográficas
- Taller de Networking Yolixtli (Introducción a las redes, Switch, Routing, VoIP)

## Experiencia
- Miembro del Laboratorio de Seguridad Informática de la FES Aragón, UNAM
- Consultor de Seguridad Informática en "Industrial Control & Information Security” (ICI SECURITY)
- Analista de Ciberseguridad en Deloitte


