#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"


if [ -z "$IP_CLIENT1" -o -z "IP_CLIENT2" ]
then
 echo "Debe definir las variables: IP_CLIENT1 e IP_CLIENT2"
 echo "Ejemplo: export IP_CLIENT1=192.168.1.1 IP_CLIENT2=192.168.1.2"
 exit 1
fi

function replica() {
  ipa server-find
  ipa-replica-manage list
}

function accounts() {

if [ -z $1 ]
then
 echo "SYNTAX: $0 $1 accounts all|group_name"
 exit 2
fi
if [ "$1" = "all" ]
then
 groups="webmasters itadmins itoperators"
else
 groups="$1"
fi

echo "**************************"
echo "Accounts and Groups"
echo "**************************"
for group in ${groups}
do
 echo "${group}"
 echo "++++++++++++++++++++++"
 ipa group-show ${group}
 if [ $? -eq 0 ]
 then
   echo "Exists ${group} = OK"
 else
   echo "Exists ${group} = FAILED"
 fi
 members=$(ipa group-show ${group}|grep 'Member users:'|cut -d: -f2|tr -d ",")
 members_managers=$(ipa group-show ${group}|grep 'Membership managed by'|cut -d: -f2|tr -d ",")
 #echo "${members}"
 if [ ! -z "${members}" ]
 then
  echo "Members Info"
  for member in ${members}
  do
   echo "==> ${member} - $(ipa user-show ${member}|grep -i 'Login shell'|cut -d: -f2|xargs)"
  done
 else
  echo "No members"
  echo "Members ${group} = FAILED"
 fi
 if [ ! -z "${members_managers}" ]
 then
  echo "Members Managers"
  for manager in ${members_managers}
  do
   echo "==> ${manager} "
  done
 else
  echo "No managers"
  echo "Managers ${group} = FAILED"
 fi
done

}

function grade() {
 COMMAND=$1
 if [ "$2" == "nonull" ]
 then
  ${COMMAND}
 else
  ${COMMAND} &>/dev/null
 fi
 test $? -eq 0  && echo -e "${GREEN}OK${ENDCOLOR}" && return 0 || echo -e "${RED}FAILED${ENDCOLOR}" && return 1
}

echo "Obtener Replica"
echo -n "Replicas 2 : "
grade "[ $(ipa-replica-manage list|wc -l) -eq 2 ]"

echo "Grupos"
echo "**************"
for GROUP in webmasters itadmins itoperators
do
 echo -n "${GROUP}: "
 grade "ipa group-show ${GROUP}"
done


echo "Validar acceso para usuario (admin) a client1 ($IP_CLIENT1)"
echo "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT1} uptime"
grade "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT1} uptime" nonull

echo "Validar acceso para usuario (admin) a client2 ($IP_CLIENT2)"
echo "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT2} uptime"
grade "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT2} uptime" nonull

echo "Validar existencia de Grupo de Hosts webservers"
echo -n "webservers: "
grade "ipa hostgroup-show webservers"

echo "Obtener equipos miembros"
member_hosts=$(ipa hostgroup-show WebServers 2>/dev/null|grep -i 'Member hosts:' |cut -d: -f2|xargs|tr -d ',')
if [ -z "${member_hosts}" -a $? -eq 0 ]
then
 echo "Contiene Hosts: FAILED"
else
  HOST_LIST=true
  for member_host in $member_hosts
  do
    echo -e "Host: ${member_host} - ${GREEN}OK${ENDCOLOR}"

  done
fi
echo "Obtener usuarios miembros de webmasters"
ipa group-show webmasters &>/dev/null
if [ $? -eq 0 ]
then
 member_users=$(ipa group-show webmasters |grep -i 'Member users:' |cut -d: -f2|xargs|tr -d ',')
if [ -z "${member_users}" ]
then
 echo -e  "Contiene Usuarios: ${RED}FAILED${ENDCOLOR}"
else
  HOST_USERS=true
  for member_user in $member_users
  do
    echo -e "User: ${member_user} - ${GREEN}OK${ENDCOLOR}"
  done
fi

else
 echo "webmasters Group: FAILED"
fi

echo "Validar acceso con usuarios de WebMasters a WebServers RANDOM User | RANDOM Host"
if [ "$HOST_USERS" == "true" -a "$HOST_LIST" == "true" ]
then
 echo "Usuarios y Hosts a validar"
 for usuario in $(shuf -e $member_users -n1 )
 do
  echo "Validando acceso de: ** (${usuario}) **"
  for host in $(shuf -e $member_hosts -n1 )
  do
    echo -e "\t --> a host: ${host}"
    echo "ssh  -o ConnectTimeout=10 ${usuario}@${host} uptime"
    grade "ssh  -o ConnectTimeout=10 ${usuario}@${host} uptime" nonull
  done
 done
else
 echo "No miembros en Grupo de Usuario y/o Grupo de Hosts: FAILED"
fi

echo "Validar sudo para (admin) sin password"
echo "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT1} sudo hostname"
grade "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT1} sudo hostname"
echo "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT2} sudo hostname"
grade "ssh  -o ConnectTimeout=10 admin@${IP_CLIENT2} sudo hostname"

echo "Validar sudo para un usuario aleatorio de WebMasters en Host Aleatorio de WebServer"
if [ "$HOST_USERS" == "true" -a "$HOST_LIST" == "true" ]
then
 echo "Usuarios y Hosts a validar"
 for usuario in $(shuf -e $member_users -n1 )
 do
  echo "Validando acceso de: ** (${usuario}) **"
  for host in $(shuf -e $member_hosts -n2 )
  do
    echo -e "\t --> a host: ${host}"
    echo "ssh  -o ConnectTimeout=10 ${usuario}@${host} sudo -l"
    grade "ssh  -o ConnectTimeout=10 ${usuario}@${host} sudo -l" nonull
  done
 done
else
 echo "No miembros en Grupo de Usuario y/o Grupo de Hosts: FAILED"
fi

