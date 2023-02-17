---
title: "Elasticsearch Cluster Docker方式搭建"
date: 2022-08-09T18:49:28+08:00
draft: false
categories: ["Elasticsearch"]
tags: ["Elasticsearch"]
summary: "用Docker搭建Elasticsearch Cluster"
---

## 环境准备(有密码)

- 注意需要将`.env`和`docker-compose.yml`放在同一文件夹下
- **此处为有密码的配置，无密码的在后面**

### .env

>.env文件设置运行Docker-compose.yml配置文件时使用的环境变量。确保使用Elastic_Password和Kibana_password变量为Elastic和Kibana_System用户指定强密码。这些变量由docker-compose.yml文件引用。

```
# elastic password 自己随意
ELASTIC_PASSWORD=123456

# kibana password 自己随意
KIBANA_PASSWORD=abcdefg

# es version
STACK_VERSION=8.3.3

# cluster name
CLUSTER_NAME=elasticsearch-8.3.3-push

# license choose basic
LICENSE=basic

# es port
ES_PORT=9200

# kibana port
KIBANA_PORT=5601

# es mem limit
# MEM_LIMIT=1073741824 1G在8.3.3会启动报错，设置4G可以启动
MEM_LIMIT=4294967296

# compose name
COMPOSE_PROJECT_NAME=push
```

### docker-compose.yml
从官网拷贝`docker-compose.yml`

>此Docker-compose.yml文件创建了一个三节点安全的Elasticsearch群集，并启用了身份验证和网络加密，并且将Kibana实例安全地连接到了它。

```yml
version: "2.2"

services:
  setup:
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    user: "0"
    command: >
      bash -c '
        if [ x${ELASTIC_PASSWORD} == x ]; then
          echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
          exit 1;
        elif [ x${KIBANA_PASSWORD} == x ]; then
          echo "Set the KIBANA_PASSWORD environment variable in the .env file";
          exit 1;
        fi;
        if [ ! -f config/certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f config/certs/certs.zip ]; then
          echo "Creating certs";
          echo -ne \
          "instances:\n"\
          "  - name: es01\n"\
          "    dns:\n"\
          "      - es01\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          "  - name: es02\n"\
          "    dns:\n"\
          "      - es02\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          "  - name: es03\n"\
          "    dns:\n"\
          "      - es03\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          > config/certs/instances.yml;
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions"
        chown -R root:root config/certs;
        find . -type d -exec chmod 750 \{\} \;;
        find . -type f -exec chmod 640 \{\} \;;
        echo "Waiting for Elasticsearch availability";
        until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
        echo "Setting kibana_system password";
        until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
        echo "All done!";
      '
    healthcheck:
      test: ["CMD-SHELL", "[ -f config/certs/es01/es01.crt ]"]
      interval: 1s
      timeout: 5s
      retries: 120

  es01:
    depends_on:
      setup:
        condition: service_healthy
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - esdata01:/usr/share/elasticsearch/data
    ports:
      - ${ES_PORT}:9200
    environment:
      - node.name=es01
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02,es03
      - discovery.seed_hosts=es02,es03
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es01/es01.key
      - xpack.security.http.ssl.certificate=certs/es01/es01.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es01/es01.key
      - xpack.security.transport.ssl.certificate=certs/es01/es01.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=${LICENSE}
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  es02:
    depends_on:
      - es01
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - esdata02:/usr/share/elasticsearch/data
    environment:
      - node.name=es02
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02,es03
      - discovery.seed_hosts=es01,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es02/es02.key
      - xpack.security.http.ssl.certificate=certs/es02/es02.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es02/es02.key
      - xpack.security.transport.ssl.certificate=certs/es02/es02.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=${LICENSE}
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  es03:
    depends_on:
      - es02
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - esdata03:/usr/share/elasticsearch/data
    environment:
      - node.name=es03
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02,es03
      - discovery.seed_hosts=es01,es02
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es03/es03.key
      - xpack.security.http.ssl.certificate=certs/es03/es03.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es03/es03.key
      - xpack.security.transport.ssl.certificate=certs/es03/es03.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=${LICENSE}
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  kibana:
    depends_on:
      es01:
        condition: service_healthy
      es02:
        condition: service_healthy
      es03:
        condition: service_healthy
    image: docker.elastic.co/kibana/kibana:${STACK_VERSION}
    volumes:
      - certs:/usr/share/kibana/config/certs
      - kibanadata:/usr/share/kibana/data
    ports:
      - ${KIBANA_PORT}:5601
    environment:
      - SERVERNAME=kibana
      - ELASTICSEARCH_HOSTS=https://es01:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
      - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
    mem_limit: ${MEM_LIMIT}
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

volumes:
  certs:
    driver: local
  esdata01:
    driver: local
  esdata02:
    driver: local
  esdata03:
    driver: local
  kibanadata:
    driver: local
```

## 启动

### 启动方式

在`docker-compose.yml`所在文件夹下，执行启动命令

`docker-compose up -d`

然后，查看启动状态，意外看到`Exited (137)`，这是为了节省内存，设置的`MEM_LIMIT=1G`太小了导致的，重新设置为`4G`。修改`.env`文件，重新启动。

查看启动日志
```
docker logs push_setup_1
Creating CA
Archive:  config/certs/ca.zip
   creating: config/certs/ca/
  inflating: config/certs/ca/ca.crt
  inflating: config/certs/ca/ca.key
Creating certs
Archive:  config/certs/certs.zip
   creating: config/certs/es01/
  inflating: config/certs/es01/es01.crt
  inflating: config/certs/es01/es01.key
   creating: config/certs/es02/
  inflating: config/certs/es02/es02.crt
  inflating: config/certs/es02/es02.key
   creating: config/certs/es03/
  inflating: config/certs/es03/es03.crt
  inflating: config/certs/es03/es03.key
Setting file permissions
Waiting for Elasticsearch availability
Setting file permissions
Waiting for Elasticsearch availability
Setting kibana_system password
All done!
```

### 其他问题

下载`es01`证书，用于curl访问

```
docker cp push_es01_1:/usr/share/elasticsearch/config/certs/es01/es01.crt .

curl --cacert es01.crt -u elastic -XGET "https://localhost:9200/"
```

然而还是报错了，看官网也没有其他步骤。
```
curl --cacert es01.crt -u elastic -XGET "https://localhost:9200/"
curl: (77) error setting certificate verify locations:
  CAfile: es01.crt
  CApath: /etc/ssl/certs
```

最后，从官网找到了答案。[Curl: (77) error setting certificate verify locations](https://discuss.elastic.co/t/curl-77-error-setting-certificate-verify-locations/308945)

```
sdev@n30-03-10:/data01/elasticsearch-8.3.3-docker$ sudo curl --cacert ca.crt -u elastic -XGET https://localhost:9200
Enter host password for user 'elastic':
{
  "name" : "es01",
  "cluster_name" : "elasticsearch-8.3.3-push",
  "cluster_uuid" : "95ByJfrVQrOr5GSZWm97ig",
  "version" : {
    "number" : "8.3.3",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "801fed82df74dbe537f89b71b098ccaff88d2c56",
    "build_date" : "2022-07-23T19:30:09.227964828Z",
    "build_snapshot" : false,
    "lucene_version" : "9.2.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

## 部署无密码集群

假如部署了带密码的集群，那就先删掉之前部署

- 如果不需要删除数据

在docker-compose.yml文件所在目录执行`docker-compose down`。

```
sdev@n30-03-10:/data01/elasticsearch-8.3.3-docker$ sudo docker-compose down
Stopping push_kibana_1 ... done
Stopping push_es03_1   ... done
Stopping push_es02_1   ... done
Stopping push_es01_1   ... done
Removing push_kibana_1 ... done
Removing push_es03_1   ... done
Removing push_es02_1   ... done
Removing push_es01_1   ... done
Removing push_setup_1  ... done
Removing network push_default
```

- 如果要删除之前部署的数据文件

```
sdev@n30-03-10:/data01/elasticsearch-8.3.3-nopass$ sudo docker volume ls
DRIVER              VOLUME NAME
local               push_certs
local               push_esdata01
local               push_esdata02
local               push_esdata03
local               push_kibanadata

# 删除命令
docker volume rm push_certs
...
```

修改文件`.env`

```
# elastic password
#ELASTIC_PASSWORD=123456

# kibana password
KIBANA_PASSWORD=abcdefg

# es version
STACK_VERSION=8.3.3

# cluster name
CLUSTER_NAME=elasticsearch-8.3.3-push

# license choose basic
LICENSE=basic

# es port
ES_PORT=9200

# kibana port
KIBANA_PORT=5601

# es mem limit
MEM_LIMIT=4294967296

# compose name
COMPOSE_PROJECT_NAME=push
```

修改`docker-compose.yml`文件

```yml
version: "2.2"

services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - esdata01:/usr/share/elasticsearch/data
    ports:
      - ${ES_PORT}:9200
    environment:
      - node.name=es01
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02,es03
      - discovery.seed_hosts=es02,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false
      - xpack.security.http.ssl.enabled=false
      - xpack.security.transport.ssl.enabled=false
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s http://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  es02:
    depends_on:
      - es01
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - esdata02:/usr/share/elasticsearch/data
    environment:
      - node.name=es02
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02,es03
      - discovery.seed_hosts=es01,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false
      - xpack.security.http.ssl.enabled=false
      - xpack.security.transport.ssl.enabled=false
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s http://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  es03:
    depends_on:
      - es02
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - esdata03:/usr/share/elasticsearch/data
    environment:
      - node.name=es03
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02,es03
      - discovery.seed_hosts=es01,es02
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false
      - xpack.security.http.ssl.enabled=false
      - xpack.security.transport.ssl.enabled=false
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s http://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  kibana:
    image: docker.elastic.co/kibana/kibana:${STACK_VERSION}
    volumes:
      - kibanadata:/usr/share/kibana/data
    ports:
      - ${KIBANA_PORT}:5601
    environment:
      - SERVERNAME=kibana
      - ELASTICSEARCH_HOSTS=http://es01:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
    mem_limit: ${MEM_LIMIT}
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

volumes:
  certs:
    driver: local
  esdata01:
    driver: local
  esdata02:
    driver: local
  esdata03:
    driver: local
  kibanadata:
    driver: local
```

然后启动

```
sdev@n30-03-10:/data01/elasticsearch-8.3.3-nopass$ sudo docker-compose up -d
Creating network "push_default" with the default driver
Creating push_kibana_1 ... done
Creating push_es01_1   ... done
Creating push_es02_1   ... done
Creating push_es03_1   ... done
``` 