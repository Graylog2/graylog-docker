# Graylog Docker image

The latest stable version of Graylog is `4.2.0`, which is available via tags `4.2`, `4.2.0`, and `4.2.0-1`.

[![Docker Stars](https://img.shields.io/docker/stars/graylog/graylog.svg)][hub] [![Docker Pulls](https://img.shields.io/docker/pulls/graylog/graylog.svg)][hub]

[hub]: https://hub.docker.com/r/graylog/graylog/

Consider using the stable `4.1` release for your production environments. Please check the [Graylog Docker documentation](https://docs.graylog.org/docs/docker) for complete installation and configuration instructions.


## What is Graylog?

Graylog is a centralized logging solution that enables aggregating and searching through logs. It provides a powerful query language, a processing pipeline for data transformation, alerting abilities, and much more. It is fully extensible through a REST API. Add-ons can be downloaded from the [Graylog Marketplace](https://marketplace.graylog.org/).

## Architecture

Take a look at the minimal [Graylog architecture](https://docs.graylog.org/docs/architecture) to get the big picture of a Graylog setup. In essence, Graylog needs to talk to MongoDB to store configuration data as well as Elasticsearch to store the actual log data.

## How to use this image

Please refer to the [Graylog Docker documentation](https://docs.graylog.org/docs/docker) for a comprehensive overview and detailed description of the Graylog Docker image.

## Configuration

Every [Graylog configuration option](https://docs.graylog.org/docs/server-conf) can be set via environment variable. To get the environment variable name for a given configuration option, simply prefix the option name with `GRAYLOG_` and put it all in upper case. Another option is to store the configuration file outside of the container and edit it directly.

This image includes the [wait-for-it](https://github.com/vishnubob/wait-for-it) script, which allows you to have Docker wait for Elasticsearch to start up before starting Graylog. For example, if you are using Docker Compose you could override the entrypoint for Graylog like this:

`entrypoint: /usr/bin/tini -- wait-for-it elasticsearch:9200 --  /docker-entrypoint.sh`


## Documentation

Documentation for Graylog is hosted [here](https://docs.graylog.org/). Please read through the docs and familiarize yourself with the functionality before opening an [issue on GitHub](https://github.com/Graylog2/graylog2-server/issues).

## License

Graylog itself is licensed under the Server Side Public License (SSPL), see [license information](https://www.mongodb.com/licensing/server-side-public-license).

This Docker image is licensed under the Apache 2.0 license, see [LICENSE](LICENSE).
