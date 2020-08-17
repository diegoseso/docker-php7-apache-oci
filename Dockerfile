FROM debian:latest
MAINTAINER Diego Sosa<diego.venezuela@gmail.com>

# Install build dependencies
ENV DEBIAN_FRONTEND noninteractive

# SSH Service
RUN apt-get update && \
    apt-get install -y openssh-server 
EXPOSE 22

RUN apt-get update && \
    apt-get install -y memcached unzip curl php php-cli php-curl php-dev php-xdebug php-pear php-memcache build-essential libaio1 re2c sqlite sqlite3 php-sqlite3

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
ADD pdo_oci /tmp/pdo_oci
WORKDIR /tmp/pdo_oci
RUN phpize
RUN ./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient/lib,12.1
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

ADD excel.ini /etc/php/7.3/mods-available/excel.ini
ADD oci8.ini /etc/php/7.3/mods-available/oci8.ini
ADD pdo_oci.ini /etc/php/7.3/mods-available/pdo_oci.ini

WORKDIR /etc/php/apache2/conf.d
RUN ln -s /etc/php/7.3/mods-available/excel.ini /etc/php/7.3/apache2/conf.d/20-excel.ini
RUN ln -s /etc/php/7.3/mods-available/oci8.ini /etc/php/7.3/apache2/conf.d/20-oci8.ini
RUN ln -s /etc/php/7.3/mods-available/pdo_oci.ini /etc/php/7.3/apache2/conf.d/20-pdo_oci.ini
RUN sed -i -e 's/max_execution_time = 30/max_execution_time = 0/g' /etc/php/7.3/apache2/php.ini

VOLUME ["/var/www/html"]
