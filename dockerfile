FROM    ubuntu:20.04

RUN     apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade
RUN     DEBIAN_FRONTEND=noninteractive TZ=Europe/Amsterdam apt-get -y install apt-transport-https rsyslog postfix postfix-mysql apache2 php mysql-client curl

RUN     cd /usr/src \
        && for pkg in "core" "webapp"; do \
           curl -s https://download.kopano.io/community/$pkg%3A/$( \
           curl -s https://download.kopano.io/community/$pkg%3A/ | sed 's/</\n/g' | grep 'a href' | grep 'Ubuntu_20.04' | cut -d'>' -f2 \
           ) | tar xzvf - \
        && apt-get -y install ./$pkg-*/*.deb \
        && rm -rf ./$pkg-* \
        ; done

RUN     cd /usr/src \
        && for PKG in "z-push-common" "z-push-config-apache" "z-push-backend-kopano" "z-push-ipc-sharedmemory" "z-push-autodiscover"; do \
           DEB=$(curl -s https://download.kopano.io/zhub/z-push%3A/final/Ubuntu_20.04/all/ | sed 's/</\n/g' | grep 'a href' | grep $PKG | cut -d'>' -f2) \
        && curl -s https://download.kopano.io/zhub/z-push%3A/final/Ubuntu_20.04/all/$DEB --output $DEB \
        ; done \
        && apt-get -y install ./*.deb \
        && rm -f ./*.deb \
        && chown -R www-data:www-data /var/lib/z-push /var/log/z-push

RUN     echo "\n#virtual_mailbox_domains = example.com\nvirtual_mailbox_maps = mysql:/etc/postfix/mysql-users.cf\nvirtual_transport = lmtp:127.0.0.1:2003" >>/etc/postfix/main.cf
RUN     /usr/sbin/a2enmod ssl \
        && sed -i -e 's/\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/\/etc\/apache2\/ssl\/default.crt/g' -e 's/\/etc\/ssl\/private\/ssl-cert-snakeoil.key/\/etc\/apache2\/ssl\/default.key/g' /etc/apache2/sites-available/default-ssl.conf \
        && ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf \
        && sed -i '2 i Alias \/Microsoft-Server-ActiveSync \/usr\/share\/z-push\/index.php' /etc/apache2/sites-enabled/kopano-webapp.conf \
        && echo '<html><head><meta http-equiv="refresh" content="0;url=./webapp" /></head></html>' >/var/www/html/index.html

ENV     SRVCFG_MYSQL_HOST="" \
        SRVCFG_MYSQL_PORT="" \
        SRVCFG_MYSQL_USER="" \
        SRVCFG_MYSQL_PASSWORD="" \
        SRVCFG_MYSQL_DATABASE="" \
        POSTFIX_VIRTUAL_MAILBOX_DOMAINS=""

EXPOSE  25 80 443

ADD     run.sh /run.sh
RUN     chmod +x /run.sh
CMD     /run.sh
