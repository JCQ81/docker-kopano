#!/bin/bash

if [ -d "/usr/share/conf" ]; then
  dirs=(apache2 postfix kopano)
  for dir in ${dirs[@]}; do
    if [ ! -d /usr/share/conf/$dir ]; then
      cp -rp /etc/$dir /usr/share/conf/
    fi
    rm -rf /etc/$dir
    ln -s /usr/share/conf/$dir /etc/$dir
  done
fi

if [ ! -d "/etc/apache2/ssl" ]; then
  mkdir -p /etc/apache2/ssl
  cd /etc/apache2/ssl
  openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NL/ST=NH/L=Amsterdam/O=ACME/CN=example.com" -keyout default.key -out default.crt
fi

for CPR in "SRVCFG" "POSTFIX"; do
  if [ $CPR == "SRVCFG" ]; then CONF="kopano/server.cfg"; else  CONF="postfix/main.cf"; fi
  for ENV in $(printenv | grep -e "^${CPR}_" | cut -d= -f1); do
    if [ ! -z ${!ENV} ]; then
      VAR=$(echo ${ENV,,} | cut -d_ -f2-)
      sed -i "/^#$VAR/c$VAR = ${!ENV}" /etc/$CONF
    fi
  done
done

MYSQL_DB=$(cat /etc/kopano/server.cfg | grep mysql_database | tr -d ' ' | cut -d= -f2)
MYSQL_USER=$(cat /etc/kopano/server.cfg | grep mysql_user | tr -d ' ' | cut -d= -f2)
MYSQL_PASS=$(cat /etc/kopano/server.cfg | grep mysql_password | tr -d ' ' | cut -d= -f2)
MYSQL_HOST=$(getent hosts $(cat /etc/kopano/server.cfg | grep mysql_host | tr -d ' ' | cut -d= -f2) | cut -d' ' -f1)

echo "user = $MYSQL_USER" >/etc/postfix/mysql-users.cf
echo "password = $MYSQL_PASS" >>/etc/postfix/mysql-users.cf
echo "hosts = $MYSQL_HOST" >>/etc/postfix/mysql-users.cf
echo "dbname = $MYSQL_DB" >>/etc/postfix/mysql-users.cf
echo "query = select value from objectproperty where objectid=(select objectid from objectproperty where value='%s' limit 1) and propname='loginname';" >>/etc/postfix/mysql-users.cf

echo -n "Waiting for mysql ..."
while ! mysqladmin ping -s -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS; do
  sleep 5
  echo -n "."
done

cp /etc/resolv.conf /var/spool/postfix/etc/
/usr/sbin/rsyslogd
/usr/sbin/kopano-dagent -l &
/usr/sbin/kopano-spooler &
/usr/sbin/postfix start
/usr/sbin/apachectl start
/usr/sbin/kopano-server
