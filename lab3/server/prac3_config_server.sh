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
        echo 198.18.192.1       router >> /etc/hosts
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

if [[ ! $(cat /etc/resolv.conf | grep "nameserver 198.18.192.1") ]] ; then
        echo "nameserver 198.18.192.1"  >> /etc/resolv.conf
fi

# Canviar temporalment el arxiu /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Verificar si els paquets bind9, bind9-doc y dnsutils estan instal·lats
packages=("bind9" "bind9-doc" "dnsutils")
for package in "${packages[@]}"; do
    if ! dpkg -s "$package" &> /dev/null; then
        echo "El paquet $package no està instal·lat. Instal·lant..."
        apt-get install -y "$package"
    else
        echo "El paquet $package ja està instal·lat."
    fi
done

# Modifiquem el fitxer /etc/default/named per peticions IPv4
if [[ ! $(cat /etc/default/named | grep 'OPTIONS="-u bind -4"') ]] ; then
	echo 'OPTIONS="-u bind -4"' >> /etc/default/named
fi

# Verificar la sintaxis de los archivos de configuración y zona
check_syntax() {
    error=0
    /sbin/named-checkconf named.conf.local || error=1
    /sbin/named-checkconf named.conf.options || error=1
    /sbin/named-checkzone intranet.gsx db.intranet.gsx || error=1
    /sbin/named-checkzone dmz.gsx db.dmz.gsx || error=1
    /sbin/named-checkzone 198 db.198 || error=1
    /sbin/named-checkzone 172 db.172 || error=1
    return $error
}

# Cambiar las propiedades de los archivos a los originales
change_properties() {
    chmod --reference=/etc/bind/db.127 /var/cache/bind/db.198
    chown --reference=/etc/bind/db.127 /var/cache/bind/db.198
    chmod --reference=/etc/bind/db.127 /var/cache/bind/db.172
    chown --reference=/etc/bind/db.127 /var/cache/bind/db.172
    chmod --reference=/etc/bind/db.127 /var/cache/bind/db.intranet.gsx
    chown --reference=/etc/bind/db.127 /var/cache/bind/db.intranet.gsx
    chmod --reference=/etc/bind/db.127 /var/cache/bind/db.dmz.gsx
    chown --reference=/etc/bind/db.127 /var/cache/bind/db.dmz.gsx
    chmod --reference=/etc/bind/db.127 /etc/bind/named.conf.local
    chown --reference=/etc/bind/db.127 /etc/bind/named.conf.local
    chmod --reference=/etc/bind/db.127 /etc/bind/named.conf.options
    chown --reference=/etc/bind/db.127 /etc/bind/named.conf.options
}

# Copiar archivos named* a /etc/bind/
copy_named_files() {
    cp named.conf.local /etc/bind/
    cp named.conf.options /etc/bind/ 
}

# Copiar archivos de zona a /var/cache/bind/
copy_zone_files() {
    cp db.intranet.gsx /var/cache/bind/
    cp db.dmz.gsx /var/cache/bind
    cp db.198 /var/cache/bind
    cp db.172 /var/cache/bind
}

# Verificar la sintaxis de los archivos
check_syntax
if [ $? -eq 0 ]; then
    # No hay errores de sintaxis, proceder con las acciones
    copy_named_files
    copy_zone_files
    change_properties
    systemctl stop named
    systemctl start named
    echo "Acciones completadas exitosamente."
else
    echo "Se encontraron errores de sintaxis. No se pudieron completar las acciones."
fi

# /etc/resolv.conf
# Nom localhost
dns_server="127.0.0.1"

# Dominis search
search_domains="dmz.gsx intranet.gsx"

# Crear contingut de l'arxiu resolv.conf
resolv_content="nameserver $dns_server\nnameserver 8.8.8.8\nsearch $search_domains\n"

# Guardar contingut en el arxiu resolv.conf
echo -e "$resolv_content" > /etc/resolv.conf
