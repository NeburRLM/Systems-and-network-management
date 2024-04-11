; file "intranet.gsx.db"

$TTL 604800
@       IN      SOA     intranet.gsx.     root.ns.intranet.gsx. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Minimum TTL
;

; Definición del servidor DNS para la zona
@       IN      NS      ns.dmz.gsx.   ; Definir el servidor DNS para la zona
ns      IN      A       198.18.207.254    ; Registro A para el nombre de host "ns"

; Registros de recursos para los nombres en la intranet
server  IN      CNAME   ns                ; Registro CNAME para "server"
www     IN      CNAME   ns                ; Registro CNAME para "www"
dhcp	IN	A	172.24.255.254
router	IN	A	172.24.192.1
