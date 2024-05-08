#!/bin/bash

# Dirección IP del router
ROUTER_IP="198.18.192.1"

# Usuario para acceso de lectura/escritura
READ_WRITE_USER="gsxAdmin"
# Contraseña de autenticación para acceso de lectura/escritura
READ_WRITE_AUTH_PASS="aut85406112"
# Contraseña de encriptación para acceso de lectura/escritura
READ_WRITE_PRIV_PASS="sec85406112"

# Umbral para el número de solicitudes SNMP
THRESHOLD=10

# Bucle para hacer snmpgets suficientes para superar el umbral
for ((i=0; i<=$((THRESHOLD+5)); i++)); do
    snmpget -v3 -u "$READ_WRITE_USER" -l authPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$ROUTER_IP" SNMPv2-MIB::sysDescr.0
done

# Probar snmpset para establecer valores en el router
snmpset -v3 -u "$READ_WRITE_USER" -l authNoPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$ROUTER_IP" ip.ipForwarding.0 = 1
snmpset -v3 -u "$READ_WRITE_USER" -l authNoPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$ROUTER_IP" sysName.0 = 'docker container'

# Guardar el syslog del servidor correspondiente al router
cat /var/log/remots/router/2024-05-07 > log_central_router.txt

