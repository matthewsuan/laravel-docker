FROM alpine:3.18

# Update
RUN apk update

# Update certificates
RUN apk --update-cache add ca-certificates

# Install dependencies
RUN apk add nginx php82 php82-fpm php82-soap php82-openssl php82-gmp php82-pdo_odbc php82-json php82-dom php82-pdo php82-zip php82-mysqli php82-sqlite3 php82-pdo_pgsql php82-bcmath php82-gd php82-odbc php82-pdo_mysql php82-pdo_sqlite php82-gettext php82-xml php82-xmlreader php82-xmlwriter php82-simplexml php82-bz2 php82-iconv php82-pdo_dblib php82-curl php82-ctype php82-tokenizer php82-opcache php82-fileinfo php82-session php82-mbstring supervisor curl

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
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php82/php-fpm.d/www.conf
RUN sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php82/php-fpm.d/www.conf
RUN sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php82/php-fpm.d/www.conf
RUN sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php82/php-fpm.d/www.conf
RUN sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php82/php-fpm.d/www.conf
RUN sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php82/php-fpm.d/www.conf #uncommenting line

# Modify php.ini
RUN sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php82/php.ini
RUN sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php82/php.ini
RUN sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php82/php.ini
RUN sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php82/php.ini
RUN sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php82/php.ini
RUN sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php82/php.ini
RUN sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php82/php.ini
RUN sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php82/php.ini

# Copy nginx.conf
COPY config/nginx.conf /etc/nginx/nginx.conf

# Copy crontab
COPY config/crontab /var/www/crontab

# Copy supervisord.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
