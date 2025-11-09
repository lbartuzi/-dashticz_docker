# Dockerfile for Dashticz v3
# Based on PHP 7.4 with Apache (can be updated to PHP 8.x if needed)
FROM php:7.4-apache

# Build arguments
ARG TIMEZONE="Europe/Amsterdam"
ARG DASHTICZ_BRANCH="master"

# Set timezone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo ${TIMEZONE} > /etc/timezone && \
    printf "[PHP]\ndate.timezone = ${TIMEZONE}\n" > /usr/local/etc/php/conf.d/timezone.ini

# Update and install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    nano \
    vim \
    # Additional libraries for PHP extensions
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libonig-dev \
    libzip-dev \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Dashticz
RUN docker-php-ext-install \
    xml \
    curl \
    mbstring \
    zip \
    opcache \
    && docker-php-ext-enable \
    xml \
    curl \
    mbstring \
    zip \
    opcache

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    # Increase memory limit for PHP
    echo "memory_limit = 256M" >> "$PHP_INI_DIR/php.ini" && \
    echo "upload_max_filesize = 50M" >> "$PHP_INI_DIR/php.ini" && \
    echo "post_max_size = 50M" >> "$PHP_INI_DIR/php.ini" && \
    echo "max_execution_time = 300" >> "$PHP_INI_DIR/php.ini"

# Enable Apache modules
RUN a2enmod rewrite && \
    a2enmod headers && \
    a2enmod expires && \
    a2enmod deflate

# Create directory for Dashticz
WORKDIR /var/www/html

# Clone Dashticz repository
RUN git clone https://github.com/Dashticz/dashticz.git --branch ${DASHTICZ_BRANCH} --depth 1 /var/www/html/dashticz

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/dashticz && \
    chmod -R 755 /var/www/html/dashticz

# Create Apache virtual host configuration
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/dashticz\n\
    <Directory /var/www/html/dashticz>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/dashticz-error.log\n\
    CustomLog ${APACHE_LOG_DIR}/dashticz-access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/dashticz.conf

# Enable the Dashticz site
RUN a2dissite 000-default.conf && \
    a2ensite dashticz.conf

# Create a startup script
RUN echo '#!/bin/bash\n\
# Check if CONFIG.js exists, if not create from default\n\
if [ ! -f /var/www/html/dashticz/custom/CONFIG.js ]; then\n\
    if [ -f /var/www/html/dashticz/custom/CONFIG_DEFAULT.js ]; then\n\
        cp /var/www/html/dashticz/custom/CONFIG_DEFAULT.js /var/www/html/dashticz/custom/CONFIG.js\n\
        # Replace default Domoticz IP with environment variable if set\n\
        if [ ! -z "$DOMOTICZ_IP" ]; then\n\
            sed -i "s|192.168.1.3:8084|$DOMOTICZ_IP|g" /var/www/html/dashticz/custom/CONFIG.js\n\
        fi\n\
    fi\n\
fi\n\
# Fix permissions\n\
chown -R www-data:www-data /var/www/html/dashticz/custom\n\
# Start Apache\n\
apache2-foreground' > /usr/local/bin/start-dashticz.sh && \
    chmod +x /usr/local/bin/start-dashticz.sh

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s \
    CMD curl -f http://localhost/ || exit 1

# Start Apache
CMD ["/usr/local/bin/start-dashticz.sh"]
