#!/bin/bash

# Definir els routers y les IPs pels enllaços
# IP base
base_ip="10.192."

# Funció per crear enllaçes veth y assignar IPs
create_veth_link() {
    local router1=$1
    local router2=$2
    local ip1=$3
    local ip2=$4
    local link_name=$5

    # Crear enllaç veth
    ip link add ${link_name}_veth1 type veth peer name ${link_name}_veth2

    # Obtenir PIDs dels contenidors
    pid_r1=$(docker inspect --format '{{.State.Pid}}' $router1)
    pid_r2=$(docker inspect --format '{{.State.Pid}}' $router2)

    # Assignar enllaços als namespaces dels contenidors
    ip link set netns $pid_r1 dev ${link_name}_veth1
    ip link set netns $pid_r2 dev ${link_name}_veth2

    # Assignar direccions IP dins dels contenidors
    nsenter -t $pid_r1 -n ip addr add $ip1 dev ${link_name}_veth1
    nsenter -t $pid_r1 -n ip link set dev ${link_name}_veth1 up

    nsenter -t $pid_r2 -n ip addr add $ip2 dev ${link_name}_veth2
    nsenter -t $pid_r2 -n ip link set dev ${link_name}_veth2 up

    echo "Enllaç configurat entre $router1 ($ip1) i $router2 ($ip2) utilitzant $link_name"
}


# Bucle per a crear enllaços veth
for (( i=1; i<=4; i++ )); do
    router1="R$i"
    router2="R$((i%4+1))"
    v1="$i.1"
    v2="$i.2"
    concatIp1="${base_ip}${v1}/30"
    concatIp2="${base_ip}${v2}/30"
    create_veth_link $router1 $router2 $concatIp1 $concatIp2 "link$i"
done

echo "Tots els enllaços veth han sigut creats i configurats."
