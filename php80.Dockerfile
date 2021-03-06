FROM php:8.0-apache

RUN apt-get update                                         \
    && apt-get install -y libmemcached-dev zlib1g-dev      \
    && apt-get install -y netcat git zip unzip             \
    && apt-get install -y libzip-dev libpng-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install memcached-3.1.5                      \
    && pecl install xdebug-3.0.3                      \
    && pecl install zip-1.19.3
    
RUN docker-php-ext-enable memcached xdebug zip        \
    && docker-php-ext-configure gd                    \
    && docker-php-ext-configure intl                  \
    && docker-php-ext-install pdo pdo_mysql bcmath gd intl

WORKDIR /var/www/html

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
ENV PHP_INI_PATH /usr/local/etc/php/php.ini

RUN    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf                      \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && cd /etc/apache2/mods-enabled && ln -s ../mods-available/rewrite.load ./                                         \
    && cp ${PHP_INI_PATH}-development $PHP_INI_PATH                                                                    \
    && echo "xdebug.mode = debug"                       >> $PHP_INI_PATH                                               \
    && echo "xdebug.start_with_request = yes"           >> $PHP_INI_PATH                                               \
    && echo "xdebug.client_host = host.docker.internal" >> $PHP_INI_PATH                                               \
    && echo "xdebug.client_port = 9000"                 >> $PHP_INI_PATH                                               \
    && echo "xdebug.discover_client_host = off"         >> $PHP_INI_PATH                                               \
    && echo "xdebug.log_level = 0"                      >> $PHP_INI_PATH

RUN sed -i 's/memory_limit = 128M/memory_limit = 2048M/' $PHP_INI_PATH

EXPOSE 80
