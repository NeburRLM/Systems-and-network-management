#!/bin/bash

# Ruta al script de vigilancia SNMP
SNMP_SCRIPT="/root/vigila_snmp.sh"

# Comprovem si tenim cron instal·lat
pckg=$(apt list --installed cron | grep "instal·lat") &>/dev/null

if [[ -z "$pckg" ]] ; then
        echo "Instal·lem cron..."
        apt install -y cron &>/dev/null
	echo "Fet!"
fi


# Configurar el cron per executar el script cada 5 minuts
(crontab -l ; echo "*/5 * * * * $SNMP_SCRIPT") | crontab -
echo "Cron configurat per executar $SNMP_SCRIPT cada 5 minuts."

service cron start
