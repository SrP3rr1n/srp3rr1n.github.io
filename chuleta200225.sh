#!/bin/bash

# Definiendo colores ANSI
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueLightColour="\033[1;34m"  # Azul más claro
yellowColour="\e[0;33m\033[1m"

# Función de Ctrl+C
function ctrl_c(){
    echo -e "\n\n${redColour} [!] Saliendo...${endColour}\n"
    tput cnorm && exit 1 
}

trap ctrl_c INT

# Archivo con la base de datos
archivo_comandos="iJBtvDuv571VHi9829bVHJVJIUVLK0918BKK"


# Función para actualizar archivos y subir cambios a GitHub
function actualizar_archivos(){
    echo -e "\n${yellowColour}[+] Iniciando actualización de archivos...${endColour}\n"

    # Copiar los archivos al directorio destino
    cp chuleta.sh /opt/srp3rr1n.github.io/
    cp iJBtvDuv571VHi9829bVHJVJIUVLK0918BKK /opt/srp3rr1n.github.io/

    # Ir al directorio donde está el repositorio
    cd /opt/srp3rr1n.github.io || { echo -e "${redColour}[!] Error: No se pudo acceder al directorio /opt/srp3rr1n.github.io.${endColour}"; exit 1; }

    # Configurar la identidad de Git
    git config --global user.email "ivansanchez88@aragon.unam.mx"

    # Obtener la fecha actual en formato DDMMYY
    fecha_actual=$(date +"%d%m%y")

    # Agregar cambios al repositorio
    git add .

    # Hacer commit con la fecha actual en el mensaje
    git commit -m "$fecha_actual"

    # Pedir al usuario su Token de GitHub de forma segura
    echo -ne "\n${yellowColour}[?] Ingresa tu token de GitHub: ${endColour}"
    read -s GITHUB_TOKEN
    echo ""

    # Validar si el usuario ingresó un token
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo -e "\n${redColour}[!] Error: No ingresaste un token. No se puede continuar.${endColour}\n"
        exit 1
    fi

    # Configurar autenticación con el token ingresado
    git remote set-url origin "https://SrP3rr1n:$GITHUB_TOKEN@github.com/SrP3rr1n/srp3rr1n.github.io.git"

    # Intentar hacer push a GitHub
    echo -e "\n${yellowColour}[+] Enviando cambios al repositorio remoto...${endColour}\n"
    git push -u origin 

    # Verificar si el push fue exitoso
    if [ $? -eq 0 ]; then
        echo -e "\n${greenColour}[✓] Los archivos se han actualizado correctamente en el servidor.${endColour}\n"
    else
        echo -e "\n${redColour}[!] Ocurrió un error al subir los cambios al repositorio.${endColour}\n"
    fi
}


# Función para extraer correctamente "Descripcion:", "Comando:" y "NOTA:", agregando separador y colores solo en las palabras clave
function extraer_datos(){
    awk "/$1/,/----------------------------------------------------------------/" "$archivo_comandos" | awk -v color="$blueLightColour" '
    /Descripcion:/ {if (block) print block "\n" color "----------------------------------------------------------------" "\033[0m"; split($0, a, ": "); block = color a[1] ":\033[0m " a[2]; next} 
    /Comando:/ {split($0, a, ": "); block = block "\n" color a[1] ":\033[0m " a[2]; next} 
    /NOTA:/ {split($0, a, ": "); block = block "\n" color a[1] ":\033[0m " a[2]; next} 
    /^[0-9]+/ {block = block "\n" $0} 
    END {if (block) print block "\n" color "----------------------------------------------------------------" "\033[0m"}'
}

# Función para selección interactiva con `fzf`, copiando solo lo que está después de "Comando:"
function seleccionar_y_copiar(){
    resultados=$(extraer_datos "$1")

    if [ -z "$resultados" ]; then
        echo -e "\n${redColour}[!] No se encontró información.${endColour}\n"
        exit 1
    fi

    # Mostrar los resultados en `fzf` con barra de selección rosa
    seleccion=$(echo -e "$resultados" | fzf --ansi --layout=reverse --border --color=border:#444444 --height=95% --cycle --color=pointer:#ff0080)

    # Extraer solo lo que está después de "Comando:"
    if [[ "$seleccion" == Comando:* ]]; then
        comando_copiar=$(echo "$seleccion" | sed 's/Comando: //')
    else
        comando_copiar="$seleccion"
    fi

    # Copiar la selección al portapapeles
    if [ -n "$comando_copiar" ]; then
        echo -n "$comando_copiar" | xclip -selection clipboard 2>/dev/null || echo -n "$comando_copiar" | pbcopy 2>/dev/null
        echo -e "\n${greenColour}[+] Copiado al portapapeles:${endColour}\n$comando_copiar\n"
    else
        echo -e "\n${redColour}[!] No se seleccionó ninguna opción.${endColour}\n"
    fi
}

# Función para buscar por herramienta
function searchTool(){
    ToolName="$1"
    echo -e "\n${greenColour}\e[5m[+]${endColour} Listando los comandos y técnicas de la herramienta ${blueLightColour}$ToolName${endColour}:\n"

    seleccionar_y_copiar "$ToolName"
}

# Función para buscar por protocolo
function searchProtocol(){
    ProtocolName="$1"
    echo -e "\n${greenColour}\e[5m[+]${endColour} Listando los comandos y técnicas del protocolo ${blueLightColour}$ProtocolName${endColour}:\n"

    seleccionar_y_copiar "$ProtocolName"
}

# Función para buscar por categoría
function searchCategory(){
    CategoryName="$1"
    echo -e "\n${greenColour}\e[5m[+]${endColour} Listando los comandos y técnicas de la categoría ${blueLightColour}$CategoryName${endColour}:\n"

    seleccionar_y_copiar "$CategoryName"
}

# Procesar argumentos
declare -i parameter_counter=0

while getopts "p:c:t:uh" arg; do
    case $arg in
        p) ProtocolName=$OPTARG; let parameter_counter+=1;;
        c) CategoryName=$OPTARG; let parameter_counter+=2;;
        t) ToolName=$OPTARG; let parameter_counter+=3;;
        u) let parameter_counter+=4;;  # ✅ Ahora se suma correctamente para ejecutar la función
        h) ;;  # ✅ Se corrige el error de sintaxis en la opción `-h`
    esac
done

# Ejecutar la acción correspondiente
if [ $parameter_counter -eq 1 ]; then
    searchProtocol "$ProtocolName"
elif [ $parameter_counter -eq 2 ]; then
    searchCategory "$CategoryName"
elif [ $parameter_counter -eq 3 ]; then
    searchTool "$ToolName"
elif [ $parameter_counter -eq 4 ]; then
    actualizar_archivos  # ✅ Ahora sí ejecuta la actualización correctamente
else
toilet -f ivrit 'C H U L E T A' | boxes | lolcat
   echo -e "\n${yellowColour}\e[5m[+]${endColour} Uso:"
   #echo -e "\t${purpleColour}s)${endColour} Cargar archivos"
   echo -e "\t${purpleColour}u)${endColour} Actualizar archivos"
   echo -e "\t${purpleColour}p)${endColour} Buscar por protocolo"
   echo -e "\t${purpleColour}c)${endColour} Buscar por categoria"
   echo -e "\t${purpleColour}t)${endColour} Buscar por herramienta"
   echo -e "\t${purpleColour}h)${endColour} Mostrar panel de ayuda\n"
   

   echo -e "\n${yellowColour}\e[5m[*]${endColour} Ejemplo: \n" 
   echo -e "\t chuleta.sh -p HTTP "
   echo -e "\t chuleta.sh -c \"Active Directory\""
   echo -e "\t chuleta.sh -t smbclient"
fi
