#! /bin/bash 
ip addr add 198.18.192.1/20 dev eth1
ip link set eth1 up

sysctl -w net.ipv4.ip_forward=1

if [[ ! $(cat /etc/hosts | grep "server") ]] ; then
        echo 198.18.207.254     server >> /etc/hosts
fi

iptables -t nat -F POSTROUTING
l=$(iptables -t nat -C POSTROUTING -s "198.18.192.0/20" -o eth0 -j MASQUERADE) 
if [[ $l != 0 ]]; then
        iptables -t nat -A POSTROUTING -s 198.18.192.0/20 -o eth0 -j MASQUERADE
else
        echo -e "Configuració IPs correcta existent\n"
fi

dpkg -s openssh-server &> /dev/null 
val=$?
if [ $val -eq 0 ] ; then
        echo -e "Ssh instal·lat\n"
        echo "$(grep ssh /etc/services)"
        echo ""
        echo "$(ss -4ltn)"
else
        echo "Servei ssh no instal·lat, instal·lant"
        apt install -y openssh-server &> /dev/null
        echo -e "Instal·lat\n"
        echo "$(systemctl status ssh)"
        echo ""
        echo "$(ss -4lnt | grep ":22")"
fi

if [[ ! $(cat /etc/ssh/sshd_config | grep "PermitRootLogin      yes") ]] ; then
        echo "PermitRootLogin   yes" >> /etc/ssh/sshd_config
        systemctl restart ssh
fi


# Configuració de la eth2
ip addr add 172.24.192.1/18 dev eth2
ip link set eth2 up

fitxerConf="/etc/sysctl.conf"

# Configuració SNAT per a Intranet
l=$(iptables -t nat -C POSTROUTING -s "172.24.192.0/18" -o eth0 -j MASQUERADE) 
if [[ $l != 0 ]]; then
	iptables -t nat -A POSTROUTING -s 172.24.192.0/18 -o eth0 -j MASQUERADE
else
	echo -e "Configuració IPs correcta existent\n"
fi


# Redireccionament DNS per resolució de noms
IP_ROUTER_INTRANET="172.24.192.1"
IP_ROUTER_DMZ="198.18.192.1"
IP_DNS_EXTERN="8.8.8.8"

# Verificar si la regla ya està configurada para redireccionar consultes DNS
if ! iptables -t nat -C PREROUTING -i eth2 -d $IP_ROUTER_INTRANET -p udp --dport 53 -j DNAT --to-destination $IP_DNS_EXTERN:53 &> /dev/null; then
    # Afegir la regla per redireccionar consultes DNS cap al servidor DNS extern
    iptables -t nat -A PREROUTING -i eth2 -d $IP_ROUTER_INTRANET -p udp --dport 53 -j DNAT --to-destination $IP_DNS_EXTERN:53
    echo "Regla DNS per eth2 agregada correctament"
else
    echo "La regla DNS per eth2 ja està configurada"
fi

# Verificar si la regla ya està configurada per redireccionar consultes DNS de la DMZ
if ! iptables -t nat -C PREROUTING -i eth1 -d $IP_ROUTER_DMZ -p udp --dport 53 -j DNAT --to-destination $IP_DNS_EXTERN:53 &> /dev/null; then
    # Agregar la regla per redireccionar consultes DNS de la DMZ cap al servidor DNS extern
    iptables -t nat -A PREROUTING -i eth1 -d $IP_ROUTER_DMZ -p udp --dport 53 -j DNAT --to-destination $IP_DNS_EXTERN:53
    echo "Regla DNS per DMZ agregada correctament"
else
    echo "La regla DNS per DMZ ja està configurada"
fi



# Arxiu configuració
dhclient_conf="/etc/dhcp/dhclient.conf"

# Verificar si las líneas ya están presentes
if grep -qE "^\s*prepend domain-name-servers\s+198.18.207.254;" "$dhclient_conf"; then
    echo "La línea 'prepend domain-name-servers 198.18.207.254;' ya está presente."
else
    echo "prepend domain-name-servers 198.18.207.254;" | sudo tee -a "$dhclient_conf" > /dev/null
    echo "La línea 'prepend domain-name-servers 198.18.207.254;' se ha añadido."
fi

if grep -qE "^\s*supersede domain-name\s+\"dmz.gsx\";" "$dhclient_conf"; then
    echo "La línea 'supersede domain-name \"dmz.gsx\";' ya está presente."
else
    echo "supersede domain-name \"dmz.gsx\";" | sudo tee -a "$dhclient_conf" > /dev/null
    echo "La línea 'supersede domain-name \"dmz.gsx\";' se ha añadido."
fi

if grep -qE "^\s*supersede domain-name\s+\"intranet.gsx\";" "$dhclient_conf"; then
    echo "La línea 'supersede domain-name \"intranet.gsx\";' ya está presente."
else
    echo "supersede domain-name \"intranet.gsx\";" | sudo tee -a "$dhclient_conf" > /dev/null
    echo "La línea 'supersede domain-name \"intranet.gsx\";' se ha añadido."
fi


# Eliminar regles PREROUTING FASE 2
iptables -t nat -F PREROUTING


# Verificar si las reglas iptables ya están presentes para DNS UDP
if iptables -C FORWARD -s 198.18.207.254/32 -p udp -m udp --dport 53 -j ACCEPT &>/dev/null; then
    echo "La regla iptables para DNS UDP ya está presente."
else
   # Configurar iptables para permitir consultas DNS UDP desde la IP especificada
    iptables -A FORWARD -s 198.18.207.254/32 -p udp -m udp --dport 53 -j ACCEPT
    echo "Regla iptables para DNS UDP añadida."
fi

# Verificar si las reglas iptables ya están presentes para DNS TCP
if iptables -C FORWARD -s 198.18.207.254/32 -p tcp -m tcp --dport 53 -j ACCEPT &>/dev/null; then
    echo "La regla iptables para DNS TCP ya está presente."
else
    # Configurar iptables para permitir consultas DNS TCP desde la IP especificada
    iptables -A FORWARD -s 198.18.207.254/32 -p tcp -m tcp --dport 53 -j ACCEPT
    echo "Regla iptables para DNS TCP añadida."
fi
# Verificar si las reglas iptables ya están presentes para DNS UDP
if iptables -C iptables -A PREROUTING -i eth0 -p udp -m udp --dport 53 -j DNAT --to-destination 198.18.207.254 -t nat &>/dev/null; then
    echo "La regla iptables ja existeix"
else
    # Configurar iptables para filtrar consultas DNS UDP internas
    iptables -A PREROUTING -i eth0 -p udp -m udp --dport 53 -j DNAT --to-destination 198.18.207.254 -t nat
    echo "Regla afegida"
fi
