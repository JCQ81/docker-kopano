## docker-kopano

An all-in-one kopano container running a minimal setup of Kopano consisting of Kopano-Server, Kopano-WebApp and Z-Push for ActiveSync. Additionally it runs services required for a fully functional environment such as Apache2 as webserver and Postfix as MTA. The only additional external requirement is an MySQL server.

The image is also available on docker hub: https://hub.docker.com/r/jcq81/docker-kopano

**Quick setup (docker-compose with MySQL)**

    git clone jcq81/docker-kopano
    cd docker-kopano
    docker build -t jcq81/docker-kopano .
    docker-compose up -d

Adding a user:

    docker exec -t kopano kopano-admin -c test -p testing123 -f 'Test' -e test@example.com

This setup published both ports 80 and 443 with an automatically created self signed certificate. When publishing this setup to the internet it is (obviously) highly recommended to not publish any insecure access by e.g. using a reverse proxy like Apache2, NGINX or HAProxy providing secure access using a certificate, and internally forwarding to port 80.

**Manual setup**

For a manual setup all the environment variables can be used as defined in the docker-compose.yml file:

    docker run -d --name kopano \
    -e SRVCFG_MYSQL_HOST=mysql.example.local \
    -e SRVCFG_MYSQL_DATABASE=kopano \
    -e SRVCFG_MYSQL_USER=kopano \
    -e SRVCFG_MYSQL_PASS=My@weS0mePaSS \
    -e POSTFIX_VIRTUAL_MAILBOX_DOMAINS=example.com \
    jcq81/docker-kopano

**Advanced setup**

For a more detailed configuration like being able to configure your own certificate just use a volume. , edit the configuration manually and restart the container.

    docker volume create kopano-conf
    docker run -d --name kopano \
    -v kopano-conf:/usr/share/conf \
    jcq81/docker-kopano

**Brave browser**

When using Brave browser disable anti-fingerprint:
https://forum.kopano.io/topic/4006/solved-fingerprint-issue-with-brave/2
