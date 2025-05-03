#!/bin/bash

# Colores ANSI
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueLightColour="\033[1;34m"
purpleColour="\e[0;35m\033[1m"
yellowColour="\e[0;33m\033[1m"

# Ctrl+C
function ctrl_c(){
    echo -e "\n\n${redColour} [!] Saliendo...${endColour}\n"
    tput cnorm && exit 1 
}
trap ctrl_c INT

archivo_comandos="iJBtvDuv571VHi9829bVHJVJIUVLK0918BKK"

function actualizar_archivos(){
    echo -e "\n${yellowColour}[+] Iniciando actualización de archivos...${endColour}\n"
    cp chuleta.sh /opt/srp3rr1n.github.io/
    cp "$archivo_comandos" /opt/srp3rr1n.github.io/
    cd /opt/srp3rr1n.github.io || { echo -e "${redColour}[!] Error: No se pudo acceder al directorio.${endColour}"; exit 1; }
    git config --global user.email "ivansanchez88@aragon.unam.mx"
    fecha_actual=$(date +"%d%m%y")
    git add .
    git commit -m "$fecha_actual"
    echo -ne "\n${yellowColour}[?] Ingresa tu token de GitHub: ${endColour}"
    read -s GITHUB_TOKEN
    echo ""
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo -e "\n${redColour}[!] No ingresaste un token. No se puede continuar.${endColour}\n"
        exit 1
    fi
    git remote set-url origin "https://SrP3rr1n:$GITHUB_TOKEN@github.com/SrP3rr1n/srp3rr1n.github.io.git"
    echo -e "\n${yellowColour}[+] Enviando cambios al repositorio remoto...${endColour}\n"
    git push -u origin 
    if [ $? -eq 0 ]; then
        echo -e "\n${greenColour}[✓] Archivos actualizados correctamente.${endColour}\n"
    else
        echo -e "\n${redColour}[!] Error al subir cambios.${endColour}\n"
    fi
}

function extraer_datos(){
    awk "/$1/,/----------------------------------------------------------------/" "$archivo_comandos" | awk -v color="" '
    /Descripcion:/ {
        if (block) print block "\\n";
        split($0, a, ": ");
        block = "📘 " a[1] ": " a[2];
        next
    }
    /Comando:/ {
        split($0, a, ": ");
        block = block "\n⚙️  " a[1] ": " a[2];
        next
    }
    /NOTA:/ {
        split($0, a, ": ");
        block = block "\n📝 " a[1] ": " a[2];
        next
    }
    /^[0-9]+/ {
        block = block "\n" $0
    }
    END {
        if (block) print block "\\n"
    }'
}

function seleccionar_y_copiar() {
    titulo="🧠 Resultados de búsqueda: $1"
    resultados=$(echo -e "$titulo\n\n$(extraer_datos \"$1\")")
    if [ -z "$resultados" ]; then
        echo -e "\n${redColour}[!] No se encontró información.${endColour}\n"
        exit 1
    fi

    seleccion=$(echo -e "$resultados" | rofi -dmenu -i -theme ~/.config/rofi/launchers/type-1/style-1.rasi)

    if [ -n "$seleccion" ]; then
        comando=$(echo "$seleccion" | awk '/⚙️  Comando:/ {sub("⚙️  Comando: ", "", $0); print $0}')
        if [ -n "$comando" ]; then
            echo -n "$comando" | xclip -selection clipboard
            notify-send "📋 Copiado" "$comando"
        else
            echo -n "$seleccion" | xclip -selection clipboard
            notify-send "📋 Copiado" "$seleccion"
        fi
    fi
}

function searchTool(){
    ToolName="$1"
    echo -e "\n${greenColour}\e[5m[+]${endColour} Comandos de herramienta ${blueLightColour}$ToolName${endColour}:\n"
    seleccionar_y_copiar "$ToolName"
}

function searchProtocol(){
    ProtocolName="$1"
    echo -e "\n${greenColour}\e[5m[+]${endColour} Comandos de protocolo ${blueLightColour}$ProtocolName${endColour}:\n"
    seleccionar_y_copiar "$ProtocolName"
}

function searchCategory(){
    CategoryName="$1"
    echo -e "\n${greenColour}\e[5m[+]${endColour} Comandos de categoría ${blueLightColour}$CategoryName${endColour}:\n"
    seleccionar_y_copiar "$CategoryName"
}

declare -i parameter_counter=0

while getopts "p:c:t:uh" arg; do
    case $arg in
        p) ProtocolName=$OPTARG; let parameter_counter+=1;;
        c) CategoryName=$OPTARG; let parameter_counter+=2;;
        t) ToolName=$OPTARG; let parameter_counter+=3;;
        u) let parameter_counter+=4;;
        h) ;;
    esac
done

if [ $parameter_counter -eq 1 ]; then
    searchProtocol "$ProtocolName"
elif [ $parameter_counter -eq 2 ]; then
    searchCategory "$CategoryName"
elif [ $parameter_counter -eq 3 ]; then
    searchTool "$ToolName"
elif [ $parameter_counter -eq 4 ]; then
    actualizar_archivos
else
    COLORS=("red" "blue" "green")
    RANDOM_COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}
    cmatrix -C "$RANDOM_COLOR" -b -s & sleep 1; kill $!
    clear
    toilet -f ivrit 'C H U L E T A' | boxes | lolcat
    echo -e "\n${yellowColour}\e[5m[+]${endColour} Uso:" 
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
