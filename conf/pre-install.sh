#!/bin/sh

echo "setting the nginx server root for Drupal to ${NGINX_DRUPAL_ROOTDIR}"
# fix up the server root in /etc/nginx/sites-enabled/default
# using "|" instead of "/" due to / in the value of NGINX_DRUPAL_ROOTDIR
sed -i "s|NGINX_DRUPAL_ROOTDIR|${NGINX_DRUPAL_ROOTDIR}|g"  /etc/nginx/sites-enabled/default
# create the directory, if it doesn't exists
echo "create the repo directory (${DRUPAL_REPO_ROOTDIR}) if it doesn't already exist"
mkdir -p ${DRUPAL_REPO_ROOTDIR}
#chown -R ${USER_ID}:${GROUP_ID} ${DRUPAL_REPO_ROOTDIR}

# shift the main user from www-data to being the one used by the launching or specified user
# as per env USER_ID GROUP_ID - instead we use a "docker" user
usermod -u $USER_ID docker
