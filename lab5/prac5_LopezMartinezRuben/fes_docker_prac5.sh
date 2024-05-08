#!/bin/bash

# Per executar comandes de docker
if [ -z "$(groups milax | grep 'docker')" ] ; then
	usermod -aG docker milax
fi

# Build de la imatge
docker build -t gsx:prac5 -f dockerfile_gsx_prac5 .

# Comprovar si la imatge s'ha construït correctament
if [ "$(docker images -q gsx:prac5)" ]; then
    echo "Imatge construïda amb èxit."
else
    echo "Error en la construcció de l'imatge."
    exit 1
fi

# Comprovar si les xarxes ja existeixen abans de crear-les
if [ "$(docker network ls -q -f name=ISP)" ] || [ "$(docker network ls -q -f name=DMZ)" ] || [ "$(docker network ls -q -f name=INTRANET)" ]; then
    echo "Les xarxes ja existeixen. No es crearà cap xarxa nova."
else

	# Creació de les xarxes ISP, DMZ, INTRANET
	docker network create --driver=bridge --subnet=10.0.2.16/30 ISP
	docker network create --driver=bridge --subnet=198.18.192.0/20 --gateway=198.18.192.2 DMZ
	docker network create --driver=bridge --subnet=172.24.192.0/18 --gateway=172.24.192.2 INTRANET

	# Comprovar si les xarxes s'han creat correctament
	if [ "$(docker network ls -q -f name=ISP)" ] && [ "$(docker network ls -q -f name=DMZ)" ] && [ "$(docker network ls -q -f name=INTRANET)" ]; then
    		echo "Xarxes creades amb èxit."
	else
    		echo "Error en la creació de les xarxes."
    		exit 1
	fi
fi

# Run dels contenidors
OPCIONS="-itd --rm --privileged"

imatge="gsx:prac5"
mkdir -p /home/milax/practica5

if ! docker ps -a --format '{{.Names}}' | grep -q '^Router$'; then
    docker run $OPCIONS --hostname router --network=ISP --name Router --mount type=bind,ro,src=/home/milax/practica5,dst=/root/prac5 $imatge
fi
#docker run $OPCIONS --hostname router --network=ISP --name Router --mount type=bind,src=/home/milax/practica5,dst=/root/prac5,ro $imatge

# Verificar si el contenedor Router está conectado a las redes DMZ e INTRANET
if [[ "$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' DMZ)" != *"Router"* ]]; then
    docker network connect DMZ Router
fi

if [[ "$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' INTRANET)" != *"Router"* ]]; then
    docker network connect INTRANET Router
fi

if ! docker ps -a --format '{{.Names}}' | grep -q '^Server$'; then
    docker run $OPCIONS --hostname server --network=DMZ --name Server --mount type=bind,src=/home/milax/practica5,dst=/root/prac5 $imatge
fi
#docker run $OPCIONS --hostname server --network=DMZ --name Server --mount type=bind,src=/home/milax/practica5,dst=/root/prac5 $imatge


if ! docker ps -a --format '{{.Names}}' | grep -q '^DHCP$'; then
    docker run $OPCIONS --hostname dhcp --network=INTRANET --name DHCP --mount type=bind,ro,src=/home/milax/practica5,dst=/root/prac5 $imatge
fi
#docker run $OPCIONS --hostname dhcp --network=INTRANET --name DHCP --mount type=bind,src=/home/milax/practica5,dst=/root/prac5,ro $imatge

xterm -e docker attach Router &
xterm -e docker attach Server &
xterm -e docker attach DHCP &

# Comprovar si els contenidors s'han creat correctament
if [ "$(docker ps -q -f name=Router)" ] && [ "$(docker ps -q -f name=Server)" ] && [ "$(docker ps -q -f name=DHCP)" ]; then
    echo "Contenidors creats amb èxit."
else
    echo "Error en la creació dels contenidors."
    exit 1
fi
