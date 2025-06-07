#!/bin/bash

# COLORES
ROJO='\e[31m'
VERDE='\e[32m'
AMARILLO='\e[33m'
AZUL='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
BLANCO='\e[37m'
PARPADEO='\e[5m' # Algunos terminales no soportan esto
FIN_COLOR='\e[0m'



# Capturar la salida con Ctrl_c
ctrl_c(){
	echo -e "\nBye Bye\n"
	exit 1
}
trap ctrl_c INT

var=0 #Variable usada para diferenciar el idioma al añadir nuevas palabras
ruta_db="./data/words.db"


banner(){
	cat <<-BANNER
		▀█████████▄     ▄████████ ▀█████████▄     ▄████████  ▄█          ▄████████ ████████▄    ▄█      
		  ███    ███   ███    ███   ███    ███   ███    ███ ███         ███    ███ ███    ███  ███      
		  ███    ███   ███    ███   ███    ███   ███    █▀  ███         ███    █▀  ███    ███  ███      
		 ▄███▄▄▄██▀    ███    ███  ▄███▄▄▄██▀   ▄███▄▄▄     ███         ███        ███    ███  ███      
		▀▀███▀▀▀██▄  ▀███████████ ▀▀███▀▀▀██▄  ▀▀███▀▀▀     ███       ▀███████████ ███    ███  ███      
		  ███    ██▄   ███    ███   ███    ██▄   ███    █▄  ███                ███ ███    ███  ███      
		  ███    ███   ███    ███   ███    ███   ███    ███ ███▌    ▄    ▄█    ███ ███  ▀ ███  ███▌    ▄
		▄█████████▀    ███    █▀  ▄█████████▀    ██████████ █████▄▄██  ▄████████▀   ▀██████▀▄█ █████▄▄██
		                                                    ▀                                  ▀        	
BANNER
}

# Menú principal
menu(){
	clear
	banner
	echo -e "${AMARILLO}================================BABELSQL DICCIONARY==================================================\n\n${FIN_COLOR}"
	echo -e "${MAGENTA}1) Buscar Palabra${FIN_COLOR}"
	echo -e "${VERDE}2) Añadir y Editar Palabras${FIN_COLOR}"
	echo -e "${CYAN}3) Ver todas las palabras en inglés${FIN_COLOR}"
	echo -e "${CYAN}4) Ver todas las palabras en español${FIN_COLOR}"
	echo -e "${ROJO}5) Salir\n\n${FIN_COLOR}"
	while true; do
		read -r -p  "Qué deseas realizar:   " seleccion
		case $seleccion in
		1)  search;;
		2)  add;;
		3)   listar="ingles"
			lista_de_palabras
			;;
		4)  listar="español"
			lista_de_palabras
			;;
		5) ctrl_c;;
		*) echo "respuesta no valida";;
		esac
	done
}

lista_de_palabras(){
	clear
	sqlite3 "$ruta_db" <<-LIMIT | less -s
	.headers on
	.mode box
	.width 15 15
	select * from $listar order by lower(palabra);
	LIMIT
	menu
}

# Funcion de búsqueda

search(){
	clear
	banner
	while true; do
	echo -e "${AMARILLO}=====================================================Buscar una palabra===========================================================${FIN_COLOR}"
	echo -e "${AZUL}1) Palabra en Inglés${FIN_COLOR}"
	echo -e "${CYAN}2) Palabra en Español${FIN_COLOR}"
	echo -e "${ROJO}3) atras${FIN_COLOR}\n"
	read -rp "Selecciona:  " seleccion
	if [[ $seleccion == 3 ]]; then
		menu
	elif [[ $seleccion == 1 ]];then
		idioma="ingles"
	elif [[ $seleccion == 2 ]]; then
		idioma="español"
	else
		echo "Selección no válida"
		sleep 2
		search
	fi
	clear
	read -rp "Escribe la palabra que deseas buscar o escribe \"atras\":   " word
	comando=$(sqlite3 -header -box "$ruta_db" "select * from $idioma where lower(palabra) like lower('%$word%');")
	if [[ $word == "atras" ]];then
			menu
	elif [[ -z "$comando" ]]; then
		echo "Palabra no encontrada"
		sleep 2
		clear
	else
		sqlite3 -header -box "$ruta_db" "select * from $idioma where palabra like '%$word%';"
	fi
	done
}

# Funcion para mostrar todas las palabras 
lista(){
		 clear
			sqlite3 -header -box "$ruta_db" "select * from $idioma order by lower(palabra);"
}

delete(){
		while true;do
		clear
		banner
		echo -e "${AMARILLO}=========================================================Eliminar una Palabra======================================================${FIN_COLOR}"
		echo -e "${AZUL}1) Eliminar palabra en Inglés${FIN_COLOR}"
		echo -e "${CYAN}2) Eliminar palabra en Español${FIN_COLOR}"
		echo -e "${ROJO}3) Atrás${FIN_COLOR}"
		read -rp "Selecciona:  " delete
		if [[ $delete -eq 1 ]]; then
			idioma="ingles"
		elif [[ $delete -eq 2 ]]; then
			idioma="español"
		elif [[ $delete -eq 3 ]]; then
			menu
		else
			echo "Selección no válida"
			sleep 2
			delete
		fi
		lista
		read -rp "Escribe el nombre de la palabra que deseas eliminar,'atras' para salir:   " word
			if [[ $word == "atras" ]]; then
				delete
			fi
		verificar_existencia=$(( sqlite3 $ruta_db "SELECT 1 FROM $idioma WHERE LOWER(palabra) = LOWER('$word')") 2>&1 )
			if [[ -z $verificar_existencia ]] ; then
				echo "La palabra no existe"
				sleep 1
			elif sqlite3 "$ruta_db" "delete from $idioma where lower(palabra) = lower('$word');" ;then
				echo "Se ha eliminado correctamente"
				sleep 1
			else
				echo "Error, no se pudo eliminar la palabra"
				sleep 1
			fi 
		done
}

update(){
	while true; do
	clear
	banner
	echo -e "${AMARILLO}=========================================================Actualizar Palabra=============================================${FIN_COLOR}"
		echo -e "${AZUL}1) Actualizar palabra en Inglés${FIN_COLOR}"
		echo -e "${CYAN}2) Actualizar palabra en Español${FIN_COLOR}"
		echo -e "${ROJO}3) Atrás${FIN_COLOR}"
	read -rp "Selecciona:   " update
	if [[ $update -eq 1 ]]; then
		idioma="ingles"
		export="$idioma"
	elif [[ $update -eq 2 ]]; then
		idioma="español"
		export="$idioma"
	elif [[ $update -eq 3 ]]; then
		menu
	else
		echo "Selección no válida"
		continue
	fi
	lista
	read -rp "Escribe el nombre de la palabra que deseas actualizar, 'atras para salir':   " word
		if [[ $word == "atras" ]]; then
			update
		elif ! sqlite3 $ruta_db "SELECT 1 FROM $idioma where lower(palabra) = lower('$word'); LIMIT 1;" | grep -q '1'; then
			echo "La palabra no existe"
			sleep 2
		else 
			clear
			sqlite3 -header -box "$ruta_db" "select * from $idioma where lower(palabra) = lower('$word');"
			read -rp "Escribe el nuevo nombre de la palabra:  " palabra
			read -rp "Escribe el tipo de palabra, verbo, adjetivo...:   " tipo
			read -rp "Escribe su traducción al otro idioma:   " traduccion
			read -rp "Escribe un ejemplo de uso:   " uso
			if sqlite3 "$ruta_db" "update $idioma set palabra='$palabra',tipo='$tipo',traduccion='$traduccion',uso='$uso' where palabra='$word';"; then
				echo "Se ha actualizado correctamente"
				sleep 1
			else
				echo "Error, no se pudo actualizar la palabra"
			sleep 1
			fi
		fi 
	done
}


# Pre-Funcion para añadir palabras nuevas
add(){
	clear
	banner
	echo -e "${AMARILLO}====================================================Añadir palabras==========================================${FIN_COLOR}"
	echo -e "${VERDE}1) Añadir Palabras en Inglés${FIN_COLOR}"
	echo -e "${VERDE}2) Añadir Palabras en español${FIN_COLOR}"
	echo -e "${CYAN}3) Actualizar palabra añadida${FIN_COLOR}"
	echo -e "${MAGENTA}4) Eliminar palabra añadida${FIN_COLOR}"
	echo -e "${ROJO}5) Ir Atrás${FIN_COLOR}"
	read -r -p "Selecciona:  " selection
	case $selection in
	1) var="ingles";adder ;;
	2) var="español";adder;;
	3)  update;;
	4) delete;;
	5) menu;;
	*) echo "Opción no válida";;
	esac
}

# Añadidor de palabras nuevas a la base de datos
adder(){
	clear
	read -rp "Escribe la palabra o escribe 'atras' para salir:  " palabra
	if [[ $palabra == "atras" ]]; then
		add
	fi
	read -rp "Escribe el tipo de palabra, verbo, adjetivo...:   " tipo
	read -rp "Escribe su traducción al otro idioma:   " traduccion
	read -rp "Escribe un ejemplo de uso:   " uso
	echo "Añadiendo..."
	palabra=$(echo "$palabra"|tr -d "\'")
	tipo=$(echo "$tipo"|tr -d "\'")
	traduccion=$(echo "$traduccion"|tr -d "\'")
	uso=$(echo "$uso"|tr -d "\'")
	sqlite3 $ruta_db <<-LIMIT
		INSERT INTO $var (palabra,tipo,traduccion,uso)
		VALUES ('$palabra','$tipo','$traduccion','$uso');
	LIMIT
	if [[ $? -eq 0 ]] ; then
	echo "Se ha agregado correctamente"
	else
		echo "No se pudo agregar"
	fi
	sleep 3
	add
}
	
	
# Mostrar Menú y opciones
menu
