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
echo "=> InfluxDB has started"

if [ ! -f "${ADMIN_CREATED}" ] && [ -n "${INFLUXDB_ADMIN_USER}" ]; then
    echo "=> Creating admin user"
    influx -execute="CREATE USER ${INFLUXDB_ADMIN_USER} WITH PASSWORD '${PASS}' WITH ALL PRIVILEGES"
    touch "${ADMIN_CREATED}"
fi

if [ ! -f "${DB_CREATED}" ]; then
    if [ -n "${INFLUXDB_CREATE_DB}" ]; then
        echo "=> About to create the following database: ${INFLUXDB_CREATE_DB}"
        IFS=';' read -r -a databases <<< "${INFLUXDB_CREATE_DB}"
        IFS=';' read -r -a policies <<< "${INFLUXDB_CREATE_RP}"

        if [ -n "${INFLUXDB_ADMIN_USER}" ]; then
            for i in "${!databases[@]}"; do
                db="${databases[i]}"
                echo "=> Creating database ${db}"
                influx -username=${INFLUXDB_ADMIN_USER} -password="${PASS}" -execute="CREATE DATABASE \"${db}\""
                influx -username=${INFLUXDB_ADMIN_USER} -password="${PASS}" -execute="GRANT ALL PRIVILEGES ON \"${db}\" TO ${INFLUXDB_ADMIN_USER}"

                if [ -n "${policies[i]}" ] && [ "${policies[i]}" != "none" ] ; then
                    IFS=':' read -r -a policy <<< "${policies[i]}"
                    echo "=> Creating default retention policy ${policy[0]} for database ${db} with duration ${policy[1]}"
                    influx -username=${INFLUXDB_ADMIN_USER} -password="${PASS}" -execute="CREATE RETENTION POLICY \"${policy[0]}\" ON \"${db}\" DURATION ${policy[1]} REPLICATION 1 DEFAULT"
                else 
                    echo "=> No retention policy for database ${db}"
                fi
            done
            echo ""
        else
            for i in ${!databases[@]}; do
                db="${databases[i]}"
                echo "=> Creating database ${db}"

                influx -execute="CREATE DATABASE \"${db}\""

                if [ -n "${policies[i]}" ] && [ "${policies[i]}" != "none" ] ; then
                    IFS=':' read -r -a policy <<< "${policies[i]}"
                    echo "=> Creating default retention policy ${policy[0]} for database ${db} with duration ${policy[1]}"
                    influx -execute="CREATE RETENTION POLICY \"${policy[0]}\" ON \"${db}\" DURATION ${policy[1]} REPLICATION 1 DEFAULT"
                else 
                    echo "=> No retention policy for database (${db})"
                fi
            done
            echo ""
        fi

        touch "${DB_CREATED}"
    else
        echo "=> No database need to be pre-created"
    fi
fi

fg