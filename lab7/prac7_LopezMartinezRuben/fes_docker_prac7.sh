#!/bin/bash

# Per executar comandes de docker
if [ -z "$(groups milax | grep 'docker')" ] ; then
	usermod -aG docker milax
fi

# Imatge Docker a utilitzar
imatge="gsx:prac7"

# Comprovar si la imatge ja existeix
if [ "$(docker images -q $imatge)" ]; then
    echo "La imatge $imatge ja existeix. No es reconstruirà."
else
    # Construir la imatge Docker
    docker build -t $imatge -f "dockerfile_gsx_prac7" .

    # Comprovar si la imatge s'ha construït correctament
    if [ "$(docker images -q $imatge)" ]; then
        echo "Imatge construïda amb èxit."
    else
        echo "Error en la construcció de l'imatge."
        exit 1
    fi
fi

# Run dels contenidors
OPCIONS="-itd --rm --privileged"

# Crear y executar els contenidors sense networks (excepte R1)
for node in {1..4}; do
    if [ "$(docker ps -q -f name=^R$node$)" ]; then
        echo "El contenidor R$node ja està en execució."
    else
        if [ $node -eq 1 ]; then
            docker run $OPCIONS --hostname router$node --name R$node $imatge
        else
            docker run $OPCIONS --hostname router$node --network=none --name R$node $imatge
        fi
        #xterm -e docker attach R$node &
    fi
done
