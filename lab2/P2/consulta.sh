#!/bin/bash

output_log="/home/milax/Documents/outputConsulta.log"
fitxer="/tmp/paquets"

if [ $# -eq 0 ]; then
    if [ -e "$fitxer" ]; then
        echo "Llegint paràmetres des de /tmp/paquets..." | tee -a "$output_log"
        while IFS= read -r l || [ -n "$l" ]; do
            # Elimina espais
            paquet=$(echo "$l" | tr -d '[:space:]')
            set -- "$@" "$paquet"
        done < "$fitxer"
    else
        logger "No s'han proporcionat paràmetres i no existeix /tmp/paquets."
    fi
fi


for package in "$@"; do
        echo "Informació pel paquet: $package" | tee -a "$output_log"

        # Verificar si el paquet està instal·lat
        if dpkg -l | grep -w "^ii  $package" > /dev/null; then
                # Obtenir versió instal·lada
                version=$(dpkg -l "$package" | awk '$2 == "'$package'" {print $3}')
                echo ">Versió instal·lada: $version" | tee -a "$output_log"


                # Obtenir la data y hora de instalació
                install_time=$(grep " install $package " /var/log/dpkg.log | awk '{print $1, $2}')
                echo ">Data y hora de instal·lació: $install_time" | tee -a "$output_log"


                # Verificar la disponibilitat de actualizacions
                available_updates=$(apt list --upgradable 2>/dev/null | grep -w "$package")
                if [ -n "$available_updates" ]; then
                        echo ">Actualitzacions disponibles: $available_updates" | tee -a "$output_log"
                else
                        echo ">No hi ha actualizacions disponibles." | tee -a "$output_log"
                fi


                # Obtenir la llista de dependencies del paquet
		dependencies=$(apt-cache depends "$package" | grep "Depèn" | awk '{print $2}' | sed ':a;N;$!ba;s/\n/, /g')
                echo ">Dependencies del paquet: $dependencies" | tee -a "$output_log"

                # Obtenir la llista de fitxers de configuració associats al paquet
                config_files=$(dpkg-query -L $package | grep -E '\/etc\/.*')
                if [ -n "$config_files" ]; then
                        echo ">Fitxers de configuració:" | tee -a "$output_log"
                        echo "$config_files" | tee -a "$output_log"
                else
                        echo ">No hi ha fitxers de configuració associats." | tee -a "$output_log"
                fi
        else
                echo ">El paquet $package no està instal·lat." | tee -a "$output_log"
        fi

        echo "---------------------------------------" | tee -a "$output_log"
done
if ! [ $# -eq 0 ]; then
	echo "----------CONSULTA REALITZADA----------" | tee -a "$output_log"
	echo -e "" | tee -a "$output_log"
fi
