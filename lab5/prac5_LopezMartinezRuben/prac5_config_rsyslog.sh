#!/bin/bash

# Direcció IP del servidor
SERVER_IP="198.18.192.3"

# Verificar el hostname per determinar si és el servidor o un altre contenidor
if [ "$HOSTNAME" == "server" ]; then
    # Configurar el servidor syslog
    echo "Configurant el servidor syslog ..."

    # Verificar si les línies ja estan descomentades a /etc/rsyslog.conf
    if ! grep -q "^module(load=\"imudp\")" /etc/rsyslog.conf; then
        # Descomentar la linia a /etc/rsyslog.conf per permetre la recepció de syslog a UDP 514
        sed -i '/^#module(load="imudp")/s/^#//' /etc/rsyslog.conf
    fi
    if ! grep -q "^input(type=\"imudp\" port=\"514\")" /etc/rsyslog.conf; then
        # Descomentar la linia a /etc/rsyslog.conf per permetre la recepció de syslog a UDP 514
        sed -i '/^#input(type="imudp" port="514")/s/^#//' /etc/rsyslog.conf
    fi

    # Crea el arxiu /etc/rsyslog.d/10-remot.conf si no existeix
    if [ ! -e "/etc/rsyslog.d/10-remot.conf" ]; then
        echo '$template GuardaRemots, "/var/log/remots/%HOSTNAME%/%timegenerated:1:10:date-rfc3339%"' | tee /etc/rsyslog.d/10-remot.conf >/dev/null
        echo ':source, !isequal, "localhost" -?GuardaRemots' | tee -a /etc/rsyslog.d/10-remot.conf >/dev/null
    fi

    # Reinicia el servei rsyslog
    service rsyslog restart
    echo "Servidor syslog configurat correctament."

else
    # Configurar els altres contenidors syslog
    echo "Configurant el contenidor ..."

    # Verificar si la configuració ja està present a /etc/rsyslog.d/90-remot.conf
    if ! grep -q "user.* @$SERVER_IP:514" /etc/rsyslog.d/90-remot.conf 2>/dev/null; then
        # Agregar la configuració al arxiu /etc/rsyslog.d/90-remot.conf
        echo "user.* @$SERVER_IP:514" | tee -a /etc/rsyslog.d/90-remot.conf >/dev/null
    fi

    # Reinicia el servei rsyslog
    service rsyslog restart
    echo "Contenidor configurat correctament."
fi
