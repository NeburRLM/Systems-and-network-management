#!/bin/bash

# Direcció IP del contenidor remot
REMOTE_IP="172.24.192.3"

# Usuari per acces de lectura
READ_USER="gsxViewer"
# Contrasenya d'autenticació per acces de lectura
READ_AUTH_PASS="aut85406112"

# Usuari per acces de lectura/escriptura
READ_WRITE_USER="gsxAdmin"
# Contrasenya de autenticació per acces de lectura/escriptura
READ_WRITE_AUTH_PASS="aut85406112"
# Contrasenya de encriptació per acces de lectura/escriptura
READ_WRITE_PRIV_PASS="sec85406112"

# Nom del arxiu de sortida
OUTPUT_FILE="sortida_snmp_remota_prac5.txt"

# Funció per executar les proves SNMP y guardar la sortida en el arxiu especificat
execute_snmp_tests() {
    echo "Executant proves SNMP a la direcció IP: $REMOTE_IP"
    echo "=============================================" >> "$OUTPUT_FILE"
    echo "Proves SNMP a la direcció IP: $REMOTE_IP" >> "$OUTPUT_FILE"
    snmpget -v 2c -c public $REMOTE_IP system.sysName.0 >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    echo "snmpwalk -v3 -u $READ_USER -l authNoPriv -a SHA -A $READ_AUTH_PASS $REMOTE_IP system" >> "$OUTPUT_FILE"
    snmpwalk -v3 -u $READ_USER -l authNoPriv -a SHA -A "$READ_AUTH_PASS" "$REMOTE_IP" system >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    echo "snmpwalk -v3 -u $READ_WRITE_USER -l authPriv -a SHA -A $READ_WRITE_AUTH_PASS -x DES -X $READ_WRITE_PRIV_PASS $REMOTE_IP hrSystem" >> "$OUTPUT_FILE"
    snmpwalk -v3 -u $READ_WRITE_USER -l authPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$REMOTE_IP" hrSystem >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    echo "snmptable -v3 -u $READ_USER -l authNoPriv -a SHA -A $READ_AUTH_PASS $REMOTE_IP UCD-SNMP-MIB::prTable" >> "$OUTPUT_FILE"
    snmptable -v3 -u $READ_USER -l authNoPriv -a SHA -A "$READ_AUTH_PASS" "$REMOTE_IP" UCD-SNMP-MIB::prTable >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    echo "snmptable -v3 -u $READ_WRITE_USER -l authPriv -a SHA -A $READ_WRITE_AUTH_PASS -x DES -X $READ_WRITE_PRIV_PASS $REMOTE_IP ucdavis.dskTable" >> "$OUTPUT_FILE"
    snmptable -v3 -u $READ_WRITE_USER -l authPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$REMOTE_IP" ucdavis.dskTable >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    echo "snmptable -v3 -u $READ_WRITE_USER -l authPriv -a SHA -A $READ_WRITE_AUTH_PASS -x DES -X $READ_WRITE_PRIV_PASS $REMOTE_IP ucdavis.laTable" >> "$OUTPUT_FILE"
    snmptable -v3 -u $READ_WRITE_USER -l authPriv -a SHA -A "$READ_WRITE_AUTH_PASS" -x DES -X "$READ_WRITE_PRIV_PASS" "$REMOTE_IP" ucdavis.laTable >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    echo "snmpget -v3 -u gsxViewer -l SecurityLevel -a SHA -A aut$IND $IP system.sysDescr.0" >> "$OUTPUT_FILE"
    snmpget -v3 -u gsxViewer -l authNoPriv -a SHA -A $READ_WRITE_AUTH_PASS $REMOTE_IP system.sysDescr.0 >> "$OUTPUT_FILE"
    echo "snmpget -v3 -u gsxAdmin -l SecurityLevel -a SHA -A aut$IND -x DES -X sec$IND $IP system.sysDescr.0" >> "$OUTPUT_FILE"
    snmpget -v3 -u gsxAdmin -l authPriv -a SHA -A $READ_WRITE_AUTH_PASS -x DES -X $READ_WRITE_PRIV_PASS $REMOTE_IP system.sysDescr.0 >> "$OUTPUT_FILE"
    echo "Proves SNMP completades. Verifica el arxiu '$OUTPUT_FILE' per veure els resultats."
    echo "=============================================" >> "$OUTPUT_FILE"
}

# Crida a la funció per executar les proves SNMP i guardar la sortida
execute_snmp_tests
