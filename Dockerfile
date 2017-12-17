 FROM node:boron
 MAINTAINER Umeaduma Livinus
 WORKDIR /usr/src/app
 COPY ./package.json /usr/src/app
 COPY ./package-lock.json /usr/src/app
 RUN npm install
 COPY . /usr/src/app
 EXPOSE 3000
 EXPOSE 27017
 CMD ["npm","start"]
