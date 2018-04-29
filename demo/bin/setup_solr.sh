#!/bin/bash

# Usage: setup_solr.sh <instance dir> <collection name>

INSTANCEDIR=$1
COLLECTION=$2
SOLR_SCHEMA_DIR=$3

# Determine location of this script.
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

##
# 1) Delete the collection and instancedir if it already exists.
##
if [ -d $INSTANCEDIR ] ; then
  echo "The Solr collection already exists...cleaning it up."
  solrctl collection --delete $COLLECTION
  solrctl instancedir --delete $COLLECTION
  rm -rf $INSTANCEDIR
  echo "Cleanup complete!"
fi

##
# 2) Generate a new instancedir at $INSTANCEDIR.
##
echo "Generating new instancedir '$INSTANCEDIR'."
solrctl instancedir --generate $INSTANCEDIR
if [ $? -ne 0 ]; then
  echo "Failed to generate instancedir! Exiting..."
  exit 1
fi

##
# 3) Copy schema from "../solr/schema.xml" to "$INSTANCEDIR/conf/".
##
echo "Copying Solr schema into '$INSTANCEDIR/conf/'."
cp -f $SOLR_SCHEMA_DIR/schema.xml $INSTANCEDIR/conf/schema.xml
if [ $? -ne 0 ]; then
  echo "Copying schema.xml to instancedir failed! Exiting..."
  exit 1
fi

##
# 4) Upload local configuration files from "$INSTANCEDIR" instancedir to ZK in "$COLLECTION".
##
echo "Uploading configuration files for '$COLLECTION' to ZooKeeper."
solrctl instancedir --create $COLLECTION $INSTANCEDIR
if [ $? -ne 0 ]; then
  echo "Uploading Solr configs to ZooKeeper failed! Exiting..."
  exit 1
fi

##
# 5) Create the Solr collection "$COLLECTION".
##
echo "Creating Solr collection '$COLLECTION'."
solrctl collection --create $COLLECTION -s 1
if [ $? -ne 0 ]; then
  echo "Collection creation failed! Exiting..."
  exit 1
fi

##
# Done.
##
echo "The collection '$COLLECTION' has been successfully created in Solr!"
