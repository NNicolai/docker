FROM php:8.0-apache

RUN apt-get update                                         \
    && apt-get install -y libmemcached-dev zlib1g-dev      \
    && apt-get install -y netcat git zip unzip jq          \
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
ENV APACHE_CONFIG /etc/apache2/apache2.conf

RUN    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf                      \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && cd /etc/apache2/mods-enabled && ln -s ../mods-available/rewrite.load ./                                         \
    && cp ${PHP_INI_PATH}-production $PHP_INI_PATH                                                                     \
    && sed -i 's/memory_limit = 128M/memory_limit = 2048M/' $PHP_INI_PATH

RUN [ ! -z ${APACHE_CONFIG} ] && echo "LimitRequestLine 65536" >> $APACHE_CONFIG

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php \
 && php -r "unlink('composer-setup.php');" \
 && mv composer.phar /usr/local/bin/composer

EXPOSE 80
