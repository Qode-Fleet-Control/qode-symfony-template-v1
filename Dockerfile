# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# Symfony on FrankenPHP (the app server the Symfony Docker setup uses). The image
# runs APP_ENV=prod; docker/entrypoint.sh serves 0.0.0.0:$PORT with the PORT read
# from the environment when the container STARTS.
FROM dunglas/frankenphp:1-php8.4-bookworm AS runtime
RUN install-php-extensions intl zip opcache
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
ENV APP_ENV=prod APP_DEBUG=0
COPY composer.json composer.lock symfony.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY . .
RUN composer dump-autoload --classmap-authoritative --no-dev --no-interaction \
 && composer run-script --no-dev post-install-cmd \
 && useradd -r -u 10001 -d /app app \
 && mkdir -p var && chown -R app:app var /config/caddy /data/caddy \
 && chmod +x docker/entrypoint.sh
ARG BUILD_ID=""
ENV PORT=8000 SERVER_ROOT=/app/public BUILD_ID=$BUILD_ID
USER app
EXPOSE 8000
ENTRYPOINT ["docker/entrypoint.sh"]
