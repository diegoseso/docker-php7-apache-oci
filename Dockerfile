FROM debian:latest
MAINTAINER Diego Sosa<diego.venezuela@gmail.com>

# Install build dependencies
ENV DEBIAN_FRONTEND noninteractive

# SSH Service
RUN apt-get update && \
    apt-get install -y openssh-server 
EXPOSE 22

RUN apt-get update && \
    apt-get install -y memcached unzip php php-cli php-dev php-xdebug php-pear php-memcache build-essential libaio1 re2c sqlite sqlite3 && \
    # php-sqlite
    ln -s /usr/include/php /usr/include/php

# Install Oracle Instant Client Basic and SDK
ADD instantclient-basic-linux.x64-12.1.0.2.0.zip /tmp/basic.zip
ADD instantclient-sdk-linux.x64-12.1.0.2.0.zip /tmp/sdk.zip
RUN mkdir -p /opt/oracle/instantclient && \
    unzip -q /tmp/basic.zip -d /opt/oracle && \
    mv /opt/oracle/instantclient_12_1 /opt/oracle/instantclient/lib && \
    unzip -q /tmp/sdk.zip -d /opt/oracle && \
    mv /opt/oracle/instantclient_12_1/sdk/include /opt/oracle/instantclient/include && \
    ln -s /opt/oracle/instantclient/lib/libclntsh.so.12.1 /opt/oracle/instantclient/lib/libclntsh.so && \
    ln -s /opt/oracle/instantclient/lib/libocci.so.12.1 /opt/oracle/instantclient/lib/libocci.so && \
    echo /opt/oracle/instantclient/lib >> /etc/ld.so.conf && \
    ldconfig

# Install PHP OCI8 extension
RUN echo 'instantclient,/opt/oracle/instantclient/lib' | pecl install oci8
ADD oci8.ini /etc/php/conf.d/oci8.ini
ADD oci8-test.php /tmp/oci8-test.php
RUN php /tmp/oci8-test.php
ADD php-7.3.19 /tmp/php-7.3.19
WORKDIR /tmp/php-7.3.19/ext/pdo_oci
RUN phpize
RUN ./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient/lib
RUN make && make install

COPY libxl-lin-3.9.1.0.tar.gz /tmp/libxl-lin-3.9.1.0.tar.gz
ADD php_excel-php7.zip /tmp/php_excel-php7.zip
WORKDIR /tmp
RUN tar xvfz libxl-lin-3.9.1.0.tar.gz
RUN unzip php_excel-php7.zip
RUN apt-get install -y libxml2-dev && cp -R /usr/include/libxml2/libxml/ /usr/include/
WORKDIR /tmp/php_excel-php7
RUN phpize
RUN ./configure --with-libxl-incdir=../libxl-3.9.1.0/include_c --with-libxl-libdir=../libxl-3.9.1.0/lib64
RUN make && make install

ADD excel.ini /etc/php/apache2/conf.d/excel.ini
ADD xdebug.ini /etc/php/apache2/conf.d/xdebug.ini

VOLUME ["/var/www/html"]
