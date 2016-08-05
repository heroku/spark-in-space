### spark-in-space 

requires: a private space with dns-discovery enabled, *NOTE* dont use the button if you have a non dns-discovery space, it will absolutely not work.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/heroku/spark-in-space/tree/button)


Once your button deploy completes, wait for the kafka cluster to become available (its zookeeper provides spark master HA).

```
app=<your app name>
heroku kafka:wait -a $app
```

Once the kafka is available, you can tail the logs and see the master come online and the workers connect to it.

```
heroku logs -t -a $app
```

once you see the master online and the workers registered, you can verify the workers do work by:

```
heroku run console.1 bin/spark-shell -a $apps
sc.parallelize(1 to 1000000).reduce(_ + _)
```

you can view the spark master by:

```
heroku open -a $app
```


### viewing spark ui

there is an nginx server that can proxy to any dyno in the space. The server will default you to proxying to the master.1 spark process.

To set a cookie so that you proxy to the spark master, hit the following url

`http://<your-spark-app>.herokuapp.com/set-backend/1.master.<your-spark-app>.app.localspace:8080`

you will be redirected to the root web ui of the backend you have selected.

You will see proxied version of the spark master UI. You can hit the `/set-backend` path with other in-space hostname:port combos
to be able to see workers and driver program ui.

### HA Spark Masters

High availability spark masters are provided by the heroku button deploy. They are accomplished by adding a heroku kafka addon, and utilizing the zookeeper server available in the addon.

If there is a `KAFKA_ZOOKEEPER_URL` set, then the spark processes will be configured to use zookeeper for recovery.

If you set the `SPARK_MASTERS` config var to a number greater than 1, then workers and spark-shell will use spark master urls that point at
the number of masters you specify.

For example if `SPARK_MASTERS` is set to 3 on the app `your-app`, the master url will be

`spark://1.master.your-app.app.localspace:7077,2.master.your-app.app.localspace:7077,3.master.your-app.app.localspace:7077`

If you are deploying this app manually, or dont need HA spark masters, you can skip or remove the kafka addon and the spark cluster should still function, just without HA.

### S3 HDFS

You can use s3 as an hdfs compatible filesystem by installing the `bucketeer` addon, with the `--as SPARK` option. 

This is provided by the button deploy.

If you do this, bucketeer will set `SPARK_BUCKET_NAME`, `SPARK_AWS_ACCESS_KEY_ID`, `SPARK_AWS_SECRET_ACCESS_KEY` config vars.

This will be detected and cause the writing of proper defaults to spark-defaults.conf. You can then use s3a:// urls in spark.

If you are deploying this app manually or dont need S3 HDFS, you can skip or remove the bucketeer adddon and the spark cluster should still function, just without S3 access.

To try out the S3 functionality, you can do the following.

```
heroku run:inside console.1 bash -a your-spark-app
./bin/spark-shell

val bucket = sys.env("SPARK_BUCKET_NAME")
val file = s"s3a://$bucket/test-object-file"
val ints = sc.makeRDD(1 to 10000)
ints.saveAsObjectFile(file)
### lots of spark output

:q

./bin/spark-shell
val bucket = sys.env("SPARK_BUCKET_NAME")
val file = s"s3a://$bucket/test-object-file"
val theInts = sc.objectFile[Int](file)
theInts.reduce(_ + _)
### lots of spark output
res0: Int = -2004260032
```

