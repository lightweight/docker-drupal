Drupal Docker Image
=============================

[![Build Status](https://travis-ci.org/zaporylie/docker-drupal.svg?branch=master)](https://travis-ci.org/zaporylie/docker-drupal)[![Pulls](https://img.shields.io/docker/pulls/zaporylie/drupal.svg)](https://hub.docker.com/r/zaporylie/drupal)[![Stars](https://img.shields.io/docker/stars/zaporylie/drupal.svg)](https://hub.docker.com/r/zaporylie/drupal)

Simple docker image to build containers for your existing Drupal projects. If you are working on Drupal code you might be more interested in zaporylie/drupal-dev image which is just an extension for this image anyway. For this project, I assume you're running Docker on a recent version of Ubuntu, Debian, or a derivative Linux (I'm running on Linux Mint 17.3, an Ubuntu 14.04 derivative).

## What you get?

* NGINX (thanks to [wiki.nginx.org](http://wiki.nginx.org/Drupal)
* php 5.5
* php5-fpm (thanks to [ricardoamaro/docker-drupal-nginx](https://github.com/ricardoamaro/docker-drupal-nginx))
* all php libraries required by Drupal
* sshd
* drush (with composer)
* mysql (but I strongly recommend to link separate mysql/mariadb container instead)
* sass for bootstrap development (with ruby, composer)

## Some features

The goal is to provide a quick-to-setup environment which references a git repostory containing a full Drupal site. One key advantage of the approach I've taken is that you can specify a "docker" user who can have the same user ID/group ID as your own user (as the developer) to ensure that on development systems your git user is the one who owns the files being served by this docker image.

Note: I don't recommend using this as it is for development purposes. You'll probably want to strip some stuff out of it.

## Drupal Repository expectations

This system expects the Drupal repository to contain the full Drupal core tree (for D6-8) as a directory within the top level. This allows for other useful documentation, scripts, database dumps, etc. at the same level, but not mixed up in the Drupal code base.

## Quickstart

First, read though the Dockerfile - that'll provide you with some insight as to what the Docker container's doing. You'll want to update the ENV values for your user on the local system (UserID and GroupID).

### Build container from Dockerfile and supporting files
docker build -t kiwilightweight/drupal .

### Launch new container
docker run --name mariadb-server -p 8680:80 -e USER_ID=`id -u` -e GROUP_ID=`id -g` --link mariadb:mysql --env-file ./env.list -v [path-to-your-repo, containing your drupal core dir]]:/app/drupal -d -P kiwilightweight/drupal

### start the container after it already exists
docker start kiwilightweight/drupal

## Some useful commandline things

### creating a shortcut for your container-of-interest

If your drupal dev container is the last one you've launched, you can get its ID like this and assign it to a handy shell variable:

ID=`docker ps -ql | awk '{ print $1}'`

### Getting a command prompt on the container

docker exec -it $ID /bin/bash

or as the "docker" user:

docker exec -it --user=docker $ID /bin/bash

# Known Problems/ToDos

 * The "docker" user's path for drush doesn't get set up right at the moment. Need to work on that. Workaround:

  sudo cp -a /root/.composer /app
  sudo cp /root/.bashrc /app
  sudo chown -R docker:docker /app/.composer /app/.bashrc

 * want to automate setting the ENV value (and making it dynamic at "run" time) for the dev user and group.

# Inherited notes from zaporylie

**With** separate mysql container (recommended):

````
docker run \
  --name <drupal> \
  --link <mysql_container_name_or_id>:mysql \
  -e MYSQL_HOST_NAME=mysql \
  -d \
  -P \
  zaporylie/drupal
````

**Without** separate mysql container:

````
docker run \
  --name <drupal> \
  -d \
  -P \
  zaporylie/drupal
````

## Configuration

| ENNVIRONMENTAL VARIABLE  |  DEFAULT VALUE  |  COMMENTS  |
|:-:|:-:|:-:|
| DRUPAL_DB | drupal |  |
| DRUPAL_DB_USER | drupal |  |
| DRUPAL_DB_PASSWORD | drupal |  |
| DRUPAL_PROFILE | minimal |  |
| DRUPAL_SUBDIR | default |  |
| DRUPAL_MAJOR_VERSION | 7 |  |
| DRUPAL_DOWNLOAD_METHOD | drush |  |
| DRUPAL_GIT_BRANCH | 7.x | Only if DRUPAL_DOWNLOAD_METHOD is git |
| DRUPAL_GIT_DEPTH | 1 | Only if DRUPAL_DOWNLOAD_METHOD is git |
| METHOD | auto | Synchronization method (use drush sql-sync or file) |
| MYSQL_HOST_NAME | (optional) | skip this if you're not linking mysql container |
| DRUPAL_TEST | 0 |  |
| BUILD_TEST | 0 |  |

## Dependencies (no longer required):

### Mysql

If you don't want to lose your data build data-only container first:

````
docker run \
  --name mysql_data \
  --entrypoint /bin/echo \
  mysql:5.5 \
  MYSQL data-only container
````

... then container with running mysql process ...

````
docker run \
  --name mysql_service\
  -e MYSQL_ROOT_PASSWORD=<mysecretpassword> \
  --volumes-from mysql_data \
  -d mysql:5.5
````

## Credits

This project is a modified version by Dave Lane <dave@davelane.nz> of a container originally created by Jakub Piasecki <jakub@piaseccy.pl>
