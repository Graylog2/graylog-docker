# Graylog Docker Image

[![Docker Stars](https://img.shields.io/docker/stars/graylog/graylog.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/graylog/graylog.svg)][hub]
[![Image Size](https://images.microbadger.com/badges/image/graylog/graylog.svg)][microbadger]
[![Image Version](https://images.microbadger.com/badges/version/graylog/graylog.svg)][microbadger]
[![Image License](https://images.microbadger.com/badges/license/graylog/graylog.svg)][microbadger]

[hub]: https://hub.docker.com/r/graylog/graylog/
[microbadger]: https://microbadger.com/images/graylog/graylog

## What is Graylog?

Graylog is a centralized logging solution that allows the user to aggregate and search through logs. It provides a powerful query language, a processing pipeline for data transformation, alerting abilities and much more. It is fully extensible through a REST API. Add-Ons can be downloaded from the [Graylog Marketplace](https://marketplace.graylog.org/).

## Architecture

Take a look at the minimal [Graylog architecture](http://docs.graylog.org/en/latest/pages/architecture.html) to get the big picture of a Graylog setup. In essence, Graylog needs to talk to MongoDB to store configuration data as well as Elasticsearch to store the actual log data.

## How to use this image

Please refer to the [Graylog Docker documentation](http://docs.graylog.org/en/2.4/pages/installation/docker.html) for a comprehensive overview and a detailed description of the Graylog Docker image.

### Quick start

If you simply want to checkout Graylog without any further customization, you can run the following three commands to create the necessary environment:

```
$ docker run --name mongo -d mongo:3
$ docker run --name elasticsearch \
    -e "http.host=0.0.0.0" -e "xpack.security.enabled=false" \
    -d docker.elastic.co/elasticsearch/elasticsearch:5.6.4
$ docker run --link mongo --link elasticsearch \
    -p 9000:9000 -p 12201:12201 -p 514:514 \
    -e GRAYLOG_WEB_ENDPOINT_URI="http://127.0.0.1:9000/api" \
    -d graylog/graylog:2.4.0-beta.3-1
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
  # MongoDB: https://hub.docker.com/_/mongo/
  mongo:
    image: mongo:3
  # Elasticsearch: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docker.html
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:5.6.4
    environment:
      - http.host=0.0.0.0
      # Disable X-Pack security: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/security-settings.html#general-security-settings
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    mem_limit: 1g
  # Graylog: https://hub.docker.com/r/graylog/graylog/
  graylog:
    image: graylog/graylog:2.4.0-beta.3-1
    environment:
      # CHANGE ME!
      - GRAYLOG_PASSWORD_SECRET=somepasswordpepper
      # Password: admin
      - GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      - GRAYLOG_WEB_ENDPOINT_URI=http://127.0.0.1:9000/api
    links:
      - mongo
      - elasticsearch
    ports:
      # Graylog web interface and REST API
      - 9000:9000
      # Syslog TCP
      - 514:514
      # Syslog UDP
      - 514:514/udp
      # GELF TCP
      - 12201:12201
      # GELF UDP
      - 12201:12201/udp
```

After starting the three containers with `docker-compose up` open your browser with the URL `http://127.0.0.1:9000` and login with `admin:admin`

## Persist log data

In order to make the log data and configuration of Graylog persistent, you can use external volumes to store all data. In case of a container restart simply re-use the existing data from the former instances.

If you need to customize the configuration files for Graylog (such as the Log4j 2 configuration), you can download the vanilla files from GitHub and put them into a dedicated Docker volume.

Create the configuration directory and copy the default files:

```
mkdir -p ./graylog/config
cd ./graylog/config
wget https://raw.githubusercontent.com/Graylog2/graylog2-images/2.4/docker/config/graylog.conf
wget https://raw.githubusercontent.com/Graylog2/graylog2-images/2.4/docker/config/log4j2.xml
```

The `docker-compose.yml` file looks like this:

```
version: '2'
services:
  # MongoDB: https://hub.docker.com/_/mongo/
  mongo:
    image: mongo:3
    volumes:
      - mongo_data:/data/db
  # Elasticsearch: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docker.html
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:5.6.4
    volumes:
      - es_data:/usr/share/elasticsearch/data
    environment:
      - http.host=0.0.0.0
      - transport.host=localhost
      - network.host=0.0.0.0
      # Disable X-Pack security: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/security-settings.html#general-security-settings
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    mem_limit: 1g
  # Graylog: https://hub.docker.com/r/graylog/graylog/
  graylog:
    image: graylog/graylog:2.4.0-beta.3-1
    volumes:
      - graylog_journal:/usr/share/graylog/data/journal
      - ./graylog/config:/usr/share/graylog/data/config
    environment:
      # CHANGE ME!
      - GRAYLOG_PASSWORD_SECRET=somepasswordpepper
      # Password: admin
      - GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      - GRAYLOG_WEB_ENDPOINT_URI=http://127.0.0.1:9000/api
    links:
      - mongo
      - elasticsearch
    ports:
      # Graylog web interface and REST API
      - 9000:9000
      # Syslog TCP
      - 514:514
      # Syslog UDP
      - 514:514/udp
      # GELF TCP
      - 12201:12201
      # GELF UDP
      - 12201:12201/udp

# Volumes for persisting data, see https://docs.docker.com/engine/admin/volumes/volumes/
volumes:
  mongo_data:
    driver: local
  es_data:
    driver: local
  graylog_journal:
    driver: local
```

Start all services with:

```
docker-compose up
```
 
## Configuration

Every configuration option can be set via environment variables, take a look [here](https://github.com/Graylog2/graylog2-server/blob/master/misc/graylog.conf) for an overview. Simply prefix the parameter name with `GRAYLOG_` and put it all in upper case. Another option would be to store the configuration file outside of the container and edit it directly.

## Documentation

Documentation for Graylog is hosted [here](http://docs.graylog.org/). Please read through the docs and familiarize yourself with the functionality before opening an [issue on GitHub](https://github.com/Graylog2/graylog2-server/issues).

## License

This Docker image is licensed under the Apache 2.0 license, see [LICENSE](LICENSE).

Graylog itself is licensed under the GNU Public License 3.0, see [license information](https://github.com/Graylog2/graylog2-server/blob/master/COPYING).
