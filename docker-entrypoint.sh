#!/bin/bash

if [ "$OSRM_MODE" != "CREATE" ] && [ "$OSRM_MODE" != "RESTORE" ]; then
    # Default to CREATE
    OSRM_MODE="CREATE"
fi

# Defaults
OSRM_DATA_PATH=${OSRM_DATA_PATH:="/osrm-data"}
OSRM_DATA_LABEL=${OSRM_DATA_LABEL:="data"}
OSRM_GRAPH_PROFILE=${OSRM_GRAPH_PROFILE:="car"}
OSRM_PBF_URL=${OSRM_PBF_URL:="http://download.geofabrik.de/asia/maldives-latest.osm.pbf"}
# Google Storage variables
OSRM_SA_KEY_PATH=${OSRM_SA_KEY_PATH:=""}
OSRM_PROJECT_ID=${OSRM_PROJECT_ID:=""}
OSRM_GS_BUCKET=${OSRM_GS_BUCKET:=""}


_sig() {
  kill -TERM $child 2>/dev/null
}
trap _sig SIGKILL SIGTERM SIGHUP SIGINT EXIT


if [ "$OSRM_MODE" == "CREATE" ]; then
    
    # Set the graph profile (car/bicycle/foot)
    mv $OSRM_GRAPH_PROFILE.lua profile.lua

    # Retrieve the PBF file
    curl $OSRM_PBF_URL --create-dirs -o $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf
    
    # Build the graph
    ./osrm-extract $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf
    ./osrm-contract $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osrm

    if [ ! -z "$OSRM_SA_KEY_PATH" ] && [ ! -z "$OSRM_PROJECT_ID" ] && [ ! -z "$OSRM_GS_BUCKET" ]; then
    
        # Activate the service account to access storage
        gcloud auth activate-service-account --key-file $OSRM_SA_KEY_PATH
        # Set the Google Cloud project ID
        gcloud config set project $OSRM_PROJECT_ID

        # Copy the graph to storage
        gsutil -m cp $OSRM_DATA_PATH/*.osrm* $OSRM_GS_BUCKET/$OSRM_DATA_LABEL

    fi
    
else

    if [ ! -z "$OSRM_SA_KEY_PATH" ] && [ ! -z "$OSRM_PROJECT_ID" ] && [ ! -z "$OSRM_GS_BUCKET" ]; then

        # Activate the service account to access storage
        gcloud auth activate-service-account --key-file $OSRM_SA_KEY_PATH
        # Set the Google Cloud project ID
        gcloud config set project $OSRM_PROJECT_ID

        # Copy the graph from storage
        gsutil -m cp $OSRM_GS_BUCKET/$OSRM_DATA_LABEL/*.osrm* $OSRM_DATA_PATH

    fi
    
fi

# Start serving requests
./osrm-routed $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osrm --max-table-size 8000 &
child=$!
wait "$child"
