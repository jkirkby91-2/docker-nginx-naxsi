#!/bin/bash

#generate ssl keys for container
openssl dhparam -out /srv/ssl/dhparam.pem 2048

#generate ssl keys for container
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /srv/ssl/nginx-selfsigned.key -out /srv/ssl/nginx-selfsigned.crt \
    -subj "/C=UK/ST=London/L=London/O=Dis/CN=localhost" \
    -keyout /srv/ssl/nginx-selfsigned.key -out /srv/ssl/nginx-selfsigned.crt > /dev/null

# Fire up supervisord
/usr/bin/supervisord -n -c /etc/supervisord.conf
