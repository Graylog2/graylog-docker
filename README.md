# Graylog Docker Image

Latest stable version of Graylog is *2.5.0* this Version is available with the tags `2.5` or `2.5.0-1`. 

[![Build Status](https://travis-ci.org/Graylog2/graylog-docker.svg?branch=2.5)](https://travis-ci.org/Graylog2/graylog-docker) [![Docker Stars](https://img.shields.io/docker/stars/graylog/graylog.svg)][hub] [![Docker Pulls](https://img.shields.io/docker/pulls/graylog/graylog.svg)][hub] [![Image Size](https://images.microbadger.com/badges/image/graylog/graylog:2.5.svg)][microbadger] [![Image Version](https://images.microbadger.com/badges/version/graylog/graylog:2.5.svg)][microbadger] [![Image License](https://images.microbadger.com/badges/license/graylog/graylog:2.5.svg)][microbadger]

In the current development branch we have builds for the upcoming versions available. Those images can be identified in the [tag overview](https://hub.docker.com/r/graylog/graylog/tags/) of Docker Hub. Currently available are:


- `3.0.0-alpha.5-1` [![Build Status](https://travis-ci.org/Graylog2/graylog-docker.svg?branch=3.0)](https://travis-ci.org/Graylog2/graylog-docker)


[hub]: https://hub.docker.com/r/graylog/graylog/
[microbadger]: https://microbadger.com/images/graylog/graylog

Use the stable `2.5` release for your production environments. Please check the [latest stable documentation](http://docs.graylog.org/en/stable/pages/installation/docker.html) for complete installation and configuration instruction.


## What is Graylog?

Graylog is a centralized logging solution that allows the user to aggregate and search through logs. It provides a powerful query language, a processing pipeline for data transformation, alerting abilities and much more. It is fully extensible through a REST API. Add-Ons can be downloaded from the [Graylog Marketplace](https://marketplace.graylog.org/).

## Architecture

Take a look at the minimal [Graylog architecture](http://docs.graylog.org/en/stable/pages/architecture.html) to get the big picture of a Graylog setup. In essence, Graylog needs to talk to MongoDB to store configuration data as well as Elasticsearch to store the actual log data.

## How to use this image

Please refer to the [Graylog Docker documentation](http://docs.graylog.org/en/stable/pages/installation/docker.html) for a comprehensive overview and a detailed description of the Graylog Docker image.

## Configuration

Every configuration option can be set via environment variables, take a look [here](http://docs.graylog.org/en/stable/pages/configuration/server.conf.html) for an overview. Simply prefix the parameter name with `GRAYLOG_` and put it all in upper case. Another option would be to store the configuration file outside of the container and edit it directly.

## Documentation

Documentation for Graylog is hosted [here](http://docs.graylog.org/). Please read through the docs and familiarize yourself with the functionality before opening an [issue on GitHub](https://github.com/Graylog2/graylog2-server/issues).

## License

This Docker image is licensed under the Apache 2.0 license, see [LICENSE](LICENSE).

Graylog itself is licensed under the GNU Public License 3.0, see [license information](https://github.com/Graylog2/graylog2-server/blob/master/COPYING).
