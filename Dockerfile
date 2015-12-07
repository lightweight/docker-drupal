FROM ubuntu:trusty
# based on https://hub.docker.com/r/zaporylie/drupal/
MAINTAINER Dave Lane <dave@davelane.nz>

ENV CONTAINER_USER docker
ENV CONTAINER_UID 1000
ENV CONTAINER_GID 1000
#ENV TERM xterm
ENV DEV_DIR /app
ENV DEBIAN_FRONTEND noninteractive

VOLUME ["${DEV_DIR}"]
WORKDIR ${DEV_DIR}

# Debugging
RUN echo "CONTAINER_USER: $CONTAINER_USER, CONTAINER_UID: $CONTAINER_UID, CONTAINER_GID: $CONTAINER_GID, DEV_DIR: $DEV_DIR"

# Create a user, with sudo permissions, to run the actual site.
RUN addgroup --gid $CONTAINER_GID $CONTAINER_USER \
 && adduser --disabled-password --quiet --gecos "" --uid ${CONTAINER_UID} --gid ${CONTAINER_GID} --home ${DEV_DIR} ${CONTAINER_USER} \
 && adduser docker sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

#
# Install all the packages we'll need
RUN apt-get update \
  && apt-get -yq install \
    openssh-server \
    supervisor \
    php5-mysql \
    mysql-client \
    git \
    net-tools \
    vim \
    curl \
    nginx \
    php5-fpm \
    unzip \
    php5-curl \
    php5-gd \
    php-pear \
    php-apc \
    mysql-server \
    shunit2 \
    pwgen \
    dialog \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./conf /root/conf/

# Set up PHP5-FPM
RUN sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/fpm/php.ini \
  && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini \
  && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf \
  && sed -i -e "s/www-data/docker/g" /etc/php5/fpm/php-fpm.conf \
  && sed -i -e "s/www-data/docker/g" /etc/php5/fpm/pool.d/www.conf \
  && find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; \
  && sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/fpm/php.ini \
  && sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/cli/php.ini \
  && sed -ri 's/^allow_url_fopen\s*=\s*On/allow_url_fopen = Off/g' /etc/php5/fpm/php.ini \
  && sed -ri 's/^upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/g' /etc/php5/fpm/php.ini \
  && sed -ri 's/^upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/g' /etc/php5/cli/php.ini
# Set up nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i -e "s/www-data/docker/g" /etc/nginx/nginx.conf \
 && sed -i -e "s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf \
 && cp /root/conf/drupal.conf /etc/nginx/sites-available/default
# Set up Composer for root user
RUN cd /home \
  && composer global require drush/drush:dev-master \
  && echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc
# Set up Composer for the docker user
RUN cp -a $HOME/.composer ${DEV_DIR} \
 && echo 'export PATH="${DEV_DIR}/.composer/vendor/bin:$PATH"' >> ${DEV_DIR}/.bashrc \
 && sudo chown -R docker:docker ${DEV_DIR}
# Set up auto-running of nginx
RUN mkdir -p /var/run/nginx /var/run/sshd /var/log/supervisor
# Prepare to run script installing Drupal
RUN chmod u+x /root/conf/drupal-download.sh \
  && chmod u+x /root/conf/drupal-install.sh
# Prepare to run script installing MySQL on the local machine (this is redundant if you're using an external DB container)
RUN chmod u+x /root/conf/db-create.sh \
  && chmod u+x /root/conf/db-wait.sh \
  && chmod u+x /root/conf/db-create-user.sh \
  && chmod u+x /root/conf/db-grant-permission.sh
# Prepare the preinstall hook
RUN chmod u+x /root/conf/pre-install.sh
# Prepare the main install script
RUN chmod u+x /root/conf/start.sh \
 && chmod u+x /root/conf/run.sh
# Prepare the test scripts
RUN chmod u+x /root/conf/tests/*
# Create the master supervisor configuration...
RUN cp /root/conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Create some directories for pre-run and post-run scripts
RUN mkdir -p /root/conf/before-start \
 && mkdir -p /root/conf/after-start
# Configure SSHD
RUN cp /root/conf/sshd.sh /root/conf/after-start \
 && mkdir -p /var/run/sshd \
 && echo 'root:defaultpassword' | chpasswd \
 && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# Some final exports to get the environment right...
RUN echo "export VISIBLE=now" >> /etc/profile \
 && echo "export TERM=xterm" >> /etc/bash.bashrc \
 && cp /root/conf/mysqld.sh /root/conf/before-start/00-mysqld.sh

# Set up the language variables
ENV LANG en_NZ.UTF-8
ENV LANGUAGE en_NZ.UTF-8
ENV LC_ALL en_NZ.UTF-8
# Compile the language spec
RUN locale-gen $LANG

# Set default environment variables
ENV NGINX_DRUPAL_ROOTDIR=${DEV_DIR}/drupal/drupal7 \
 DRUPAL_DB=drupal \
 DRUPAL_DB_USER=drupal \
 DRUPAL_DB_PASSWORD=drupal \
 DRUPAL_DB_DUMP=none \
 DRUPAL_PROFILE=minimal \
 DRUPAL_SUBDIR=default \
 DRUPAL_MAJOR_VERSION=7 \
 DRUPAL_DOWNLOAD_METHOD=none \
 DRUPAL_GIT_BRANCH=7.x \
 DRUPAL_GIT_DEPTH=1 \
 METHOD=auto \
 DRUPAL_TEST=0 \
 BUILD_TEST=0 \
 NOTVISIBLE="in users profile"

# this is deprecated in favour of using the -p syntax with the docker run command...
# EXPOSE 8622:22 8680:80

ENTRYPOINT ["/bin/bash"]

# Finally, run the full build shell
# First, say we're doing it
RUN echo "running run.sh - /root/conf/run.sh"
# Actually do it.
CMD ["/root/conf/run.sh"]
# Say we're finished
RUN echo "finished run.sh"
