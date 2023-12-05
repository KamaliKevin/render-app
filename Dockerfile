# Stage 1: Build assets with npm
FROM node:14 as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run production

# Stage 2: Build Laravel application
FROM composer:2 as composer
WORKDIR /app
COPY --from=build /app /app
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

FROM php:8.2-apache-buster as production

ENV APP_ENV=production
ENV APP_DEBUG=false

RUN docker-php-ext-configure opcache --enable-opcache && \
docker-php-ext-install pdo pdo_mysql
COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY --from=build /app /var/www/html
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY .env.prod /var/www/html/.env

RUN php artisan config:cache && \
php artisan route:cache && \
chmod 775 -R /var/www/html/storage/ && \
chown -R www-data:www-data /var/www/ && \
a2enmod rewrite
