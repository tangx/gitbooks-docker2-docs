FROM php:7.2-rc-fpm-alpine

LABEL maintainer octowhale

# https://github.com/docker-library/php/blob/7c45279501f958926e51779081bc083fbb412539/7.2-rc/alpine/Dockerfile
# https://github.com/chrootLogin/docker-nextcloud/issues/3
RUN set -x \
    && deluser www-data   \
    # && delgroup www-data  \
    && addgroup -g 1000 -S www-data \
    && adduser -u 1000 -D -S -G www-data www-data

# RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories    \
#     && apk --no-cache add shadow \
#     && usermod -u 1000 www-data

# ENTRYPOINT ["docker-php-entrypoint"]
# CMD ["php", "-a"]