FROM php:8.1-apache

RUN apt-get update                                         \
    && apt-get install -y libmemcached-dev zlib1g-dev      \
    && apt-get install -y netcat git zip unzip             \
    && apt-get install -y libzip-dev libpng-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install memcached-3.1.5                      \
    && pecl install xdebug-3.1.4                      \
    && pecl install zip
    
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
    && cp ${PHP_INI_PATH}-production $PHP_INI_PATH
    
EXPOSE 80
