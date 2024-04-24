#!/bin/bash

# Comprovem si han passat els parametres necessaris
if [ $# -ne 1 ]; then
    echo "Error: Falten parametres"
    echo -e "Formal=> treballproj.sh projecte\n"
    exit 1
fi


# Comprovem si existeix el projecte
if [ ! -d /empresa/projectes/"$1" ] ; then
	echo -e "Error: NO existeix cap projecte amb aquest nom: $1"
	exit 1
else
	projecte="$1"
fi

# Modifiquem l'entorn per a que els arxius creats per defecte tinguin sols permisos per al owner i group
cd /empresa/projectes/"$projecte"
umask 007
newgrp "$projecte"
