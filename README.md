# Symfony template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with the
stock Symfony 8.1 skeleton laid on top, served by FrankenPHP.

## Origin

    docker run --rm -u $(id -u):$(id -g) -v "$PWD":/w -w /w <php8.4 + composer:2 image> \
      composer create-project symfony/skeleton qode-symfony-template-v1 --prefer-dist --no-interaction

Generated 2026-10-05 (symfony/skeleton, Symfony 8.1.*, PHP 8.4.26 — the PHP the image
runs). `vendor/` and `var/` were removed; `composer.lock` and `symfony.lock` are kept.
The skeleton is the minimal flavour: add what you need with Flex recipes
(`composer require twig orm webapp …`).

## Run it

**On the fleet** — nothing to do: `bin/run` (docker runtime) does `docker compose build`
then `docker compose up --remove-orphans` in the foreground. The app listens on
`0.0.0.0:$PORT`; `HEALTH_PATH=/health`; `/` answers a small JSON greeting.

**With docker**

    PORT=8000 bin/run              # or: docker compose up --build
    curl localhost:8000/health

**Without docker** (PHP 8.4+, composer):

    FLEET_RUNTIME=process PORT=8000 bin/run
    # = composer install; php -S 0.0.0.0:$PORT -t public   (APP_ENV=dev from .env)

| step | process runtime | docker runtime |
|---|---|---|
| install | `composer install --no-interaction` | — |
| build | — | `docker compose build` |
| start | `php -S 0.0.0.0:$PORT -t public` | `docker compose up --remove-orphans` |

`bin/console` is Symfony's own console; it lives in `bin/` beside the fleet scripts.

## How the container works

- `Dockerfile`: `dunglas/frankenphp:1-php8.4-bookworm` (+ intl, zip, opcache),
  `composer install --no-dev`, `APP_ENV=prod`, the Flex auto-scripts (cache:clear,
  assets:install) run at build, non-root user `app`.
- `docker/entrypoint.sh`: generates an `APP_SECRET` when none is set (`.env` leaves it
  empty; set it to keep signed data valid across restarts), `cache:warmup`, then serves
  with FrankenPHP's stock Caddyfile on `SERVER_NAME=":$PORT"` (plain HTTP on the runtime
  `$PORT`), document root `public/`.
- `.env` is kept in the image on purpose: Symfony's Dotenv requires it to exist. Real
  environment variables win over it.

## Deviations from the stock generator output, and why

- `src/Controller/HomeController.php` added: `/` (JSON greeting) and `/health` (the
  fleet's health check). The bare skeleton has no route at all, so `/` is a 404 in prod.
- Added `Dockerfile`, `docker/entrypoint.sh`, `compose.yaml`, `.dockerignore`,
  `fleet.conf`, the fleet scripts in `bin/`, `.github/workflows/`, `docs/fleet-lifecycle.md`;
  `.gitignore` gained `.fleet/`, `.fleet-deploy.log`, `*.log`.
- Trusted proxies are not configured (the skeleton generates no absolute URLs). When you
  add Twig/forms behind the fleet's TLS edge, set `framework.trusted_proxies`.

## Verified

**Not verified yet.** The `docker compose build` / `verify.sh` run was never reached: on
2026-10-05 the shared docker host's disk sat at 0-2 GB free (98 GB volume at 99-100%)
for more than three hours, below the 6 GB gate builds wait for. Before trusting this
template, run `verify.sh <dir> <port>` (run, restart and stop must all pass).

What *was* checked: `migrate.py audit` → READY; `php -l` on every PHP file this template
added or changed, and `sh -n` on its shell scripts → clean.

See `docs/fleet-lifecycle.md` for the lifecycle scripts.
