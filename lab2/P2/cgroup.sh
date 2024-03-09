#!/bin/bash

# Funció per obtenir la informació del procés
get_process_info() {
    local pid=$1
    local ppid=$(ps -o ppid= -p $pid)
    local command=$(ps -o comm= -p $pid)
    echo "pid: $pid, ppid: $ppid, command: $command"
}

# Obtenir el PID de la shell actual
current_pid=$$

# Mostrar informació per a la shell actual
echo "Informació del cgroup de la shell (pid: $current_pid):"
get_process_info $current_pid

# Obtindre la informació de processos pare recursivament fins arribar al primer procés del cgroup
while [ $current_pid -ne 1 ]; do
    current_pid=$(ps -o ppid= -p $current_pid)
    echo -e "\nInformació del procés pare (pid: $current_pid):"
    get_process_info $current_pid
done
