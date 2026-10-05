#!/bin/sh
# Container start: serve the Symfony app on 0.0.0.0:$PORT.
set -e

# .env leaves APP_SECRET empty (only .env.dev sets one). No secret from the fleet ->
# make one for this container; set APP_SECRET in the environment to keep it stable.
if [ -z "${APP_SECRET:-}" ]; then
  APP_SECRET="$(php -r 'echo bin2hex(random_bytes(16));')"
  export APP_SECRET
  echo "entrypoint: APP_SECRET was empty; generated one for this container"
fi

php bin/console cache:warmup

export SERVER_NAME=":${PORT:-8000}"
exec frankenphp run --config /etc/frankenphp/Caddyfile
