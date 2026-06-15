# final-ossec2

## Instrucciones

Para poder ejecutar este script, deberá contar con:

0. Clonar este repositorio
1. FreeIPA
2. Credenciales para el usuario (admin)
3. Credenciales para los usarios del grupo (webmasters)



## Ejecución:

* El script debe ejecutarse en el sistema ipa01.
* Como el usuario root via (SSH)

  

```sh
kinit admin

export IP_CLIENT1=192.168.1.1 IP_CLIENT2=192.168.1.2

```

Debe agregar la llave de SSH del usuario root al usuario admin de su IdM. Si no tiene una llave, debe de crearla y agregar la configuración adecuada.

```sh
 ./test.sh
```
