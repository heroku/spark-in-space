#!/usr/bin/env bash


export SPARK_LOCAL_IP=$HEROKU_PRIVATE_IP

export SPARK_PUBLIC_DNS=$HEROKU_DNS_DYNO_NAME

# if there is a KAFKA_ZOOKEEPER_URL set, setup HA for spark masters
if ! [ -z "$KAFKA_ZOOKEEPER_URL" ]; then
  zkurl=$(echo $KAFKA_ZOOKEEPER_URL | sed 's/zookeeper\:\/\///g')
  export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.dir=/spark -Dspark.deploy.zookeeper.url=$zkurl"
fi
