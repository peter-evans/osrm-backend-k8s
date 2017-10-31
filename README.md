# osrm-backend for Kubernetes
[![](https://images.microbadger.com/badges/image/peterevans/osrm-backend-k8s.svg)](https://microbadger.com/images/peterevans/osrm-backend-k8s)
[![Build Status](https://travis-ci.org/peter-evans/osrm-backend-k8s.svg?branch=master)](https://travis-ci.org/peter-evans/osrm-backend-k8s)

Open Source Routing Machine (OSRM) [osrm-backend](https://github.com/Project-OSRM/osrm-backend) for Kubernetes on Google Container Engine (GKE).

This Docker image and sample Kubernetes configuration files are one solution to persisting [osrm-backend](https://github.com/Project-OSRM/osrm-backend) data and providing immutable deployments.

If you are looking for a more general purpose docker image, see [osrm-backend-docker](https://github.com/peter-evans/osrm-backend-docker).

## Supported tags and respective `Dockerfile` links

- [`1.12.0`, `1.12`, `latest`  (*1.12/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.12)
- [`1.11.0`, `1.11` (*1.11/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.11)
- [`1.10.0`, `1.10` (*1.10/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.10)
- [`1.9.0`, `1.9` (*1.9/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.9)
- [`1.8.0`, `1.8` (*1.8/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.8)
- [`1.7.2`, `1.7` (*1.7/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.7)
- [`1.6.1`, `1.6` (*1.6/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.6)
- [`1.5.4`, `1.5` (*1.5/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.5)
- [`1.4.4`, `1.4` (*1.4/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.4)
- [`1.3.0`, `1.3` (*1.3/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/1.3)

For earlier versions see [releases](https://github.com/peter-evans/osrm-backend-k8s/releases) and the available [tags on Docker Hub](https://hub.docker.com/r/peterevans/osrm-backend-k8s/tags/).

## Usage
The Docker image can be run standalone without Kubernetes:

```bash
docker run -d -p 5000:5000 \
-e OSRM_PBF_URL='http://download.geofabrik.de/asia/maldives-latest.osm.pbf' \
--name osrm-backend peterevans/osrm-backend-k8s:latest
```
Tail the logs to verify the graph has been built and osrm-backend is serving requests:
```
docker logs -f <CONTAINER ID>
```
Then point your web browser to [http://localhost:5000/](http://localhost:5000/)

## Kubernetes Deployment
The [osrm-backend](https://github.com/Project-OSRM/osrm-backend) builds a data graph from a PBF file. This process can take over an hour for a single country.
If a pod in a deployment fails, waiting over an hour for a new pod to start could lead to loss of service.

The sample Kubernetes files provide a means of persisting a data graph in storage that is used by all pods in the deployment. 
Each pod having their own copy of the graph is desirable in order to have no single point of failure.

#### Explanation
Initial deployment flow:

1. Create a secret that contains the JSON key of a Google Cloud IAM service account that has read/write permissions to Google Storage.
2. Deploy the canary deployment.
3. Wait for the graph to be built and uploaded to Google Storage.
4. Delete the canary deployment.
5. Deploy the stable track deployment.

To update the live deployment with a new graph:

1. Deploy the canary deployment alongside the stable track deployment.
2. Wait for the graph to be built and uploaded to Google Storage.
3. Delete the canary deployment.
4. Perform a rolling update on the stable track deployment to create pods using the new graph.

#### Creating the secret

```bash
# Google Cloud project ID and service account details
PROJECT_ID=my-project
SA_NAME=my-service-account
SA_DISPLAY_NAME="My Service Account"
SA_EMAIL=$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com
KEY_FILE=service-account-key.json

# Create a new GCP IAM service account
gcloud iam service-accounts create $SA_NAME --display-name "$SA_DISPLAY_NAME"

# Create and download a new key for the service account
gcloud iam service-accounts keys create $KEY_FILE --iam-account $SA_EMAIL

# Give the service account the "Storage Object Viewer" and "Storage Object Creator" IAM roles
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SA_EMAIL --role roles/storage.objectViewer
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SA_EMAIL --role roles/storage.objectCreator

# Create a secret containing the service account key file
kubectl create secret generic osrm-storage-secret --from-file=$KEY_FILE
```  

#### Deployment configuration
Before deploying, edit the `env` section of both the canary deployment and stable track deployment.

- `OSRM_MODE` - `CREATE` from PBF data, or `RESTORE` from Google Storage.
- `OSRM_PBF_URL` - URL to PBF data file. (Optional when `OSRM_MODE=RESTORE`)
- `OSRM_GRAPH_PROFILE` - Graph profile; `car`,`bicycle` or `foot`. (Optional when `OSRM_MODE=RESTORE`)
- `OSRM_DATA_LABEL` - A meaningful and **unique** label for the data. e.g. maldives-car-20161209
- `OSRM_SA_KEY_PATH` - Path to the JSON service account key. This needs to match the `mountPath` of the volume mounted secret.
- `OSRM_PROJECT_ID` - Google Cloud project ID.
- `OSRM_GS_BUCKET` - Google Storage bucket.

## License

MIT License - see the [LICENSE](LICENSE) file for details