#!/bin/sh

if [[ -f /root/conf/pre-install.sh ]]; then
  echo "Running: pre-install.sh"
  source /root/conf/pre-install.sh
fi

echo "Build method: $METHOD"

if [ "${METHOD}" = "none" ]; then

  echo "Checking for existing Drupal"
  if [ ! -d ${NGINX_DRUPAL_ROOTDIR} ] || [ "$(cd ${NGINX_DRUPAL_ROOTDIR}/ && drush st | grep 'Drupal version' | wc -l)" = "0"  ]; then
    echo "Drupal is missing "
  fi
  export METHOD_AUTO_RESULT=noop

elif [ "${METHOD}" = "new" ]; then

  echo "Install new Drupal site"
  source /root/conf/db-create.sh
  source /root/conf/db-grant-permission.sh
  source /root/conf/drupal-install.sh
  export METHOD_AUTO_RESULT=new_install

elif [ "${METHOD}" = "auto" ]; then
  echo "Building..."
  source /root/conf/db-wait.sh

  if [ ! -d ${NGINX_DRUPAL_ROOTDIR} ] || [ "$(cd ${NGINX_DRUPAL_ROOTDIR}/ && drush st | grep 'Drupal version' | wc -l)" = "0"  ]; then
    echo "Drupal is missing"
    source /root/conf/drupal-download.sh
  fi

  if [[ ! -f ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}/settings.php ]]; then
    echo "Missing settings file"
    mkdir -p ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}

    mysql -h${MYSQL_HOST_NAME} -u${DRUPAL_DB_USER} -p${DRUPAL_DB_PASSWORD} -e "use ${DRUPAL_DB}; SELECT 0 FROM ${DRUPAL_DB_PREFIX}node LIMIT 1;"
    if [ $? -eq 0 ]; then

      echo "Create settings file for existing database"
      cp ${NGINX_DRUPAL_ROOTDIR}/sites/default/default.settings.php ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}/settings.php
      cd ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR} && drush eval "include DRUPAL_ROOT.'/includes/install.inc'; include DRUPAL_ROOT.'/includes/update.inc'; \$db['databases']['value'] = update_parse_db_url('mysql://${DRUPAL_DB_USER}:${DRUPAL_DB_PASSWORD}@${MYSQL_HOST_NAME}/${DRUPAL_DB}', '${DRUPAL_DB_PREFIX}'); drupal_rewrite_settings(\$db, '${DRUPAL_DB_PREFIX}');"
      export METHOD_AUTO_RESULT=settings_updated

    else

      echo "Install brand new Drupal"
      source /root/conf/db-create.sh
      source /root/conf/db-grant-permission.sh
      source /root/conf/drupal-install.sh
      export METHOD_AUTO_RESULT=new_install
    fi

  else

    echo "Settings file exist"
    if [ "$(cd ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR} && drush st | grep 'Connected' | wc -l)" == "1" ]; then

      echo "Already running"
      export METHOD_AUTO_RESULT=enabled

    else

      echo "..but doesn't work"
      mysql -h${MYSQL_HOST_NAME} -u${DRUPAL_DB_USER} -p${DRUPAL_DB_PASSWORD} -e "use ${DRUPAL_DB}; SELECT 0 FROM ${DRUPAL_DB_PREFIX}node LIMIT 1;"
      if [ $? -eq 0 ]; then

        echo "Update settings file"
        cd ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR} && drush eval "include DRUPAL_ROOT.'/includes/install.inc'; include DRUPAL_ROOT.'/includes/update.inc'; \$db['databases']['value'] = update_parse_db_url('mysql://${DRUPAL_DB_USER}:${DRUPAL_DB_PASSWORD}@${MYSQL_HOST_NAME}/${DRUPAL_DB}', '${DRUPAL_DB_PREFIX}'); drupal_rewrite_settings(\$db, '${DRUPAL_DB_PREFIX}');"
        export METHOD_AUTO_RESULT=settings_updated

      else

        echo "Install brand new Drupal"
        cp -f ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}/default.settings.php ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}/settings.php
        source /root/conf/db-create.sh
        source /root/conf/db-grant-permission.sh
        source /root/conf/drupal-install.sh
        export METHOD_AUTO_RESULT=new_install

      fi
    fi
  fi
fi

chgrp -R ${GROUP_ID} ${NGINX_DRUPAL_ROOTDIR}
find ${NGINX_DRUPAL_ROOTDIR} -type d -exec chmod u=rwx,g=rx,o= '{}' \;
find ${NGINX_DRUPAL_ROOTDIR} -type f -exec chmod u=rw,g=r,o= '{}' \;
find ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}/files -type d -exec chmod ug=rwx,o= '{}' \;
find ${NGINX_DRUPAL_ROOTDIR}/sites/${DRUPAL_SUBDIR}/files -type f -exec chmod ug=rw,o= '{}' \;

if [[ -f /root/conf/post-install.sh ]]; then
  echo "Running: post-install.sh"
  source /root/conf/post-install.sh
fi
