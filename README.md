This is a container that can be used to launch a simple master-slave cluster. The same container can be used as a master to bootstrap the cluster, as a sentinel or a read-only slave. Once up and running the bootstrap can be allowed to fail and the remaining instances will promote a slave to master.

Pre-built containers can be pulled from [Docker](https://hub.docker.com/r/memes/redis/).

# Environment

Environment variables are used to configure Redis at runtime

* REDIS_BOOTSTRAP_SERVICE_HOST is used to find/configure the bootstrap master instance. Defaults to ```bootstrap-service```
* REDIS_BOOTSTRAP_SERVICE_PORT defines the port that will be used for bootstrap master instance. Defaults to ```6379``` and _should be changed on platforms where different containers cannot use the same port_.
* REDIS_SENTINEL_SERVICE_HOST defines the load-balanced endpoint shared by all Redis Sentinels. Defaults to ```sentinel-service```
* REDIS_SENTINEL_SERVICE_PORT defines the port used by Redis Sentinel instances. Defaults to ```26379```
* REDIS_SERVICE_HOST is used to set the load-balanced endpoint used by all other Redis instances. Defaults to ```redis-service```
* REDIS_SERVICE_PORT is used to set the listening port for Redis instances other than bootstrap. Defaults to ```6379```
* LAUNCH_AS_BOOTSTRAP when set to a non-empty value will launch Redis container as a standalone master. Only one instance should be launched this way in any given cluster
* LAUNCH_AS_SENTINEL when set to a non-empty value will launch a Redis Sentinel that manages the master and slave instances
