#! /bin/bash

# Afegim PATH per poder executar comandes sense necessitat de sudo
PATH="$PATH:/usr/sbin/"

# Demanem privilegis per poder crear l'area de swap
if [[ $EUID -ne 0 ]] ; then
	echo "Necessitem privilegis per executar aquest script"
	exit 1
fi

# Comprovem si hi ha àrea de swap
if [[ -z $(swapon -s | grep /var/swap) ]] ; then
	echo "Creants fitxer de swap..."

	# Creem fitxer de 64 MB (4096k (midaBloc) x 16 (blocs) = 65536k = 64 MB)
	dd if=/dev/zero of=/var/swap bs=4096k count=16 &> /dev/null

	# Donem els permissos segurs a l'area de swap
	chmod 0600 /var/swap

	# Crear àrea swap
	mkswap /var/swap

	# Afegim àrea de swap al sistema
	swapon /var/swap
else
	echo "Fitxer de swap ja creat!"
fi

# Verificar que s'ha creat el fitxer de swap
echo "---------------------------"
echo "Fitxers de swap actius..."
swapon -s
echo "--------------------------"

echo "Memoria de swap total disponible..."
free -h
echo "-------------------------"

# Moduls previs al montatge de la nova imatge
modulsPre=$(lsmod)

# Montar fitxer .img
if [[ ! $(df -h | grep "loop") ]] ; then
	echo "Montant imatge memtest86..."
	mount -o loop /home/milax/Documents/GSX/lab12/memtest86-4.3.7-usb/memtest86-usb.img /mnt
fi

# Afegim l'entrada al /etc/fstab per manternir-ho quan es faci el boot del sistema
if ! grep -q "/var/swap" /etc/fstab; then
	echo "/var/swap   none    swap    defaults    0   0" >> /etc/fstab
        systemctl daemon-reload
fi


echo "Imatge memtest86 montada"
df -h | grep "loop"

# Moduls previs al montatge de la nova imatge
modulsAct=$(lsmod)

# Moduls nous instalats per la imatge memtest86
echo "--------------------------"
echo "Moduls nous (memtest86)..."

diff <(echo "$modulsPre") <(echo "$modulsAct") | grep '^>' | sed 's/^> //'
