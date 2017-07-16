FROM tutum/apache-php

RUN apt-get update
RUN apt-get install -y unzip libaio-dev php5-dev
RUN apt-get clean -y

# SSH Service
RUN apt-get install -y openssh-server 
EXPOSE 22


# Oracle instantclient
ADD instantclient-basic-linux.x64-12.1.0.2.0.zip /tmp/
ADD instantclient-sdk-linux.x64-12.1.0.2.0.zip /tmp/
ADD instantclient-sqlplus-linux.x64-12.1.0.2.0.zip /tmp/

RUN unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -d /usr/local/
RUN mkdir /usr/local/instantclient
RUN ln -s /usr/local/instantclient_12_1 /usr/local/instantclient/lib
RUN ln -s /usr/local/instantclient/lib/libclntsh.so.12.1 /usr/local/instantclient/lib/libclntsh.so
RUN ln -s /usr/local/instantclient/lib/sqlplus /usr/bin/sqlplus
RUN echo 'instantclient,/usr/local/instantclient/lib' | pecl install oci8-1.4.10
RUN echo "extension=oci8.so" > /etc/php5/apache2/conf.d/30-oci8.ini

# Build PHP PDO-OCI extension
RUN pecl channel-update pear.php.net && \
    cd /tmp && \
    pecl download pdo_oci && \
    tar xvf /tmp/PDO_OCI-1.0.tgz -C /tmp && \
    sed 's/function_entry/zend_function_entry/' -i /tmp/PDO_OCI-1.0/pdo_oci.c && \
    sed 's/10.1/12.1/' -i /tmp/PDO_OCI-1.0/config.m4 && \
    cd /tmp/PDO_OCI-1.0 && \
    phpize && \
    ./configure --with-pdo-oci=/usr/local/instantclient && \
    make install



RUN echo "<?php echo phpinfo(); ?>" > /app/index.php

