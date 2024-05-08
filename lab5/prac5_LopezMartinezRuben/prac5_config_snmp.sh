#! /bin/bash


# Comprovar SNMP

pckg=$(apt list --installed snmp | grep "instal·lat") &>/dev/null

if [[ -z "$pckg" ]] ; then
        echo "Instal·lem paquets SNMP..."
        apt install -y snmp snmpd smistrip patch snmp-mibs-downloader &>/dev/null
else
	echo "Paquets SNMP ja instal·lats!"
fi


if [[ -e /root/prac5/snmp.conf ]] ; then
	rm /root/prac5/snmp.conf
	rm /root/prac5/snmpd.conf
fi

cp /etc/snmp/snmp.conf /root/prac5/snmp.conf
cp /etc/snmp/snmpd.conf /root/prac5/snmpd.conf

echo 'mibdirs + /usr/share/mibs
mibs +All' > /root/prac5/snmp.conf

# Configurar per rebre trames UDP desde qualsevol lxc
sed -i '/^agentaddress.*127/s/^/#/' /root/prac5/snmpd.conf

if [ -z "$(cat /root/prac5/snmpd.conf | grep 'agentaddress udp:161')" ] ; then
	sed -i '/#agentaddress.*127/a agentaddress udp:161' /root/prac5/snmpd.conf
fi

# Modificar sysLocation
sed -i '/^sysLocation.*Sitting/s/^/#/' /root/prac5/snmpd.conf

if [ -z "$(cat /root/prac5/snmpd.conf | grep 'sysLocation Tarragona')" ] ; then
	sed -i '/#sysLocation.*Sitting/a sysLocation Tarragona' /root/prac5/snmpd.conf
fi

# Modificar sysContact
sed -i '/^sysContact.*Me/s/^/#/' /root/prac5/snmpd.conf

if [ -z "$(cat /root/prac5/snmpd.conf | grep 'sysContact Ruben Lopez Martinez')" ] ; then
	sed -i '/#sysContact.*Me/a sysContact Ruben Lopez Martinez' /root/prac5/snmpd.conf
fi

# Afegir vistagsx a les vistes disponibles

if [ -z "$(cat /root/prac5/snmpd.conf | grep 'vistagsx')" ] ; then
	# Afegim interfaces
	OIDBRANCH=$(snmptranslate -On IF-MIB::interfaces)
	echo "interfaces = $OIDBRANCH"
	sed -i '/view.*systemonly.*included.*.1.3.6.1.2.1.25.1/a\
view vistagsx included '"$OIDBRANCH" /root/prac5/snmpd.conf

	# Afegim ip
	OIDBRANCH=$(snmptranslate -On IP-MIB::ip)
	echo "ip = $OIDBRANCH"
	sed -i '/view.*systemonly.*included.*.1.3.6.1.2.1.25.1/a\
view vistagsx included '"$OIDBRANCH" /root/prac5/snmpd.conf

	# Afegim snmp
	OIDBRANCH=$(snmptranslate -On SNMPv2-MIB::snmp)
	echo "snmpv2 = $OIDBRANCH"
	sed -i '/view.*systemonly.*included.*.1.3.6.1.2.1.25.1/a\
view vistagsx included '"$OIDBRANCH" /root/prac5/snmpd.conf


	# Afegim icmp
	OIDBRANCH=$(snmptranslate -On IP-MIB::icmp)
	echo "icmp = $OIDBRANCH"
	sed -i '/view.*systemonly.*included.*.1.3.6.1.2.1.25.1/a\
view vistagsx included '"$OIDBRANCH" /root/prac5/snmpd.conf

	# Afegim ucdavis
	OIDBRANCH=$(snmptranslate -On UCD-SNMP-MIB::ucdavis)
	echo "ucdavis = $OIDBRANCH"
	sed -i '/view.*systemonly.*included.*.1.3.6.1.2.1.25.1/a\
view vistagsx included '"$OIDBRANCH" /root/prac5/snmpd.conf

	# Afegir community string cilbup
	if [ -z "$(cat /root/prac5/snmpd.conf | grep 'rocommunity cilbup localhost')" ]; then
    		# Insertar la línea con el community string "cilbup" después de cualquier línea que contenga "rocommunity" seguido de cualquier texto y "public"
    		sed -i "/rocommunity .*public.*/a rocommunity cilbup localhost -V vistagsx" /root/prac5/snmpd.conf
	fi



fi

# Verificar si la secció ja està present en el arxiu
if ! grep -q "Process Monitoring" /root/prac5/snmpd.conf; then
    cat << EOF >> /root/prac5/snmpd.conf


#
#  Process Monitoring
#
                               # At least one  'mountd' process
proc  mountd
proc sshd
                               # At least one 'sendmail' process, but no more than 10
proc named 10 1
proc dhcpd
proc rsyslog
#proc apache2 4 1

#  Walk the UCD-SNMP-MIB::prTable to see the resulting output
#  Note that this table will be empty if there are no "proc" entries in the snmpd.conf file


#
#  Disk Monitoring
#
                               # 10MBs required on root disk, 5% free on /var, 10% free on all other disks
disk       /     10000
disk       /var  5%
includeAllDisks  10%

#  Walk the UCD-SNMP-MIB::dskTable to see the resulting output
#  Note that this table will be empty if there are no "disk" entries in the snmpd.conf file


#
#  System Load
#
                               # Unacceptable 1-, 5-, and 15-minute load averages
load   12 10 5

#  Walk the UCD-SNMP-MIB::laTable to see the resulting output
#  Note that this table *will* be populated, even without a "load" entry in the snmpd.conf file

EOF
fi



# SNMPv3 - Acces remot
# Verificar si la configuració createUser gsxViewer SHA aut85406112 no existeix en el arxiu snmpd.conf
if ! grep -q "createUser gsxViewer SHA aut85406112" /root/prac5/snmpd.conf; then
    echo "createUser gsxViewer SHA aut85406112" >> /root/prac5/snmpd.conf
fi

# Verificar si la configuració createUser gsxAdmin SHA aut85406112 DES sec85406112 no existeix en el arxiu snmpd.conf
if ! grep -q "createUser gsxAdmin SHA aut85406112 DES sec85406112" /root/prac5/snmpd.conf; then
    echo "createUser gsxAdmin SHA aut85406112 DES sec85406112" >> /root/prac5/snmpd.conf
fi

# Verificar si la configuració rouser gsxViewer authNoPriv no existeix en el arxiu snmpd.conf
if ! grep -q "rouser gsxViewer authNoPriv" /root/prac5/snmpd.conf; then
    echo "rouser gsxViewer authNoPriv" >> /root/prac5/snmpd.conf
fi

# Verificar si la configuració rwuser gsxAdmin authNoPriv no existeix en el arxiu snmpd.conf
if ! grep -q "rwuser gsxAdmin authNoPriv" /root/prac5/snmpd.conf; then
    echo "rwuser gsxAdmin authPriv" >> /root/prac5/snmpd.conf
fi



# Copiar fitxers locals al seu entorn de treball real
cp /root/prac5/snmp.conf /etc/snmp/
cp /root/prac5/snmpd.conf /etc/snmp/

chmod 644 /etc/snmp/snmp.conf
chmod 600 /etc/snmp/snmpd.conf

service snmpd restart
