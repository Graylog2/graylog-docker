# Graylog Docker Image

[![Docker Stars](https://img.shields.io/docker/stars/graylog2/graylog.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/graylog2/graylog.svg)][hub]
[![Image Size](https://images.microbadger.com/badges/image/graylog2/graylog.svg)][microbadger]
[![Image Version](https://images.microbadger.com/badges/version/graylog2/graylog.svg)][microbadger]
[![Image License](https://images.microbadger.com/badges/license/graylog2/graylog.svg)][microbadger]

[hub]: https://hub.docker.com/r/graylog2/graylog/
[microbadger]: https://microbadger.com/images/graylog2/graylog

## What is Graylog?

Graylog is a centralized logging solution that allows the user to aggregate and search through logs. It provides a powerful query language, a processing pipeline for data transformation, alerting abilities and much more. It is fully extensible through a REST API. Add-Ons can be downloaded from the [Graylog Marketplace](https://marketplace.graylog.org/).

## Architecture

Take a look at the minimal [Graylog architecture](http://docs.graylog.org/en/latest/pages/architecture.html) to get the big picture of a Graylog setup. In essence, Graylog needs to talk to MongoDB to store configuration data as well as Elasticsearch to store the actual log data.

## How to use this image

Start the MongoDB container
```
$ docker run --name some-mongo -d mongo:2
```

Start Elasticsearch
```
$ docker run --name some-elasticsearch -d elasticsearch:2 elasticsearch -Des.cluster.name="graylog"
```

Run Graylog server and link with the other two
```
$ docker run --link some-mongo:mongo --link some-elasticsearch:elasticsearch -p 9000:9000 -e GRAYLOG_WEB_ENDPOINT_URI="http://127.0.0.1:9000/api" -d graylog2/server
```

### Settings

Graylog comes with a default configuration that works out of the box but you have to set a password for the admin user. Also the web interface needs to know how to connect from your browser to the Graylog API. Both can be done via environment variables.

```
  -e GRAYLOG_PASSWORD_SECRET=somepasswordpepper
  -e GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
  -e GRAYLOG_WEB_ENDPOINT_URI="http://127.0.0.1:9000/api"
```
In this case you can login to Graylog with the user and password `admin`.  Generate your own password with this command:

```
  $ echo -n yourpassword | shasum -a 256
```

This all can be put in a `docker-compose` file, like:

```
version: '2'
services:
  some-mongo:
    image: "mongo:3"
  some-elasticsearch:
    image: "elasticsearch:2"
    command: "elasticsearch -Des.cluster.name='graylog'"
  graylog:
    image: graylog2/server:2.1.1-1
    environment:
      GRAYLOG_PASSWORD_SECRET: somepasswordpepper
      GRAYLOG_ROOT_PASSWORD_SHA2: 8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      GRAYLOG_WEB_ENDPOINT_URI: http://127.0.0.1:9000/api
    links:
      - some-mongo:mongo
      - some-elasticsearch:elasticsearch
    ports:
      - "9000:9000"
```

After starting the three containers with `docker-compose up` open your browser with the URL `http://127.0.0.1:9000` and login with `admin:admin`

## Persist log data

In order to make the log data and configuration of Graylog persistent, you can use external volumes to store all data. In case of a container restart simply re-use the existing data from the former instances.

If you need to customize the configuration files for Graylog (such as the Log4j 2 configuration), you can download the vanilla files from GitHub and put them into a dedicated Docker volume.

Create the configuration directory and copy the default files:

```
mkdir -p ./graylog/config
cd ./graylog/config
wget https://raw.githubusercontent.com/Graylog2/graylog-docker/2.2/config/graylog.conf
wget https://raw.githubusercontent.com/Graylog2/graylog-docker/2.2/config/log4j2.xml
```

The `docker-compose.yml` file looks like this:

```
version: '2'
services:
  some-mongo:
    image: "mongo:3"
    volumes:
      - /graylog/data/mongo:/data/db
  some-elasticsearch:
    image: "elasticsearch:2"
    command: "elasticsearch -Des.cluster.name='graylog'"
    volumes:
      - /graylog/data/elasticsearch:/usr/share/elasticsearch/data
  graylog:
    image: graylog2/server:2.1.1-1
    volumes:
      - /graylog/data/journal:/usr/share/graylog/data/journal
      - /graylog/config:/usr/share/graylog/data/config
    environment:
      GRAYLOG_PASSWORD_SECRET: somepasswordpepper
      GRAYLOG_ROOT_PASSWORD_SHA2: 8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      GRAYLOG_WEB_ENDPOINT_URI: http://127.0.0.1:9000/api
    links:
      - some-mongo:mongo
      - some-elasticsearch:elasticsearch
    ports:
      - "9000:9000"
      - "12201:12201/udp"
      - "1514:1514/udp"
```

Start all services with:

```
docker-compose up
```
 
## Configuration

Every configuration option can be set via environment variables, take a look [here](https://github.com/Graylog2/graylog2-server/blob/master/misc/graylog.conf) for an overview. Simply prefix the parameter name with `GRAYLOG_` and put it all in upper case. Another option would be to store the configuration file outside of the container and edit it directly.

## Documentation

Documentation for Graylog is hosted [here](http://docs.graylog.org/en/latest/). Please read through the docs and familiarize yourself with the functionality before opening an [issue on GitHub](https://github.com/Graylog2/graylog2-server/issues).

## License

This Docker image is licensed under the Apache 2.0 license, see [LICENSE](LICENSE).

Graylog itself is licensed under the GNU Public License 3.0, see [license information](https://github.com/Graylog2/graylog2-server/blob/master/COPYING).
