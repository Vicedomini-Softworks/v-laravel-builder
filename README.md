# v-laravel-builder

CI image for the Laravel and Lumen projects of Vicedomini Cloud: PHP 8.5 (CLI) with the extensions Laravel needs, Composer 2, Node.js 22, git and poppler-utils. It replaces the per-build `setup-php` / `setup-node` work on the Jenkins Kubernetes agents.

```
ghcr.io/vicedomini-softworks/v-laravel-builder:8.5
```

Tags: `8.5` (what the Jenkinsfiles pin), `latest`, and `sha-<commit>` for a reproducible build.

## Contents

| | |
|---|---|
| PHP | `php:8.5-cli-bookworm` + `bcmath exif gd intl opcache pcntl pcov pdo_mysql pdo_pgsql redis sockets xsl zip`; `memory_limit=-1` |
| Composer | 2.x, `COMPOSER_ALLOW_SUPERUSER=1` |
| Node.js | newest 22.x, glibc build, checksum-verified |
| Tools | `git` (with `safe.directory '*'`), `unzip`, `pdftotext`/`pdftoppm` (poppler-utils) |

Not in the image: a Docker daemon, so it cannot build images.

## Build

`.github/workflows/image.yml` builds the image, smoke-tests it (versions, every extension listed above, unlimited `memory_limit`) and pushes it to GHCR. It runs on a push to `main` that touches the `Dockerfile` or the workflow, weekly (base-image and security updates) and on demand. It has no `pull_request` trigger on purpose: the repository is public and the job holds a package-write token.

The package must be public for the cluster to pull it without credentials: *Package settings → Change visibility* after the first push, if GitHub did not already make it public.

## Adding an extension

Add it to the `install-php-extensions` line in the `Dockerfile` and to the loop in the smoke-test step, then push to `main`.
