# Supported tags and respective `Dockerfile` links
-	[`1.2`, `1.2.0`, `latest` (*tevjef/influxdb/1.2/Dockerfile*)](https://raw.githubusercontent.com/tevjef/influxdb-docker/master/1.2/Dockerfile)
-	[`1.1`, `1.1.1` (*tevjef/influxdb/1.1/Dockerfile*)](https://raw.githubusercontent.com/tevjef/influxdb-docker/master/1.1/Dockerfile)
-	[`1.0`, `1.0.2` (*tevjef/influxdb/1.0/Dockerfile*)](https://raw.githubusercontent.com/tevjef/influxdb-docker/master/1.0/Dockerfile)

This image is a fork of https://github.com/tutumcloud/influxdb with support for InfluxDB 1.1+

# InfluxDB

InfluxDB is a time series database built from the ground up to handle high write and query loads. InfluxDB is meant to be used as a backing store for any use case involving large amounts of timestamped data, including DevOps monitoring, application metrics, IoT sensor data, and real-time analytics.

[InfluxDB Documentation](https://docs.influxdata.com/influxdb/latest/)

![logo](https://raw.githubusercontent.com/docker-library/docs/43d87118415bb75d7bb107683e79cd6d69186f67/influxdb/logo.png)

### Running the container

The InfluxDB image exposes a shared volume under `/var/lib/influxdb`, so you can mount a host directory to that point to access persisted container data. A typical invocation of the container might be:

```console
$ docker run -p 8086:8086 \
      -v $PWD:/var/lib/influxdb \
      tevjef/influxdb
```

Modify `$PWD` to the directory where you want to store data associated with the InfluxDB container.

You can also have Docker control the volume mountpoint by using a named volume.

```console
$ docker run -p 8086:8086 \
      -v influxdb:/var/lib/influxdb \
      tevjef/influxdb
```

### Exposed Ports

The following ports are important and are used by InfluxDB.

-	8086 HTTP API port

The HTTP API port will be automatically exposed when using `docker run -P`.

The administrator interface is not automatically exposed when using `docker run -P`. While the administrator interface is run by default, the adminstrator interface requires that the web browser have access to InfluxDB on the same port in the container as from the web browser. Since `-P` exposes the HTTP port to the host on a random port, the administrator interface is not compatible with this setting.

Find more about API Endpoints & Ports [here](https://docs.influxdata.com/influxdb/latest/concepts/api/).

### Configuration

InfluxDB can be either configured from a config file or using environment variables. To mount a configuration file and use it with the server, you can use this command:

Generate the default configuration file:

```console
$ docker run --rm tevjef/influxdb influxd config > influxdb.conf
```

Modify the default configuration, which will now be available under `$PWD`. Then start the InfluxDB container.

```console
$ docker run -p 8086:8086 \
      -v $PWD/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
      tevjef/influxdb -config /etc/influxdb/influxdb.conf
```

Modify `$PWD` to the directory where you want to store the configuration file.

#### Environment Variables

For environment variables, the format is `INFLUXDB_$SECTION_$NAME`. All dashes (`-`) are replaced with underscores (`_`). If the variable isn't in a section, then omit that part.

Examples:

```console
INFLUXDB_REPORTING_DISABLED=true
INFLUXDB_META_DIR=/path/to/metadir
INFLUXDB_DATA_QUERY_LOG_ENABLED=false
```

The `tevjef/influxdb` image uses several environment variables which are easy to miss. While none of the variables are required, they may significantly aid you in using the image.

###### `INFLUXDB_CREATE_DB`

This optional environment variable can be used to define databases to be automatically created on the first time the container starts. Each database name is separated by `;`.

###### `INFLUXDB_CREATE_RP`

This optional environment variable is used in conjunction with `INFLUXDB_CREATE_DB` to create a default retention policy for a database. Each retention policy has the syntax
`<name>:<duration>`. Multiple retention policies are delimited by `;` with each policy mapping to one database. 

```
      -e INFLUXDB_CREATE_DB=db1;db2;db3 \
      -e INFLUXDB_CREATE_RP=db1_rp:2w;none;db3_rp:1d2h
```

It follows that databases `db1` and `db3` have retention policies `db1_rp:2w` and `db3_rp:1d2h` while `db2` has no retention policy.

###### `INFLUXDB_ADMIN_USER`

This optional environment variable is used to create a user with all privileges.

###### `INFLUXDB_ADMIN_PASSWORD`

This optional environment variable is used in conjunction with `INFLUXDB_ADMIN_USER` to set a user and its password. If it is not specified, then the default password `admin` will be used.

```
    docker run -d -p 8086:8086 -e INFLUXDB_ADMIN_USER="root" -e INFLUXDB_ADMIN_PASSWORD="somepassword" -e INFLUXDB_CREATE_DB="db1;db2;db3" tevjef/influxdb:latest
```

Find more about configuring InfluxDB [here](https://docs.influxdata.com/influxdb/latest/introduction/installation/)

### Graphite

InfluxDB supports the Graphite line protocol, but the service and ports are not exposed by default. To run InfluxDB with Graphite support enabled, you can either use a configuration file or set the appropriate environment variables. Run InfluxDB with the default Graphite configuration:

```console
docker run -p 8086:8086 \
    -e INFLUXDB_GRAPHITE_ENABLED=true \
    influxdb
```

See the [README on GitHub](https://github.com/influxdata/influxdb/blob/master/services/graphite/README.md) for more detailed documentation to set up the Graphite service. In order to take advantage of graphite templates, you should use a configuration file by outputting a default configuration file using the steps above and modifying the `[[graphite]]` section.

### HTTP API

Creating a DB named mydb:

```console
$ curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE mydb"
```

Inserting into the DB:

```console
$ curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary 'cpu_load_short,host=server01,region=us-west value=0.64 1434055562000000000'
```

Read more about this in the [official documentation](https://docs.influxdata.com/influxdb/latest/guides/writing_data/)

### CLI / SHELL

Start the container:

```console
$ docker run --name=influxdb -d -p 8086:8086 tevjef/influxdb
```

Run the influx client in another container:

```console
$ docker run --rm --net=container:influxdb -it tevjef/influxdb influx -host influxdb
```

At the moment, you cannot use `docker exec` to run the influx client since `docker exec` will not properly allocate a TTY. This is due to a current bug in Docker that is detailed in [docker/docker#8755](https://github.com/docker/docker/issues/8755).

### Web Administrator Interface

*As of version 1.1, the admin panel has been deprecated and will have to be explicitly enabled in the [admin] section of the influxdb config file.*

Navigate to [localhost:8083](http://localhost:8083) with your browser while running the container.

See more about using the web administrator interface [here](https://docs.influxdata.com/influxdb/latest/tools/web_admin/).

# Image Variants

The `tevjef/influxdb` images come in many flavors, each designed for a specific use case.

## `tevjef/influxdb:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of. This tag is based off of [`buildpack-deps`](https://registry.hub.docker.com/_/buildpack-deps/). `buildpack-deps` is designed for the average user of docker who has many images on their system. It, by design, has a large number of extremely common Debian packages. This reduces the number of packages that images that derive from it need to install, thus reducing the overall size of all images on your system.

# License

View [license information](https://github.com/tevjef/influxdb-docker/blob/master/LICENSE) for the software contained in this image.

# Supported Docker versions

This image is supported on Docker version 1.12.1.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.
