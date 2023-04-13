Graylog Data Node Image
=======================

tbd

## Usage

### Docker Compose Example

```yaml
---
services:
  graylog-datanode:
    image: "graylog/graylog-datanode:dev"
  environment:
    GRAYLOG_DATANODE_PASSWORD_SECRET: "<password-secret>"
    GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2: "<root-pw-sha2>"
    GRAYLOG_DATANODE_MONGODB_URI: "mongodb://mongodb:27017/graylog"
  ports:
    - "127.0.0.1:9001:9001"  # Graylog Data Node REST API
    - "127.0.0.1:9200:9200"  # OpenSearch REST API
    - "127.0.0.1:9300:9300"  # OpenSearch Transport API
  volumes:
    - "graylog-datanode:/var/lib/graylog-datanode"

volumes:
  graylog-datanode:
```

### Environment Variables

| Variable | Default | Required | Description |
| :--- | :--- | :--- | :--- |
| `GRAYLOG_DATANODE_PASSWORD_SECRET` | none | yes | Password secret to seed secret storage. |
| `GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2` | none | yes | Password hash for the root user. |
| `GRAYLOG_DATANODE_MONGODB_URI` | none | yes | URI to the MongoDB instance and database. |
| `GRAYLOG_DATANODE_DATA_DIR` | `/var/lib/graylog-datanode` | no | The data root directory. (e.g., OpenSearch data) |
| `GRAYLOG_DATANODE_NODE_NAME` | container hostname | no | The OpenSearch node name. |
| `GRAYLOG_DATANODE_OPENSEARCH_DISCOVERY_SEED_HOSTS` | none | no | tbd |
