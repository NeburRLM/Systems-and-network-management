#!/bin/bash

# Direcció IP del router
ROUTER_IP="198.18.192.1"

# Usuari per acces de lectura/escriptura
READ_WRITE_USER="gsxAdmin"
# Contrasenya de autenticació per acces de lectura/escriptura
READ_WRITE_AUTH_PASS="aut85406112"
# Contrasenya de encriptació per acces de lectura/escriptura
READ_WRITE_PRIV_PASS="sec85406112"

# Llindar pel número de sol·licituds SNMP (SNMPv2-MIB::snmpInSetRequests y SNMPv2-MIB::snmpInGetRequests)
LLINDAR=10

# OID pel número de sol·licituds d'establiment SNMP
SET_REQUESTS_OID="SNMPv2-MIB::snmpInSetRequests.0"
# OID pel número de sol·licituds de consulta SNMP
GET_REQUESTS_OID="SNMPv2-MIB::snmpInGetRequests.0"


# Realitzar snmpgets per obtenir els valores actuals dels OIDs
set_requests=$(snmpget -v3 -u "$READ_WRITE_USER" -l authNoPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$ROUTER_IP" "$SET_REQUESTS_OID" | awk '{print $4}')
get_requests=$(snmpget -v3 -u "$READ_WRITE_USER" -l authNoPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$ROUTER_IP" "$GET_REQUESTS_OID" | awk '{print $4}')


# Comparar els valors obtinguts amb el umbral
if  [ -f "/tmp/valorsAntGet" ]; then
   valorsAntGet=$(cat /tmp/valorsAntGet)
   incrementGet=$(( get_requests - valorsAntGet ))
   valorsAntSet=$(cat /tmp/valorsAntSet)
   incrementSet=$(( set_requests - valorsAntSet ))
   if [ "$get_requests" -gt "$LLINDAR" ]; then
      logger -p user.warning -t GSX "AVÍS: el valor del $GET_REQUESTS_OID al router ha augmentat massa: $get_requests ($incrementGet)"
   fi
   if [ "$set_requests" -gt 0 ]; then
      # Enviar missatge al syslog local
      logger -p user.warning -t GSX "AVÍS: el valor del $SET_REQUESTS_OID al router ha augmentat massa: $set_requests ($incrementSet)"
   fi
fi

echo $get_requests > /tmp/valorsAntGet
echo $set_requests > /tmp/valorsAntSet
