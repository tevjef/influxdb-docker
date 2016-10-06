#!/bin/bash

set -m
CONFIG_FILE="/etc/influxdb/influxdb.conf"
INFLUX_HOST="localhost"
INFLUX_API_PORT="8086"
API_URL="http://${INFLUX_HOST}:${INFLUX_API_PORT}"

if [ "${PRE_CREATE_DB}" == "**None**" ]; then
    unset PRE_CREATE_DB
fi

echo "influxdb configuration: "
cat ${CONFIG_FILE}
echo "=> Starting InfluxDB ..."
if [ -n "${JOIN}" ]; then
  exec influxd -config=${CONFIG_FILE} -join ${JOIN} &
else
  exec influxd -config=${CONFIG_FILE} &
fi

# Pre create database on the initiation of the container
if [ -n "${PRE_CREATE_DB}" ]; then
    echo "=> About to create the following database: ${PRE_CREATE_DB}"
    if [ -f "/.pre_db_created" ]; then
        echo "=> Database had been created before, skipping ..."
    else
        arr=$(echo ${PRE_CREATE_DB} | tr ";" "\n")

        #wait for the startup of influxdb
        RET=1
        while [[ RET -ne 0 ]]; do
            echo "=> Waiting for confirmation of InfluxDB service startup ..."
            sleep 3
            curl -k ${API_URL}/ping 2> /dev/null
            RET=$?
        done
        echo ""

        PASS=${ADMIN_PASSWORD:-admin}
        if [ -n "${ADMIN_USER}" ]; then
          echo "=> Creating admin user"
          influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} -execute="CREATE USER ${ADMIN_USER} WITH PASSWORD '${PASS}' WITH ALL PRIVILEGES"
          for x in $arr
          do
              echo "=> Creating database: ${x}"
              influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} -username=${ADMIN_USER} -password="${PASS}" -execute="create database ${x}"
              influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} -username=${ADMIN_USER} -password="${PASS}" -execute="grant all PRIVILEGES on ${x} to ${ADMIN_USER}"
          done
          echo ""
        else
          for x in $arr
          do
              echo "=> Creating database: ${x}"
              influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} -execute="create database \"${x}\""
          done
        fi

        touch "/.pre_db_created"
    fi
else
    echo "=> No database need to be pre-created"
fi

fg