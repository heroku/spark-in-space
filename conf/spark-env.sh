#!/usr/bin/env bash


export SPARK_LOCAL_IP=$HEROKU_PRIVATE_IP

export SPARK_PUBLIC_DNS=$HEROKU_DNS_DYNO_NAME

# if there is a SPARK_ZK_ZOOKEEPER_URL set, setup HA for spark masters
if ! [ -z "$SPARK_ZK_ZOOKEEPER_URL" ]; then
  zkurl=$(echo $SPARK_ZK_ZOOKEEPER_URL | sed 's/zookeeper\:\/\///g')
  export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.dir=/$HEROKU_DNS_APP_NAME -Dspark.deploy.zookeeper.url=$zkurl"
fi

export LD_LIBRARY_PATH=/app/spark-home/lib