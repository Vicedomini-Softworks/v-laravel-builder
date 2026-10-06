# CI image for the Laravel/Lumen projects of the Vicedomini Cloud monorepo: what
# `setup-php` + `setup-node` give a GitHub runner, preinstalled, so a Jenkins pod
# starts testing immediately instead of installing PHP extensions on every build.
#
#   PHP (CLI)  + the extensions Laravel and our projects need
#   Composer 2 + Node.js (glibc build: package-lock.json pins -gnu native binaries)
#   git, unzip, poppler-utils (vcloud-billing's PDF text-extraction tests)
ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-cli-bookworm

ARG NODE_MAJOR=22

LABEL org.opencontainers.image.title="v-laravel-builder" \
      org.opencontainers.image.description="PHP + Composer + Node CI image for Laravel projects" \
      org.opencontainers.image.source="https://github.com/Vicedomini-Softworks/v-laravel-builder" \
      org.opencontainers.image.licenses="UNLICENSED"

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_NO_INTERACTION=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git poppler-utils unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# What the official image lacks of what Laravel needs (ctype, curl, dom, fileinfo, filter,
# hash, mbstring, openssl, pcre, pdo, pdo_sqlite, session, sodium, tokenizer, xml, ... are
# built in), plus xsl for vcloud-billing's FatturaPA stylesheet checks.
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/install-php-extensions
RUN chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions @composer \
        bcmath exif gd intl opcache pcntl pdo_mysql pdo_pgsql redis sockets xsl zip

# The official image ships no php.ini, so PHP would run with memory_limit=128M and
# PHPStan dies. setup-php runs the CLI unlimited; the container's own limit is the cap.
RUN echo 'memory_limit=-1' > "$PHP_INI_DIR/conf.d/zz-memory-limit.ini"

# Newest Node ${NODE_MAJOR}.x, checked against nodejs.org's published checksums.
RUN set -eux; \
    base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"; \
    case "$(dpkg --print-architecture)" in amd64) arch=x64 ;; arm64) arch=arm64 ;; *) exit 1 ;; esac; \
    tarball="$(curl -fsSL "$base/SHASUMS256.txt" | awk -v a="linux-$arch.tar.xz" '$2 ~ a"$" {print $2}')"; \
    curl -fsSLO "$base/$tarball"; \
    curl -fsSL "$base/SHASUMS256.txt" | grep " $tarball\$" | sha256sum -c -; \
    tar -xJf "$tarball" -C /usr/local --strip-components=1; \
    rm "$tarball"; \
    node --version; npm --version

# The Jenkins workspace is checked out by another container, as another user.
RUN git config --system --add safe.directory '*'

WORKDIR /workspace
