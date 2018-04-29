#!/bin/bash

# Determine location of this script.
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Print usage.
printUsage() {
  echo "Usage: $0 <Cloudera Manager Host> <Solr Host> <Impala Host>"
  echo
  echo "NOTE: There are a number of hardcoded paths and values in this script."
}

# Check args.
if [[ $# -ne 3 ]]; then
  printUsage
  exit 1
fi

CLOUDERA_MANAGER_HOST=$1
SOLR_HOST=$2
IMPALA_HOST=$3

# To import the dashboard into a new environment, we manually modify connection strings in the dashboard's sqlite db.
SOLR_INFOSTR='{"PARAMS":{"SOLRTYPE":"cloud","HOST":"'$SOLR_HOST'","PORT":"8983","USERNAME":"arcadia","DATABASE":"","DRIVER":"","DSN":"","Authentication":"No Authentication"}}'

IMPALA_INFOSTR='{"PARAMS":{"HOST":"'$IMPALA_HOST'","PORT":"21050","USERNAME":"arcadia","SETTINGS":{},"TIMEOUT":60,"IMPERSONATION":false,"AUTH":"nosasl","SOCK":"normal","KERBSERV":"","SSLCERT_NAME_MISMATCH":false}}'

SOLR_ARCQUERY="UPDATE datasets_dataconnection SET dataconnection_info='$SOLR_INFOSTR' WHERE id=5;"

IMPALA_ARCQUERY="UPDATE datasets_dataconnection SET dataconnection_info='$IMPALA_INFOSTR' WHERE id=4;"

sqlite3 $dir/../conf/arcviz.sqlite3 "$SOLR_ARCQUERY"

sqlite3 $dir/../conf/arcviz.sqlite3 "$IMPALA_ARCQUERY"

chown arcadia:arcadia $dir/../conf/arcviz.sqlite3

mv arcadia:arcadia $dir/../conf/arcviz.sqlite3 /var/lib/arcadia/

# Restart Arcadia after moving the modified db.
curl -X POST -H "Content-Type:application/json" -u "admin:admin" http://$CLOUDERA_MANAGER_HOST:7180/api/v11/clusters/Cluster%201/services/Arcadia/commands/restart
