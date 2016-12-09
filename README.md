# osrm-backend for Kubernetes
Open Source Routing Machine (OSRM) [osrm-backend](https://github.com/Project-OSRM/osrm-backend) for Kubernetes on Google Container Engine (GKE).

Based on [osrm-backend-docker](https://github.com/cartography/osrm-backend-docker), this Docker image and sample Kubernetes configuration files provide a solution to persisting graph data and immutable deployments.

## Explanation
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

## Usage

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
Before deploying, edit the `args` section of both the canary deployment and stable track deployment. The arguments passed to the Docker entrypoint are as follows:

- `$1` - A meaningful label for the data graph. e.g. maldives-car-20161209
- `$2` - Path to the JSON service account key. This needs to match the `mountPath` of the volume mounted secret.
- `$3` - Google Cloud project ID.
- `$4` - Google Storage bucket.
- `$5` - Graph profile. (car/bicycle/foot)
- `$6` - URL to PBF data file.

All six arguments are specified in the canary deployment in order to build a new graph. The stable deployment track just requires the first four arguments.


## Credits

Based on [osrm-backend-docker](https://github.com/cartography/osrm-backend-docker).

## License

MIT License - see the [LICENSE](LICENSE) file for details