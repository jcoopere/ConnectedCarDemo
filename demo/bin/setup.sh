#!/bin/bash

# Determine location of this script.
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Print usage.
printUsage() {
  echo "Usage: $0 <Kudu Master Host> <Impala Daemon Host> <Zookeeper Host>"
  echo
  echo "NOTE: There are a number of hardcoded paths and values in this script."
}

# Check args.
if [[ $# -ne 3 ]]; then
  printUsage
  exit 1
fi

KUDU_MASTER_HOST=$1
IMPALA_DAEMON_HOST=$2
ZOOKEEPER_HOST=$3

# Run setup_solr.sh script.
# Create Solr stuff in this users home directory.
$dir/setup_solr.sh ~/connected-car-solr car-event-collection $dir/../solr/connected_car

# Create Kudu table (using Java API).
java -cp $dir/../target/ConnectedCar.jar com.cloudera.demo.connected_car.CreateConnectedCarProfileTable $KUDU_MASTER_HOST

# Create Impala mapping to Kudu table.
impala-shell -i $IMPALA_DAEMON_HOST:21000 -q "CREATE EXTERNAL TABLE IF NOT EXISTS connected_car_profiles STORED AS KUDU TBLPROPERTIES('kudu.table_name' = 'connected_car_profiles', 'kudu.master_addresses' = '$KUDU_MASTER_HOST:7051');"

# Delete and Create Kafka topics.
kafka-topics --zookeeper $ZOOKEEPER_HOST:2181 --delete --topic connected_car_readings
kafka-topics --zookeeper $ZOOKEEPER_HOST:2181 --delete --topic connected_car_streaming

sleep 5

kafka-topics --zookeeper $ZOOKEEPER_HOST:2181 --create --topic connected_car_readings --partitions 1 --replication-factor 1
kafka-topics --zookeeper $ZOOKEEPER_HOST:2181 --create --topic connected_car_streaming --partitions 1 --replication-factor 1
