version: '2'
services:
  # MongoDB: https://hub.docker.com/_/mongo/
  mongodb:
    image: mongo:5.0
    mem_limit: 128m

  opensearch:
    image: "opensearchproject/opensearch:1.3.6"
    environment:
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m -Dlog4j2.formatMsgNoLookups=true"
      - "discovery.type=single-node"
      - "logger.deprecation.level=warn"
      - "action.auto_create_index=false"
      - "bootstrap.memory_lock=true"
      - "plugins.security.ssl.http.enabled=false"
      - "plugins.security.disabled=true"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    mem_limit: 1g

  graylog:
    build:
      context: ..
      dockerfile: docker/oss/Dockerfile
      args:
        - VCS_REF
        - GRAYLOG_VERSION
    entrypoint: /usr/bin/tini -- wait-for-it opensearch:9200 --  /docker-entrypoint.sh
    environment:
      # CHANGE ME!
      - GRAYLOG_PASSWORD_SECRET=somepasswordpepper
      # Password: admin
      - GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      - GRAYLOG_MESSAGE_JOURNAL_ENABLED=false
      - GRAYLOG_NODE_ID_FILE=/usr/share/graylog/data/config/node-id
      - GRAYLOG_ELASTICSEARCH_HOSTS=http://opensearch:9200/
      - GRAYLOG_MONGODB_URI=mongodb://mongodb:27017/graylog
      # - GRAYLOG_HTTP_EXTERNAL_URI=http://127.0.0.1:9000/
    mem_limit: 1g
    ports:
      # Graylog web interface and REST API
      - 9000:9000
      # Syslog TCP input
      - 514:514
      # Raw/Plaintext input
      - 5555:5555
    restart: always
    depends_on:
      - opensearch
      - mongodb
