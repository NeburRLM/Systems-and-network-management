#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Ús: $0 <paquet1> [<paquet2> ...]"
    exit 1
fi

for package in "$@"; do
    echo "Desinstal·lant el paquet: $package"

    # Verificar si el paquet està instal·lat
    if dpkg -l | grep -w "^ii  $package" > /dev/null; then
        # Obtenir la llista de fitxers de configuració associats al paquet
        config_files=$(dpkg-query -L $package | grep -E '\/etc\/.*')

        # Desinstal·lar el paquet sense eliminar les seves configuracions ni dependencies
        echo "Desinstal·lant $package sense eliminar configuracions ni dependencies..."
        apt-get remove --purge -y $package

        echo "Desinstal·lació completada."

        # Mostrar fitxers de configuració associats al paquet
        if [ -n "$config_files" ]; then
            echo "Fitxers de configuració conservats:"
            echo "$config_files"
        else
            echo "No hi ha fitxers de configuració associats."
        fi

    else
        echo "El paquete $package no està instal·lat."
    fi

    echo "---------------------------------------"
done

