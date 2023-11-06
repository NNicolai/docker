FROM php:8.1-apache

RUN apt-get update                                         \
    && apt-get install -y zlib1g-dev      \
    && apt-get install -y netcat-traditional git zip unzip jq          \
    && apt-get install -y libzip-dev libpng-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug-3.1.4                      \
    && pecl install zip
    
RUN docker-php-ext-enable xdebug zip        \
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
    && cp ${PHP_INI_PATH}-development $PHP_INI_PATH                                                                    \
    && echo "xdebug.mode = debug"                       >> $PHP_INI_PATH                                               \
    && echo "xdebug.start_with_request = yes"           >> $PHP_INI_PATH                                               \
    && echo "xdebug.client_host = host.docker.internal" >> $PHP_INI_PATH                                               \
    && echo "xdebug.client_port = 9000"                 >> $PHP_INI_PATH                                               \
    && echo "xdebug.discover_client_host = off"         >> $PHP_INI_PATH                                               \
    && echo "xdebug.log_level = 0"                      >> $PHP_INI_PATH                                               \
    && sed -i 's/memory_limit = 128M/memory_limit = 2048M/' $PHP_INI_PATH                                              \
    && sed -i 's/error_reporting = E_ALL/error_reporting = E_ALL \& ~E_DEPRECATED/' $PHP_INI_PATH

# Have to set LimitRequestLine before VirtualHost
RUN [ ! -z ${APACHE_CONFIG} ] && echo "LimitRequestLine 512000" >> $APACHE_CONFIG

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
 && mv composer.phar /usr/local/bin/composer

EXPOSE 80
