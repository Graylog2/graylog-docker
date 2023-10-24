# Graylog Data Node Docker Image

[![Docker Stars](https://img.shields.io/docker/stars/graylog/graylog.svg)][hub] [![Docker Pulls](https://img.shields.io/docker/pulls/graylog/graylog.svg)][hub]

[hub]: https://hub.docker.com/r/graylog/graylog/

The latest stable version of Graylog Data Node is **`5.2.0-rc.1`**.

## What is Graylog Data Node?

Graylog is a centralized logging solution that enables aggregating and searching through logs. 
The Data Node is our wrapper around OpenSearch to provide better support/management.


## Image Details

There are images for the `linux/amd64` and `linux/arm64` platforms available. All images are based on the latest [Eclipse Temurin image](https://hub.docker.com/_/eclipse-temurin) (JRE + Ubuntu LTS variant) available at build time.

#### `graylog/graylog-datanode`


| Java Version  | Platform  | Tags  |
|---|---|---|
| OpenJDK 17 | `linux/amd64`, `linux/arm64` | `5.2.0-rc.1-1` |


> Note: There is no 'latest' tag. You'll need to specify which version you want.


## Configuration

Please refer to the [Graylog Docker documentation](https://docs.graylog.org/docs/docker) for a comprehensive overview and detailed description of the Graylog Docker image.

If you want to quickly spin up an instance for testing, you can use our [Docker Compose template](https://github.com/Graylog2/docker-compose).

Notably, this image **requires** that two important configuration options be set (although in practice you will likely need to set more):
1. `password_secret` (environment variable `GRAYLOG_DATANODE_PASSWORD_SECRET`)
    * A shared common secret with Graylog. Please refer to the Graylog docs on how to create it (and then, copy it over)
2. `root_password_sha2` (environment variable `GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2`)
    * A SHA2 hash of a password you will use for your initial login as Graylog's root user.
        * The default username is `admin`.  This value is customizable via configuration option `root_username` (environment variable `GRAYLOG_ROOT_USERNAME`).
    * In general, these credentials will only be needed to initially set up the system or reconfigure the system in the event of an authentication backend failure.
    * This password cannot be changed using the API or via the Web interface.
    * May be generated with something like: `echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1`


Every [Graylog DataNode configuration option](https://docs.graylog.org/docs/server-conf) can be set via environment variable. To get the environment variable name for a given configuration option, simply prefix the option name with `GRAYLOG_DATANODE_` and put it all in upper case. Another option is to store the configuration file outside of the container and edit it directly.

### Docker Compose Example

```yaml
---
services:
  graylog-datanode:
#    hostname: "datanode"
    image: "graylog/graylog-datanode:5.2"
    depends_on:
      - "mongodb"
    environment:
      GRAYLOG_DATANODE_PASSWORD_SECRET: "<password-secret>"
      GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2: "<root-pw-sha2>"
      GRAYLOG_DATANODE_ROOT_USERNAME: "<admin user name>"
      GRAYLOG_DATANODE_MONGODB_URI: "mongodb://mongodb:27017/graylog"
    ulimits:
      memlock:
        hard: -1
        soft: -1
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - "127.0.0.1:8999:8999"  # Graylog Data Node REST API
      - "127.0.0.1:9200:9200"  # OpenSearch REST API
      - "127.0.0.1:9300:9300"  # OpenSearch Transport API
    volumes:
      - "graylog-datanode:/var/lib/graylog-datanode"

  mongodb:
    image: "mongo:5.0"
    ports:
      - "127.0.0.1:27017:27017"
    volumes:
      - "mongodb:/data/db"

volumes:
  graylog-datanode:
  mongodb:

```

Enable `hostname: "datanode"` in `docker-compose.yml` and `datanode` as an alias for your IPv4/IPv6 addresses for localhost, if you want to only run it as above and connect from within a running graylog in IntelliJ during develpoment.

### Environment Variables

| Variable | Default | Required | Description |
| :--- | :--- | :--- |:----------------------------------------------------------|
| `GRAYLOG_DATANODE_PASSWORD_SECRET` | none | yes | Password secret to seed secret storage. Must be the same value as the `password_secret` in the Graylog server configuration. |
| `GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2` | none | yes | Password hash for the root user. |
| `GRAYLOG_DATANODE_ROOT_USERNAME` | `admin` | yes | Name of the root user. |
| `GRAYLOG_DATANODE_MONGODB_URI` | none | yes | URI to the MongoDB instance and database. |
| `GRAYLOG_DATANODE_DATA_DIR` | `/var/lib/graylog-datanode` | no | The data root directory. (e.g., OpenSearch data) |
| `GRAYLOG_DATANODE_NODE_NAME` | container hostname | no | The OpenSearch node name. |
| `GRAYLOG_DATANODE_OPENSEARCH_DISCOVERY_SEED_HOSTS` | none | no | tbd |





## Documentation

Documentation for Graylog is hosted [here](https://docs.graylog.org/). Please read through the docs and familiarize yourself with the functionality before opening an [issue on GitHub](https://github.com/Graylog2/graylog2-server/issues).

## License

Graylog itself is licensed under the Server Side Public License (SSPL), see [license information](https://www.mongodb.com/licensing/server-side-public-license).

This Docker image is licensed under the Apache 2.0 license, see [LICENSE](LICENSE).
