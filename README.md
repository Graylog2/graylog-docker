[![Docker Stars](https://img.shields.io/docker/stars/graylog/graylog.svg)][hub] [![Docker Pulls](https://img.shields.io/docker/pulls/graylog/graylog.svg)][hub]

[hub]: https://hub.docker.com/r/graylog/graylog/

# Graylog Docker image

The latest stable version of Graylog is `4.2.0`, which is available via tags `4.2`, `4.2.0`, and `4.2.0-1`.

Consider using the stable `4.2` release for your production environments. Please check the [Graylog Docker documentation](https://docs.graylog.org/docs/docker) for complete installation and configuration instructions.


## What is Graylog?

Graylog is a centralized logging solution that enables aggregating and searching through logs. It provides a powerful query language, a processing pipeline for data transformation, alerting abilities, and much more. It is fully extensible through a REST API. Add-ons can be downloaded from the [Graylog Marketplace](https://marketplace.graylog.org/).

## Architecture

Take a look at the minimal [Graylog architecture](https://docs.graylog.org/docs/architecture) to get the big picture of a Graylog setup. In essence, Graylog needs to talk to MongoDB to store configuration data as well as Elasticsearch to store the actual log data.


## Configuration

Please refer to the [Graylog Docker documentation](https://docs.graylog.org/docs/docker) for a comprehensive overview and detailed description of the Graylog Docker image.

If you want to quickly spin up an instance for testing, you can use our [Docker Compose template](https://github.com/Graylog2/docker-compose).

Notably, this image **requires** that two important configuration options be set (although in practice you will likely need to set more):
1. `password_secret` (environment variable `GRAYLOG_PASSWORD_SECRET`)
    * A secret that is used for password encryption and salting.
    * Must be at least 16 characters, however using at least 64 characters is strongly recommended.
    * Must be the same on all Graylog nodes in the cluster.
    * May be generated with something like: `pwgen -N 1 -s 96`
2. `root_password_sha2` (environment variable `GRAYLOG_ROOT_PASSWORD_SHA2`)
    * A SHA2 hash of a password you will use for your initial login as Graylog's root user.
      * The default username is `admin`.  This value is customizable via configuration option `root_username` (environment variable `GRAYLOG_ROOT_USERNAME`).
    * In general, these credentials will only be needed to initially set up the system or reconfigure the system in the event of an authentication backend failure.
    * This password cannot be changed using the API or via the Web interface.
    * May be generated with something like: `echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1`


Every [Graylog configuration option](https://docs.graylog.org/docs/server-conf) can be set via environment variable. To get the environment variable name for a given configuration option, simply prefix the option name with `GRAYLOG_` and put it all in upper case. Another option is to store the configuration file outside of the container and edit it directly.

This image includes the [wait-for-it](https://github.com/vishnubob/wait-for-it) script, which allows you to have Docker wait for Elasticsearch to start up before starting Graylog. For example, if you are using Docker Compose you could override the entrypoint for Graylog like this:

`entrypoint: /usr/bin/tini -- wait-for-it elasticsearch:9200 --  /docker-entrypoint.sh`


## Image Details

There are several different image variants available.

#### `graylog:<version>`

This is the open source Graylog image. You can check the Docker Hub page for [a list of all available versions](https://hub.docker.com/r/graylog/graylog/tags)

The standard image runs on Debian and Java 8. There are also ARM64 and Java 11 variants.


#### `graylog-enterprise:<version>`

This is the [Graylog Enterprise](https://docs.graylog.org/docs/intro) image. The versions available can be found on [Docker Hub](https://hub.docker.com/r/graylog/graylog-enterprise/tags).

It's using Debian and Java 8. There are ARM64 and Java 11 variants as well.


#### `graylog-forwarder:<version>`

This image runs the [Graylog Forwarder](https://docs.graylog.org/docs/forwarder). You can check the Docker Hub page for [a list of all available versions](https://hub.docker.com/repository/docker/graylog/graylog-forwarder/tags)




## Documentation

Documentation for Graylog is hosted [here](https://docs.graylog.org/). Please read through the docs and familiarize yourself with the functionality before opening an [issue on GitHub](https://github.com/Graylog2/graylog2-server/issues).

## License

Graylog itself is licensed under the Server Side Public License (SSPL), see [license information](https://www.mongodb.com/licensing/server-side-public-license).

This Docker image is licensed under the Apache 2.0 license, see [LICENSE](LICENSE).
