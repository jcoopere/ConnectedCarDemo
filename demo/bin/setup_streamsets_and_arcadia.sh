#!/bin/bash

# Print usage.
printUsage() {
  echo "Usage: $0 <Cloudera Manager host> <Arcengine Hosts List (csv)> <Arcengine Cat Host> <Arcengine StateStore Host> <StreamSets Host>"
  echo
  echo "NOTE: There are a number of hardcoded paths and values in this script."
}

# Check args.
if [[ $# -ne 5 ]]; then
  printUsage
  exit 1
fi

CLOUDERA_MANAGER_HOST=$1
ARCENGINE_HOSTS=$2
ARCENGINE_CAT_HOST=$3
ARCENGINE_SS_HOST=$4
STREAMSETS_HOST=$5

echo "Beginning CSD setup..."

echo "Creating temporary directory '/tmp/csd_setup/'..."
mkdir /tmp/csd_setup/
cd /tmp/csd_setup/

echo "Setting up StreamSets CSD..."
wget -q https://archives.streamsets.com/datacollector/2.0.0.0/csd/STREAMSETS-2.0.0.0.jar
chmod 644 STREAMSETS-*.jar
chown cloudera-scm:cloudera-scm STREAMSETS-*.jar
mv STREAMSETS-*.jar /opt/cloudera/csd/

echo "Setting up Arcadia Data CSD..."
wget -q http://get.arcadiadata.com/cloudera_demo/AE_CDH_parcels_3.2.0.0-1474670580.zip
unzip AE_CDH_parcels_3.2.0.0-1474670580.zip
cd cm
chmod 644 /opt/cloudera/csd/ARCADIAENTERPRISE-*.jar
chown cloudera-scm:cloudera-scm /opt/cloudera/csd/ARCADIAENTERPRISE-*.jar
mv ARCADIAENTERPRISE-*.jar /opt/cloudera/csd/
python -m SimpleHTTPServer 1985 &> /dev/null &
SERVER_PID=$!
sleep 10

sudo service cloudera-scm-server restart
sleep 120

echo "CSD setup complete!"

echo "Beginning setup of services via CM Python API..."
pip install cm-api==11.0.0
python /home/admin/ConnectedCarDemo/demo/bin/setup_services.py $CLOUDERA_MANAGER_HOST $ARCENGINE_HOSTS $ARCENGINE_CAT_HOST $ARCENGINE_SS_HOST $STREAMSETS_HOST

# Kill Python SimpleHTTPServer used by Arcadia.
kill "${SERVER_PID}"

echo "StreamSets and Arcadia setup complete!"
