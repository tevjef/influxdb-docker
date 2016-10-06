#!/bin/bash

set -m
CONFIG_FILE="/etc/influxdb/influxdb.conf"
PASS=${INFLUXDB_ADMIN_PASSWORD:-admin}
ADMIN_CREATED="/var/lib/influxdb/.admin_created"
DB_CREATED="/var/lib/influxdb/.db_created"

echo "InfluxDB configuration: "
cat ${CONFIG_FILE}
echo "=> Starting InfluxDB ..."
exec influxd -config=${CONFIG_FILE} &

#wait for the startup of influxdb
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of InfluxDB service startup ..."
    sleep 3
    curl -k http://localhost:8086/ping 2> /dev/null
    RET=$?
done
echo ""

if [ ! -f "${ADMIN_CREATED}" ] && [ -n "${INFLUXDB_ADMIN_USER}" ]; then
    echo "=> Creating admin user"
    influx -execute="CREATE USER ${INFLUXDB_ADMIN_USER} WITH PASSWORD '${PASS}' WITH ALL PRIVILEGES"
    touch "${ADMIN_CREATED}"
fi

if [ ! -f "${DB_CREATED}" ]; then
    if [ -n "${INFLUXDB_CREATE_DB}" ]; then
        echo "=> About to create the following database: ${INFLUXDB_CREATE_DB}"
        arr=$(echo ${INFLUXDB_CREATE_DB} | tr ";" "\n")



        if [ -n "${INFLUXDB_ADMIN_USER}" ]; then
            for x in $arr; do
                echo "=> Creating database: ${x}"
                influx -username=${INFLUXDB_ADMIN_USER} -password="${PASS}" -execute="CREATE DATABASE ${x}"
                influx -username=${INFLUXDB_ADMIN_USER} -password="${PASS}" -execute="GRANT ALL PRIVILEGES ON ${x} TO ${INFLUXDB_ADMIN_USER}"
            done
            echo ""
        else
            for x in $arr; do
                echo "=> Creating database: ${x}"
                influx -execute="CREATE DATABASE \"${x}\""
            done
            echo ""
        fi

        touch "${DB_CREATED}"
    else
        echo "=> No database need to be pre-created"
    fi
fi

fg
