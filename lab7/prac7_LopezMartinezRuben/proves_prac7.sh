#!/bin/bash

# Router a usar per la prova
ROUTER="R2"

# Fitxer de sortida
OUTPUT_FILE="sortida_prac7.txt"

# Neteja del fitxer de sortida
echo "### Iniciant proves en $ROUTER ###" > $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Comprovació de que els dos daemons se estan executant
echo "# Comprovant que els daemons s'estan executant en $ROUTER..." | tee -a $OUTPUT_FILE
docker top $ROUTER | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Comprobació de la taula de enrutament actualitzada amb informació de zebra
echo "# Comprovant la taula d'enrutament de $ROUTER..." | tee -a $OUTPUT_FILE
docker exec $ROUTER ip -c route | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Accedint a vtysh per comprovar la configuració i la taula d'enrutament detallada
echo "# Comprovant configuració i taula d'enrutament en vtysh de $ROUTER..." | tee -a $OUTPUT_FILE
docker exec $ROUTER vtysh -c "show running-config" | tee -a $OUTPUT_FILE
docker exec $ROUTER vtysh -c "show ip route" | tee -a $OUTPUT_FILE
docker exec $ROUTER vtysh -c "show ip rip status" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Comprovació de les IPs i les rutes en $ROUTER
echo "Comprovant les IPs i rutes de $ROUTER...\n" | tee -a $OUTPUT_FILE
docker exec $ROUTER ip -c address | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Realitzar un ping i traceroute desde R1 a R2
IP_DESTI="10.192.2.1"
echo "# Realitzant ping i traceroute desde R1 a $ROUTER ($IP_DESTI)..." | tee -a $OUTPUT_FILE
docker exec R1 ping -c1 $IP_DESTI | tee -a $OUTPUT_FILE
docker exec R1 traceroute -n $IP_DESTI | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Traceroute
echo "# Realitzant traceroute desde $ROUTER ($IP_DESTI)..." | tee -a $OUTPUT_FILE
docker exec $ROUTER traceroute -n -T $IP_DESTI | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Forçar la caiguda d'un enllaç
LINK="link1_veth2"
echo "# Forçant la caiguda de l'enllaç $LINK en $ROUTER..." | tee -a $OUTPUT_FILE
docker exec $ROUTER ip link set $LINK down | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

sleep 10

# Verificar la ruta novament després de la caiguda de l'enllaç
echo "# Verificant la ruta en R1 cap a $IP_DESTI després de la caiguda de l'enllaç..." | tee -a $OUTPUT_FILE
docker exec R1 ip route get $IP_DESTI | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Traceroute desde R1 a $IP_DESTI després de la caiguda de l'enllaç
echo "# Realizant traceroute desde R1 a $IP_DESTI després de la caiguda de l'enllaç..." | tee -a $OUTPUT_FILE
docker exec R1 traceroute -n $IP_DESTI | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Axecar l'enllaç novament
echo "# Axecant novament l'enllaç $LINK en $ROUTER..." | tee -a $OUTPUT_FILE
docker exec $ROUTER ip link set $LINK up | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Esperar uns segons per la convergencia de la xarxa
sleep 10

# Verificar la ruta novament després d'axecar el enllaç
echo "# Verificant la ruta en R1 cap a $IP_DESTI després d'axecar l'enllaç..." | tee -a $OUTPUT_FILE
docker exec R1 ip route get $IP_DESTI | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Traceroute desde R1 a $IP_DESTI després d¡axecar l'enllaç
echo "# Realizant traceroute desde R1 a $IP_DESTI després d'axecar l'enllaç..." | tee -a $OUTPUT_FILE
docker exec R1 traceroute -n $IP_DESTI | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

echo "### Proves completades." | tee -a $OUTPUT_FILE
