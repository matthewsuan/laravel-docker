FROM alpine:3.16

# Update
RUN apk update

# Update certificates
RUN apk --update-cache add ca-certificates

# Install dependencies
RUN apk add nginx php81 php81-fpm php81-soap php81-openssl php81-gmp php81-pdo_odbc php81-json php81-dom php81-pdo php81-zip php81-mysqli php81-sqlite3 php81-pdo_pgsql php81-bcmath php81-gd php81-odbc php81-pdo_mysql php81-pdo_sqlite php81-gettext php81-xml php81-xmlreader php81-xmlwriter php81-simplexml php81-bz2 php81-iconv php81-pdo_dblib php81-curl php81-ctype php81-tokenizer php81-opcache php81-fileinfo php81-session php81-mbstring supervisor curl

# Install supercronic
RUN curl -fsSLO "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64"
RUN chmod +x supercronic-linux-amd64
RUN mv supercronic-linux-amd64 /usr/bin/supercronic

# Symlink php8 to php
RUN ln -s /usr/bin/php8 /usr/bin/php

# Add user
RUN adduser -D -g 'www' www
RUN mkdir /www
RUN chown -R www:www /var/lib/nginx
RUN chown -R www:www /www

# Set ENV
ENV PHP_FPM_USER="www"
ENV PHP_FPM_GROUP="www"
ENV PHP_FPM_LISTEN_MODE="0660"
ENV PHP_MEMORY_LIMIT="512M"
ENV PHP_MAX_UPLOAD="50M"
ENV PHP_MAX_FILE_UPLOAD="200"
ENV PHP_MAX_POST="100M"
ENV PHP_DISPLAY_ERRORS="On"
ENV PHP_DISPLAY_STARTUP_ERRORS="On"
ENV PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
ENV PHP_CGI_FIX_PATHINFO=0

# Modify www.conf
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php81/php-fpm.d/www.conf
RUN sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php81/php-fpm.d/www.conf
RUN sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php81/php-fpm.d/www.conf
RUN sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php81/php-fpm.d/www.conf
RUN sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php81/php-fpm.d/www.conf
RUN sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php81/php-fpm.d/www.conf #uncommenting line

# Modify php.ini
RUN sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php81/php.ini
RUN sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php81/php.ini
RUN sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php81/php.ini
RUN sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php81/php.ini
RUN sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php81/php.ini
RUN sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php81/php.ini
RUN sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php81/php.ini
RUN sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php81/php.ini

# Copy nginx.conf
COPY config/nginx.conf /etc/nginx/nginx.conf

# Copy crontab
COPY config/crontab /var/www/crontab

# Copy supervisord.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
