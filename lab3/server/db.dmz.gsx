 ; file "dmz.gsx.db"

$TTL 604800
@       IN      SOA     ns.dmz.gsx.     root.ns.dmz.gsx. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Minimum TTL
;

; Definición del servidor DNS para la zona
@       IN      NS      ns.dmz.gsx.   ; Definir el servidor DNS para la zona
ns      IN      A       198.18.207.254
; Registros CNAME para server y www
server  IN      CNAME   ns   ; Apunta al nombre de servidor correcto
www     IN      CNAME   ns      ; Apunta al nombre de host correcto
router	IN	A	198.18.192.1

