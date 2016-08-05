### spark-in-space 

Heroku Button deploy of an (optionally highly available) Spark cluster.

requires: a private space with dns-discovery enabled, *NOTE* dont use the button if you have a non dns-discovery space, it will absolutely not work.

If you use this cluster for real work, please protect it by adding a domain and ssl cert.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/heroku/spark-in-space/tree/button)

Once your button deploy completes, you can tail the logs and see the master come online and the workers connect to it.

```
heroku logs -t -a $app
```

once you see the master online and the workers registered, you can verify the workers do work by:

```
heroku run console.1 bin/spark-shell -a $apps
sc.parallelize(1 to 1000000).reduce(_ + _)
```

you can view the spark master by running the command below. The default basic auth credentials are `spark:space`, and can be changed
by updating the `SPARK_BASIC_AUTH` config var, which by default is set to nginx PLAIN format, `spark:{PLAIN}space`

```
heroku open -a $app
```

to add more worker nodes to your spark cluster, simply scale the worker processes.

```
heroku scale worker=5 -a $app
```

### viewing spark ui

there is an nginx server that can proxy to any dyno in the space. The server will default you to proxying to the master.1 spark process.

To set a cookie so that you proxy to the spark master, hit the following url

`http://<your-spark-app>.herokuapp.com/set-backend/1.master.<your-spark-app>.app.localspace:8080`

you will be redirected to the root web ui of the backend you have selected.

You will see proxied version of the spark master UI. You can hit the `/set-backend` path with other in-space hostname:port combos
to be able to see workers and driver program ui.

### HA Spark Masters

High availability spark masters are accomplished by adding a heroku kafka addon, and utilizing the zookeeper server available in the addon.

If there is a `KAFKA_ZOOKEEPER_URL` set, then the spark processes will be configured to use zookeeper for recovery.

To add this addon do the following:

```
app=<your app name>
heroku addons:create heroku-kafka -a $app
heroku kafka:wait -a $app
```

Once the kafka is available, you can tail the logs and watch the master come back up and the workers connect to it.

If you set the `SPARK_MASTERS` config var to a number greater than 1, then workers, spark-submit and spark-shell will use spark master urls that point at
the number of masters you specify.
 
For example, If you want 3 masters, you should `heroku scale master=3 -a $app`, then `heroku config:set SPARK_MASTERS=3 -a $app`, and the master url will be

`spark://1.master.$app.app.localspace:7077,2.master.$app.app.localspace:7077,3.master.$app.app.localspace:7077`


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

