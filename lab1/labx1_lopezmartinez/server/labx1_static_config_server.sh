#! /bin/bash 

fitxerConf="/etc/network/interfaces"

if  ! grep -q "iface eth0 inet static" "$fitxerConf" ; then
	
	sed -i 's/iface eth0 inet dhcp/iface eth0 inet static/g' /etc/network/interfaces
	echo "
		address 198.18.207.254
 		netmask 255.255.240.0
		network 198.18.192.0
 		broadcast 198.18.207.255
 		gateway 198.18.192.1
	" >> /etc/network/interfaces
fi


if [[ ! $(cat /etc/hosts | grep "router") ]] ; then
	echo 198.18.192.1	router >> /etc/hosts
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
