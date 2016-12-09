#!/bin/bash
DATA_PATH=${DATA_PATH:="/osrm-data"}

_sig() {
  kill -TERM $child 2>/dev/null
}
trap _sig SIGKILL SIGTERM SIGHUP SIGINT EXIT


if [ $# -eq 6 ]; then

    # Set the graph profile (car/bicycle/foot)
    mv $5.lua profile.lua

    # Retrieve the PBF file
    curl $6 > $DATA_PATH/$1.osm.pbf
    
    # Build the graph
    ./osrm-extract $DATA_PATH/$1.osm.pbf
    ./osrm-contract $DATA_PATH/$1.osrm

    # Activate the service account to access storage
    gcloud auth activate-service-account --key-file $2
    # Set the Google Cloud project ID
    gcloud config set project $3

    # Copy the graph data to storage
    gsutil -m cp $DATA_PATH/*.osrm* $4/$1
    
elif [ $# -eq 4 ]; then

    # Activate the service account to access storage
    gcloud auth activate-service-account --key-file $2
    # Set the Google Cloud project ID
    gcloud config set project $3

    # Copy the graph from storage
    gsutil -m cp $4/$1/*.osrm* $DATA_PATH
    
fi

# Start serving requests
./osrm-routed $DATA_PATH/$1.osrm --max-table-size 8000 &
child=$!
wait "$child"
