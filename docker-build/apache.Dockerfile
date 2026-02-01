ARG DEBIAN_VERSION=trixie
ARG DEBIAN_FRONTEND=noninteractive

FROM debian:${DEBIAN_VERSION}

ARG DEBIAN_FRONTEND
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  apache2 \
  apache2-utils \
  libapache2-mod-fcgid \
  php-fpm \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN a2dismod mpm_prefork php* || true
RUN a2enmod mpm_event proxy proxy_fcgi setenvif rewrite
RUN a2enconf php*-fpm

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN sed -i 's/^Timeout .*/Timeout 36000/' /etc/apache2/apache2.conf && \
  sed -i 's/^max_execution_time = .*/max_execution_time = 36000/' /etc/php/*/fpm/php.ini && \
  sed -i 's/^;request_terminate_timeout = .*/request_terminate_timeout = 36000/' /etc/php/*/fpm/pool.d/www.conf

EXPOSE 80

CMD ["sh", "-c", "service $(basename /etc/init.d/php*-fpm) start && apachectl -D FOREGROUND"]
