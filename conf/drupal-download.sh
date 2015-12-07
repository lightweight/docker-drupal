#!/bin/sh
if [ "${DRUPAL_DOWNLOAD_METHOD}" = "drush" ]; then

  echo "Downloading drupal-${DRUPAL_MAJOR_VERSION} with drush..."
  drush dl drupal-${DRUPAL_MAJOR_VERSION} --destination=/tmp -y \
    && rsync -a /tmp/drupal*/ ${NGINX_DRUPAL_ROOTDIR}

elif [ "${DRUPAL_DOWNLOAD_METHOD}" = "git" ]; then

  echo "Cloning..."
  cd /tmp \
    && git clone --branch ${DRUPAL_GIT_BRANCH} --depth=${DRUPAL_GIT_DEPTH} http://git.drupal.org/project/drupal.git drupal \
    && rsync -a /tmp/drupal/ ${NGINX_DRUPAL_ROOTDIR}

elif [ "${DRUPAL_DOWNLOAD_METHOD}" = "none" ]; then

  echo "Not downloading Drupal - make sure to assign a volume containing a Drupal directory to ${DRUPAL_SUBDIR}, when initiating Docker, e.g.  -v /home/me/drupaldev/drupal7:${NGINX_DRUPAL_ROOTDIR}"
  
else

  echo "Missing download method or download method is incorrect"

fi
