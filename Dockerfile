FROM azzazkhan/laravel:fpm AS composer

WORKDIR /var/www

COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --prefer-dist --no-autoloader --no-scripts

# Frontend asset bundling

FROM azzazkhan/laravel:fpm AS yarn

ARG VITE_APP_NAME
ARG VITE_APP_DOMAIN
ARG VITE_APP_URL
ARG VITE_API_DOMAIN
ARG VITE_API_URL

WORKDIR /var/www

COPY --chown=www-data:www-data package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Only copy minimum-required files for asset bundling
COPY --chown=www-data:www-data --from=composer /var/www/vendor ./vendor
COPY --chown=www-data:www-data tsconfig.json vite.config.ts ./
COPY --chown=www-data:www-data resources ./resources

RUN rm -rf public/build bootstrap/ssr \
    && yarn run build

# Base application

FROM azzazkhan/laravel:fpm

COPY --chown=www-data:www-data . .

COPY --chown=www-data:www-data --from=composer /var/www/vendor ./vendor
COPY --chown=www-data:www-data --from=yarn /var/www/public/build ./public/build
COPY --chown=www-data:www-data --from=yarn /var/www/bootstrap/ssr ./bootstrap/ssr

RUN ls -lah

RUN chmod -R 0755 bootstrap/cache storage \
    && composer dump-autoload --optimize
