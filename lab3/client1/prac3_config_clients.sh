#!/bin/bash

# Configurar el arxiu dhclient.conf per enviar el host-name y sol·licitar un lease-time de un dia
dhclient_conf="/etc/dhcp/dhclient.conf"

# Verificar si las líneas ya están presentes
if grep -qE "^\s*require domain-name, domain-name-servers;" "$dhclient_conf"; then
    echo "Las líneas 'require domain-name, domain-name-servers;' ya están presentes."
else
    echo "require domain-name, domain-name-servers;" | tee -a "$dhclient_conf" > /dev/null
    echo "Las líneas 'require domain-name, domain-name-servers;' se han añadido."
fi

if grep -qE "^\s*send host-name = gethostname\(\);" "$dhclient_conf"; then
    echo "La línea 'send host-name = gethostname();' ya está presente."
else
    echo "send host-name = gethostname();" | tee -a "$dhclient_conf" > /dev/null
    echo "La línea 'send host-name = gethostname();' se ha añadido."
fi

if grep -qE "^\s*request subnet-mask, broadcast-address, time-offset, routers, domain-name, domain-name-servers, domain-search;" "$dhclient_conf"; then
    echo "La línea 'request subnet-mask, broadcast-address, time-offset, routers, domain-name, domain-name-servers, domain-search;' ya está presente."
else
    echo "request subnet-mask, broadcast-address, time-offset, routers, domain-name, domain-name-servers, domain-search;" | tee -a "$dhclient_conf" > /dev/null
    echo "La línea 'request subnet-mask, broadcast-address, time-offset, routers, domain-name, domain-name-servers, domain-search;' se ha añadido."
fi


# Axecar la interficie eth0
ifup eth0

# Mostrar la configuració de xarxa obtinguda
echo "Configuración de red obtenida:"
ip addr show dev eth0

# Comprovar la assignació de la IP, la porta de enllaç  predeterminada i els serveis de noms
echo "Porta de enllaç predeterminada:"
ip route | grep default
echo "Servidors de noms (DNS):"
cat /etc/resolv.conf

# Comprovar el temps de lloguer en /var/lib/dhcp
echo "Temps de lloguer obtingut:"
ls -l /var/lib/dhcp
