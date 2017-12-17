#!/usr/bin/env bash

# This script install docker if it does not exist.
# It installs git if it does not exist
# It clones the forked source code from the remote git repo
# It generate the .env file for the application
# It generates the Dockerfile for the application container image
# It generates the Dockerfile for the mongodb container image
# It generates .dockerignore file
# It generates the docker-composer.yml for use by docker-compose
# It finally runs the docker-compose to create the two containers.
# Scripted by Umeaduma Livinus.


# NOTE the mongodb folder, .dockerignore, .env, docker-compose.yml,
# Dockerfile can be deleted and then this script will be able to
# generate them again, create the image and build the containers.

DOCKER=`which docker`
GIT=`which git`
LSB_RELEASE=`which lsb_release`
APP_DIR="$HOME/alc_docker_app"
# install docker-ce
if [ -z "$DOCKER" ];then
    if [ -n "$LSB_RELEASE" ];then
        IS_ARTFUL=`"$LSB_RELEASE" -cs`
        # if it does not exist for ubuntu 17.10 artful distro
        if [ $IS_ARTFUL = "artful" ];then
            sudo apt-get update
            sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo apt-key fingerprint 0EBFCD88
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable"
            sudo apt-get update
            sudo apt-get install docker-ce docker-compose
        else
            sudo apt-get update
            sudo apt-get install docker-ce docker-compose
        fi
    fi
fi
# checks for existence of git
if [ -z "$GIT" ];then
    sudo apt-get install git
fi
# creates app directory if it does not exist
if [ ! -d "$APP_DIR" ];then
    mkdir "$APP_DIR"
fi
if [ ! -e "$APP_DIR/package.json" ];then
    git clone https://github.com/Livialink/UserManager.git $APP_DIR
fi

if [ ! -s "$APP_DIR/.env" ];then
    echo -en \
         " PORT=3000\n" \
         "DB_URL='mongodb://database:27017/databaseName'" > "$APP_DIR/.env"
fi

if [ ! -s "$APP_DIR/Dockerfile" ];then
    touch "$APP_DIR/Dockerfile"
    echo  -en \
            " FROM node:boron\n" \
            "MAINTAINER Umeaduma Livinus\n" \
            "WORKDIR /usr/src/app\n" \
            "COPY ./package.json /usr/src/app\n" \
            "COPY ./package-lock.json /usr/src/app\n" \
            "RUN npm install\n" \
            "COPY . /usr/src/app\n" \
            "EXPOSE 3000\n" \
            "EXPOSE 27017\n" \
            "CMD [\"npm\",\"start\"]\n" > "$APP_DIR/Dockerfile"

    if [ ! -d "$APP_DIR/mongodb" ];then
        mkdir "$APP_DIR/mongodb"
        if [ ! -s "$APP_DIR/mongodb/Dockerfile" ];then
                echo -en \
                       " FROM ubuntu\n" \
                       "MAINTAINER Umeaduma Livinus\n" \
                       "RUN \ \n" \
                       "   apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \ \n" \
                       "   echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' > /etc/apt/sources.list.d/mongodb.list && \ \n" \
                       "   apt-get update && \ \n" \
                       "   apt-get install -y mongodb-org && \ \n" \
                       "   rm -rf /var/lib/apt/lists/*\n" \
                       " VOLUME [\"/data/db\"]\n" \
                       " WORKDIR /data\n" \
                       " CMD [\"mongod\"]\n" \
                       " EXPOSE 27017\n" > "$APP_DIR/mongodb/Dockerfile"

        #  build mongodb image with sudo docker build -t alc_mongodb .
        # to run mongodb instance sudo docker run --name my_instance -i -t alc_mongodb
        fi
    fi


    if [ ! -s "$APP_DIR/.dockerignore" ];then
        echo -en \
             " node_modules\n" \
             "npm-debug.log" > "$APP_DIR/.dockerignore"
    fi
    if [ ! -s "$APP_DIR/docker-compose.yml" ];then

        echo -en \
             " version: \"2\"\n" \
             "services:\n" \
             "  database:\n"\
             "    build: $APP_DIR/mongodb/.\n" \
             "    ports:\n" \
             "      - \"27017:27017\"\n" \
             "  alc-app:\n" \
             "    build: $APP_DIR/.\n" \
             "    ports:\n" \
             "      - \"3000:3000\"\n" \
             "    links:\n" \
             "      - database\n" \
             "    volumes:\n" \
             "      - $APP_DIR/.:/usr/src/app\n" > "$APP_DIR/docker-compose.yml"
    fi

fi

if [ -s "$APP_DIR/docker-compose.yml" ];then
    cd "$APP_DIR/." & sudo docker-compose up --build
fi
