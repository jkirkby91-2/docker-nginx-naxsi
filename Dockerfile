FROM jkirkby91/ubuntusrvbase:latest

MAINTAINER James Kirkby <jkirkby91@gmail.com>

RUN apt-get update && \
apt-get upgrade -y && \
apt-get install fail2ban supervisor libpcre3-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev libssl-dev unzip wget make \
  libgoogle-perftools-dev google-perftools jq -y --fix-missing && \
apt-get remove --purge -y software-properties-common build-essential && \
apt-get autoremove -y && \
apt-get clean && \
apt-get autoclean && \
echo -n > /var/lib/apt/extended_states && \
rm -rf /var/lib/apt/lists/* && \
rm -rf /usr/share/man/?? && \
rm -rf /usr/share/man/??_*

RUN mkdir /tmp/ngxbuild

RUN cd /tmp/ngxbuild

RUN wget -q http://nginx.org/download/nginx-1.11.9.tar.gz

RUN wget -q https://github.com/nbs-system/naxsi/archive/0.55.2.tar.gz

RUN tar xzf nginx-1.11.9.tar.gz

RUN tar xzf 0.55.2.tar.gz

WORKDIR  nginx-1.11.9

RUN groupadd -r nginx && useradd -r -g nginx nginx

RUN ./configure \
  --with-pcre \
  --with-ipv6 \
  --user=nginx \
  --group=nginx \
  --with-stream \
  --with-file-aio \
  --with-poll_module \
  --with-http_v2_module \
  --with-http_ssl_module \
  --with-stream_ssl_module \
  --with-http_realip_module \
  --pid-path=/run/nginx.pid \
  --prefix=/usr/local/nginx \
  --without-http_uwsgi_module \
  --with-stream_realip_module \
  --pid-path=/var/run/nginx.pid \
  --with-http_gzip_static_module \
  --with-google_perftools_module \
  --lock-path=/var/lock/nginx.lock \
  --conf-path=/etc/nginx/nginx.conf \
  --sbin-path=/usr/local/sbin/nginx \
  --lock-path=/run/lock/subsys/nginx \
  --add-module=../naxsi-0.55.2/naxsi_src/ \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --without-mail_pop3_module \
  --without-mail_smtp_module \
  --without-mail_imap_module \
  --without-http_scgi_module \
  --prefix=/usr && \
  make -j 4 && \
  make install && \
  mkdir -p /var/lib/nginx/{body,proxy,fastcgi}

RUN cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

RUN touch /etc/fail2ban/filter.d/nginx-req-limit.conf

COPY confs/nginx-req-limit.conf /etc/fail2ban/filter.d/nginx-req-limit.conf

COPY confs/apparmor/nginx.conf /etc/apparmor/nginx.conf

COPY confs/jail1.conf /tmp/jail.conf

RUN cat /tmp/jail.conf >> /etc/fail2ban/jail.local

RUN rm /tmp/jail.conf

COPY confs/nginx-naxsi.conf /etc/fail2ban/filter.d/nginx-naxsi.conf

COPY confs/jail2.conf /tmp/jail.conf

RUN cat /tmp/jail.conf >> /etc/fail2ban/jail.conf

COPY confs/supervisord.conf /etc/supervisord.conf

RUN curl -O /etc/nginx/sites-avalible/rp.conf -sL https://gist.githubusercontent.com/jkirkby91/e6de5882f0e6df8e42adf1fb6f8e78b6/raw/5aafd3b95a2ac3b9617fad38adf593b7f6d44a76/nginx-ssl-loadbalancer-proxy-naxsi.conf

COPY start.sh /start.sh

RUN chmod 777 /start.sh

RUN chown -Rf www-data:www-data /srv

RUN chmod -Rf 644 /srv

RUN touch /var/log/nginx/error.log

RUN touch /var/log/nginx/access.log

CMD ["/bin/bash", "/start.sh"]
