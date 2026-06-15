# final-ossec2

## Instrucciones

Para poder ejecutar este script, deberá contar con:

1. FreeIPA
2. Credenciales para el usuario (admin)
3. Credenciales para los usarios del grupo (webmasters)


## Ejecución:

* El script debe ejecutarse en el sistema ipa01.
* Como el usuario root via (SSH)

  

```sh
kinit admin

export LANG=en_US.UTF-8

export IP_CLIENT1=192.168.1.1 IP_CLIENT2=192.168.1.2

 ```

```sh
 ./test.sh
```
