#! /bin/bash 

ip addr add 198.18.192.1/20 dev eth1
ip link set eth1 up

fitxerConf="/etc/sysctl.conf"

lineaForward=$(grep "net.ipv4.ip_forward=" "$fitxerConf")

if [[ "lineaForward" == *"=1"* ]]; then
	sed -i '/net.ipv4.ip_forward=/s/^#//g' "$fitxerConf"
	echo "Forwarding activat"
	sysctl -p /etc/sysctl.conf
fi

if [[ ! $(cat /etc/hosts | grep "server") ]] ; then
	echo 198.18.207.254	server >> /etc/hosts
fi

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

if [[ ! $(cat /etc/ssh/sshd_config | grep "PermitRootLogin	yes") ]] ; then
	echo "PermitRootLogin	yes" >> /etc/ssh/sshd_config
	systemctl restart ssh
fi

