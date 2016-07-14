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
``

once you see the master online and the workers registered, you can verify the workers do work by

```
heroku run:inside master.1 bash -a your-spark-app
./spark-home/bin/spark-shell --master spark://$HEROKU_PRIVATE_IP:7077
sc.parallelize(1 to 1000000).reduce(_ + _)
```


### TODO:

* add nginx proxy to master web ui
* example s3 hdfs config via bucketeer