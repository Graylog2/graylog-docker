version: '2'
services:
  # MongoDB: https://hub.docker.com/_/mongo/
  mongo:
    image: mongo:4.2
    mem_limit: 128m
  # Elasticsearch: https://www.elastic.co/guide/en/elasticsearch/reference/6.x/docker.html
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.8.10
    environment:
      - http.host=0.0.0.0
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    mem_limit: 1g
  graylog:
    build:
      context: ..
      dockerfile: Dockerfile
      args:
        - VCS_REF
        - GRAYLOG_VERSION
    environment:
      # CHANGE ME!
      - GRAYLOG_PASSWORD_SECRET=somepasswordpepper
      # Password: admin
      - GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
      - GRAYLOG_MESSAGE_JOURNAL_ENABLED=false
      - GRAYLOG_NODE_ID_FILE=/usr/share/graylog/data/config/node-id
    mem_limit: 1g
    links:
      - mongo
      - elasticsearch
    ports:
      # Graylog web interface and REST API
      - 9000:9000
      # Syslog TCP input
      - 514:514
      # Raw/Plaintext input
      - 5555:5555
