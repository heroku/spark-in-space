### spark-in-space

requires: a private space with dns-discovery enabled

```
git clone https://github.com/heroku/spark-in-space
cd spark-in-space
heroku create your-spark-app --space your-dns-enabled-space
# have a herokai with sudo add this to your app until run-inside is released
# heroku sudo labs:enable dyno-run-inside -a your-spark-app
heroku buildpacks:add http://github.com/kr/heroku-buildpack-inline.git -a your-spark-app
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-jvm-common.git -a your-spark-app
git push heroku master
heroku scale master=1 worker=2:private-l -a your-spark-app
heroku logs -a your-spark-app -t
```

once you see the master online and the workers registered, you can verify the workers do work by

```
heroku run:inside master.1 bash -a your-spark-app
./bin/spark-shell
sc.parallelize(1 to 1000000).reduce(_ + _)
```

### viewing spark ui

there is an nginx server that can proxy to any dyno in the space.

To set a cookie so that you proxy to the spark master, hit the following url

`http://<your-spark-app>.herokuapp.com/set-backend/1.master.<your-spark-app>.app.localspace:7077`

then go to

`http://<your-spark-app>.herokuapp.com`

You will see proxied version of the spark master UI. You can hit the `/set-backend` path with other in-space hostname:port combos
to be able to see workers and driver program ui.


### TODO:

* example s3 hdfs config via bucketeer
* zookeeper based HA spark master
* factor into a buildpack that can be added to any jvm app, which gets the master,worker,web procs made available.