Graylog Data Node Image
=======================

tbd

## Usage

### Docker Compose Example

```yaml
---
services:
  graylog-datanode:
#    hostname: "datanode"
    image: "graylog/graylog-datanode:5.2-dev"
    depends_on:
      - "mongodb"
    environment:
      GRAYLOG_DATANODE_PASSWORD_SECRET: "<password-secret>"
      GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2: "<root-pw-sha2>"
      GRAYLOG_DATANODE_ROOT_USERNAME: "<admin user name>"
      GRAYLOG_DATANODE_MONGODB_URI: "mongodb://mongodb:27017/graylog"
      GRAYLOG_DATANODE_SINGLE_NODE_ONLY: "true"
    ulimits:
      memlock:
        hard: -1
        soft: -1
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - "127.0.0.1:9001:9001"  # Graylog Data Node REST API
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

| Variable | Default | Required | Description                                               |
| :--- | :--- | :--- |:----------------------------------------------------------|
| `GRAYLOG_DATANODE_PASSWORD_SECRET` | none | yes | Password secret to seed secret storage.                   |
| `GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2` | none | yes | Password hash for the root user.                          |
| `GRAYLOG_DATANODE_ROOT_USERNAME` | admin | yes |name of the root user.                          |
| `GRAYLOG_DATANODE_MONGODB_URI` | none | yes | URI to the MongoDB instance and database.                 |
| `GRAYLOG_DATANODE_DATA_DIR` | `/var/lib/graylog-datanode` | no | The data root directory. (e.g., OpenSearch data)          |
| `GRAYLOG_DATANODE_NODE_NAME` | container hostname | no | The OpenSearch node name.                                 |
| `GRAYLOG_DATANODE_SINGLE_NODE_ONLY` | `"false"` | no | Starts OpenSearch in single node mode when set to `true`. |
| `GRAYLOG_DATANODE_OPENSEARCH_DISCOVERY_SEED_HOSTS` | none | no | tbd |

