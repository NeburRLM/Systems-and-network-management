#!/bin/bash

PATH="$PATH:/usr/sbin/"

# S'ha de tenir privilegis
if [[ $EUID -ne 0 ]] ; then
    echo "Necessitem privilegis per executar aquest script"
    exit 1
fi
systemctl start acct

if [ $# -eq 2 ]; then
    command="$1"
    user="$2"
    if lastcomm "$command" | awk -v user="$user" '{if ($2 == "S" || $2 == "F" || $2 == "C" || $2 == "D" || $2 == "X") {u=$3} else {u=$2}; if (u == user) print u}' | grep -q "^$user$"; then
        echo "L'usuari $user ha executat la comanda $command en els següents dies:"
        lastcomm "$command" | awk -v user="$user" '{if ($2 == "S" || $2 == "F" || $2 == "C" || $2 == "D" || $2 == "X") {u=$3; d=$7 " " $8 " " $9 " " $10} else {u=$2; d=$6 " " $7 " " $8 " " $9}; if (u == user) print d}'
    else
        echo "L'usuari $user no ha executat la comanda $command."
    fi
elif [ $# -eq 1 ]; then
    command="$1"
    echo "Els usuaris que han executat la comanda $command i el nombre de vegades que l'han executat són:"
    lastcomm "$command" | awk '{if ($2 == "S" || $2 == "F" || $2 == "C" || $2 == "D" || $2 == "X") {u=$3} else {u=$2}; print u}' | sort | uniq -c
else
    echo "Ús: $0 <comanda> [usuari]"
    echo "Per a veure els dies que un usuari ha executat una comanda: $0 <comanda> <usuari>"
    echo "Per a veure quins usuaris han executat una comanda i el nombre de vegades: $0 <comanda>"
    exit 1
fi
