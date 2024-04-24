#!/bin/bash

# Creem estructura bàsica requerida
echo -e "####Creant estructura basica ...####\n"
mkdir -p /empresa/{usuaris,projectes,bin}
chmod 1777 /empresa/bin

# Comprovar si s'han passat els 2 parametres (usuaris i projectes)
if [ $# -ne 2 ]; then
	echo -e "Error: Falten parametres\n"
	echo "Ús: altausuaris.sh usuaris.txt projectes.txt"
	exit 1
fi
if [ "$1" != "usuaris.txt" ]; then
	echo "Error de paràmetres. FORMAT=> altausuaris.sh usuaris.txt projectes.txt"
	exit 1
fi
if [ "$2" != "projectes.txt" ]; then
        echo "Error de paràmetres. FORMAT=> altausuaris.sh usuaris.txt projectes.txt"
        exit 1
fi

# Afegim el directori bin de l'usuari al final de la variable PATH
if grep -Fxq "export PATH=\$PATH:/empresa/usuaris/\$USER/bin:/empresa/bin:." "/etc/skel/.bashrc"; then
	echo "PATH existent al .bashrc del skel"
else
   	echo 'export PATH=$PATH:/empresa/usuaris/$USER/bin:/empresa/bin:.' >> "/etc/skel/.bashrc"
    	echo "PATH afegit al .bashrc del skel"
fi

# Afegim umask 
if grep -Fxq "umask 0007" "/etc/skel/.bashrc"; then
        echo "Màscara existent al .bashrc del skel"
else
        echo 'umask 0007' >> "/etc/skel/.bashrc"
        echo "Màscara afegida al .bashrc del skel"
fi



# Gestió bucle usuaris
primera_linia=true
while IFS=: read -r dni nom num projectes; do
	if [ "$primera_linia" = true ]; then
       		primera_linia=false
       		continue  # Salta a la següent iteració
     	fi

     	# Processar el nom y els cognoms
     	nomUser=$(echo "$nom" | cut -d ',' -f2 | tr -d '[:space:]')  # Extreu el nom de la cadena de nom i cognoms
     	cognomsUser=$(echo "$nom" | cut -d ',' -f1 | tr -d '[:space:]')  # Extreu els cognoms de la cadena de nom i cognoms
     	inicialsCognoms=$(echo "$cognomsUser" | grep -o '[A-Z]' | tr -d '\n')
     	# Concatenar el nom i les inicials dels cognoms
     	nomCompletUser="${nomUser}${inicialsCognoms}"

    	# Verificar si l'usuari que volem afegir al sistema no existeix, a partir del seu dni (ja que poden haver dos persones amb el mateix nom
	# però amb diferent dni, per tant seran persones diferents)
	userExistent=false
	dniSistema=$(getent passwd | awk -F: -v d="$dni" -v OFS=: '$5 ~ d {print $5}')
	if [ -n "$dniSistema" ]; then
    		userExistent=true
	fi
	# Si el dni de l'usuari no existeix i hi ha un nom igual al seu, modifiquem el seu nom afegint un número posterior al seu nom
	if [ -d "/empresa/usuaris/$nomCompletUser" ] && [ "$userExistent" = false ]; then
    		# Si existeix, agregar un número al final del nom de l'usuari
        	contador=1
        	while [ -d "/empresa/usuaris/${nomCompletUser}_${contador}" ]; do
        		contador=$((contador + 1))
        	done
        	nomCompletUser="${nomCompletUser}_${contador}"
    	fi
    	# Crear usuari amb la seva carpeta si l'usuari no existeix
	if [ "$userExistent" = false ]; then
		useradd -c "$dni" -d /empresa/usuaris/"$nomCompletUser" -s "/bin/bash" -m "$nomCompletUser" &> /dev/null
		passwd -d -q "$nomCompletUser"
		mkdir -p /empresa/usuaris/"$nomCompletUser"/bin &> /dev/null
		# Assignem com a owner l'usuari
		chown -R "$nomCompletUser":"$nomCompletUser" /empresa/usuaris/"$nomCompletUser"
		chmod -R 4700 /empresa/usuaris/"$nomCompletUser"
		echo "->Usuari $nomCompletUser amb $dni afegit al sistema"
		#Crear grups projectes
		for projecte in $(echo "$projectes" | sed "s/,/ /g")
		do
			groupadd "$projecte" &> /dev/null
			# Assignem grups secundaris al usuari
			usermod -aG "$projecte" "$nomCompletUser" &> /dev/null
		done
	else
		echo "Usuari existent en el sistema amb dni $dniSistema. No s'ha pogut afegir."
	fi
done < "$1"

# Gestió bucle projectes
primera_linia=true
while IFS=: read -r nom_projecte owner descripcio
do
	if [ "$primera_linia" = true ]; then
                primera_linia=false
                continue  # Salta a la següent iteració
        fi
	mkdir -p /empresa/projectes/"$nom_projecte" &> /dev/null
	ownerC=$(echo "$owner" | tr -d '[:space:]')
	nomCompletUser=$(getent passwd | awk -F: -v d="$ownerC" -v OFS=: '$5 ~ d {print $1}')
	#echo "$ownerC => $nomCompletUser"
	if [ -n "$nomCompletUser" ]; then
        	# Canvia el grup primari de l'usuari al nom del projecte
        	usermod -g "$nom_projecte" "$nomCompletUser" &> /dev/null
	fi
	chown "$nomCompletUser":"$nom_projecte" /empresa/projectes/"$nom_projecte"
        chmod -R 1770 /empresa/projectes/"$nom_projecte"
done < "$2"
