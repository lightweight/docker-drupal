#!/bin/sh

drush dl drupal-${CODE_DRUSH_MAJOR_VERSION} --destination=/tmp -y \
  && rsync -a /tmp/drupal*/ /app/drupal
