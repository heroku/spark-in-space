### spark-in-space 

Heroku Button deploy of an Apache Spark cluster.

requires: a private space with dns-discovery enabled, *NOTE* dont use the button if you have a non dns-discovery space, it will absolutely not work.

If you use this cluster for real work, please protect it by adding a domain and ssl cert.

You should probably right-click 'open link in new window' on the button so you can follow the readme here. As long as this repo is private you will need to oauth your github account to the heroku dashboard.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/heroku/spark-in-space)

Note: The rest of this readme assumes you have set your app name as `$app` in your shell, like so `app=my-spark-cluster`.

Once your button deploy completes, you can tail the logs and see the master come online and the workers connect to it.

```
heroku logs -t -a $app
```

once you see the master online and the workers registered, you can verify the workers do work by:

```
heroku run bin/spark-shell -a $app
sc.parallelize(1 to 1000000).reduce(_ + _)
```

Note that this will take about 2 minutes to start up. If you ask a herokai to enable the `dyno-run-inside` feature on your app, 
you can then scale up a console process and use run:inside to get instant consoles.

```
heroku scale console=1 -a $app
# wait for console.1 to be up
heroku run:inside console.1 bin/spark-shell -a $app
sc.parallelize(1 to 1000000).reduce(_ + _)
```


ou can view the spark master by running the `heroku open -a $app` command, assuming you set the `SPACE_PROXY_DEFAULT_BACKEND` to `1.master.$app.app.localspace:8080` 
when creating the app.  If not, or to change it you can run

```
heroku config:set SPACE_PROXY_DEFAULT_BACKEND=1.master.$app.app.localspace:8080 -a app
heroku logs -t -a $app
#wait for master to restart
heroku open -a $app
```

The default basic auth credentials are `spark:space`, and can be changed
by updating the `SPACE_PROXY_BASIC_AUTH` config var, which by default is set to nginx PLAIN format, `spark:{PLAIN}space`


to add more worker nodes to your spark cluster, simply scale the worker processes.

```
heroku scale worker=5 -a $app
```

to make use of more worker nodes by default, set the config var:

* `SPARK_DEFAULT_CORES`: default **4**; see [Resource Scheduling](http://spark.apache.org/docs/1.6.1/spark-standalone.html#resource-scheduling)

to change the memory allocated to Spark, set the config vars:

* `SPARK_EXECUTOR_MEMORY`: default **12g**; see [Application Properties](https://spark.apache.org/docs/1.6.1/configuration.html#application-properties)
* `SPARK_DRIVER_MEMORY`: default **2g**; see [Application Properties](https://spark.apache.org/docs/1.6.1/configuration.html#application-properties)

individual jobs may be tuned for memory & core utilization with [`spark-submit` options](http://spark.apache.org/docs/1.6.1/submitting-applications.html#launching-applications-with-spark-submit), examples:

* `--executor-memory 4G`
* `--total-executor-cores 16`

### viewing spark ui

There is an nginx server that can proxy to any dyno in the space. The server will default you to proxying to the master.1 spark process.

[As of Spark 2.1.0](https://issues.apache.org/jira/browse/SPARK-15487), a new configuration supports improved UI functionality when served through a this kind of reverse proxy. To enable the reverse proxy behavior, set the fully-qualified hostname that clients use to access Spark Master UI:

```bash
# Point to your custom domain/SSL endpoint for the Spark in Space deployment:
heroku config:set SPARK_REVERSE_PROXY_URL=https://spark-in-space.example.com

# …or if you're using the plain HTTP Space app URLs:
heroku config:set SPARK_REVERSE_PROXY_URL=http://<your-spark-app>.herokuapp.com
```

To set a cookie so that you proxy to the spark master, hit the following url

`http://<your-spark-app>.herokuapp.com/set-backend/1.master.<your-spark-app>.app.localspace:8080`

you will be redirected to the root web ui of the backend you have selected.

You will see proxied version of the spark master UI. You can hit the `/set-backend` path with other in-space hostname:port combos
to be able to see workers and driver program ui.

Some examples:

* Go to the UI for worker.7 in your spark cluster `http://<your-spark-app>.herokuapp.com/set-backend/7.worker.<your-spark-app>.app.localspace:8081`
* Go to the UI for a jobs' driver process, in this example running as `job.1` in the app `your-spark-job` `http://<your-spark-app>.herokuapp.com/set-backend/1.job.<your-spark-job>.app.localspace:4040`

### Logging

The `LOG_LEVEL` environment variable controls the log4j log level for spark, it defaults to INFO, but you may set it to any 
valid level. INFO provides a lot of logging so you can see things are working properly, but can slow things down.
A better setting for real use is `heroku config:set LOG_LEVEL=WARN -a $app`.

### S3 HDFS

You can use s3 as an hdfs compatible filesystem by installing the `bucketeer` addon, using the `--as SPARK_S3` option. 

This is provided by the button deploy.

If you do this, bucketeer will set `SPARK_S3_BUCKET_NAME`, `SPARK_S3_AWS_ACCESS_KEY_ID`, `SPARK_S3_AWS_SECRET_ACCESS_KEY` config vars.

This will be detected and cause the writing of proper defaults to spark-defaults.conf. You can then use s3n:// or s3a:// urls in spark.

If you are deploying this app manually or dont need S3 HDFS, you can skip or remove the bucketeer adddon and the spark cluster should still function, just without S3 access.

To try out the S3 functionality, you can do the following.

```
heroku run:inside console.1 bash -a your-spark-app
./bin/spark-shell

val bucket = sys.env("SPARK_S3_BUCKET_NAME")
val file = s"s3a://$bucket/test-object-file"
val ints = sc.makeRDD(1 to 10000)
ints.saveAsObjectFile(file)
### lots of spark output

:q

./bin/spark-shell
val bucket = sys.env("SPARK_S3_BUCKET_NAME")
val file = s"s3a://$bucket/test-object-file"
val theInts = sc.objectFile[Int](file)
theInts.reduce(_ + _)
### lots of spark output
res0: Int = 50005000
```

### Multiple and HA Spark Masters

If you set the `SPARK_MASTERS` config var to a number greater than 1, then workers, spark-submit and spark-shell will use spark master urls that point at
the number of masters you specify.
 
For example, If you want 3 masters, you should `heroku scale master=3 -a $app`, then `heroku config:set SPARK_MASTERS=3 -a $app`, and the master url will be

`spark://1.master.$app.app.localspace:7077,2.master.$app.app.localspace:7077,3.master.$app.app.localspace:7077`

High availability spark masters require zookeeper.

If there is a `SPARK_ZK_ZOOKEEPER_URL` set, then the spark processes will be configured to use zookeeper for recovery.

the `SPARK_ZK_ZOOKEEPER_URL` should be of the following form for a 3 node cluster `zookeeper://10.1.1.1:2181,zookeeper://10.1.1.2:2181,zookeeper://10.1.1.3:2181`

### Spark Versions

This repo, when used as a buildpack, can support:

* Spark 1.4.1 for Hadoop 2.6
* Spark 1.6.1 for Hadoop 2.6 (default)
* Spark 2.0.0 for Hadoop 2.7

To use a specific version, place a file named `.spark.version` in the root of your project, containing the Spark version number, e.g. `1.4.1` or `2.0.0`.
