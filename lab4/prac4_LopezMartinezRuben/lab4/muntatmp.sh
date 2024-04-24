#!/bin/bash

#Crear un tmpfs de 100 megabytes
mkdir -p /empresa/usuaris/$USER/tmp

# Montar todos los sistemas de archivos en /etc/fstab
mount /empresa/usuaris/$USER/tmp

