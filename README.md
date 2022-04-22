# CYOLAuthenticator: Create Your Own Login Authenticator
A Jupyterhub authenticator that allows users to pick a name and password if they know a code.

This branch is a heavily modified version that runs in the Google
Cloud Platform environment.

The front-end web service runs on a Google Compute Engine VM in a
docker container (`dstndstn/tutorial-server`), described in the `hub/`
directory.  This includes a persistent disk mounted in `/nfs`, which
holds user home directories as well as persistent state for the
service. It also runs an LDAP server, and exports the home directories
via NFS.

The notebook servers are started on Kubernetes pods, which run the
`dstndstn/tutorial-singleuser` container (in the `singleuser/` directory).
The notebooks are run as the logged-in user, and the home directory is
mounted over NFS.

## Old instructions

To enable users to create a login, place a code word in
`/usr/enable_mkuser`. If the users provide this code word when
attempting to create a login, they will succeed.

To disable creation of logins, remove `/usr/enable_mkuser`.

Note that you will also need a custom `login.html` page. See the docker
directory for how to do this.

## Building the "hub" container image

- Create an ssh public key that you want to use for root logins; copy it
  to `hub/id_root_hub.pub`

- Copy `cyolauthenticator/*` to `hub/`

- Create a `codeword.txt` file containing the "secret code" users need to know to log in.

- `cd hub && docker build .`

## Google Cloud Platform Setup instructions

- in Google Kubernetes Engine, create a cluster to run your notebook
  servers.

- in Google Compute Engine, create a persistent volume called `nfs-home`,
  initiatize it with a filesystem (probably `ext4`), and add:
  - `sys/svc.json` containing a JSON-format service account credential
    for Kubernetes
  - `home/` directory
  - Optionally, `sys/ldap/data.mdb` containing the LDAP database

- Run:
```
kubectl apply -f config/nfs-pv.yaml
kubectl apply -f config/nfs-pvc.yaml
```

- change the firewall rules to allow traffic between GCE and your GKE cluster:
```
# PER https://cloud.google.com/kubernetes-engine/docs/troubleshooting#autofirewall
$ gcloud container clusters describe your-first-cluster-1 --format=get"(network)" --zone us-central1-a
default
$ gcloud container clusters describe your-first-cluster-1 --format=get"(clusterIpv4Cidr)" --zone us-central1-a
10.4.0.0/14
$ gcloud compute firewall-rules create "your-first-cluster-1-to-all-vms-on-network" --network="default" --source-ranges="10.4.0.0/14" --allow=tcp,udp,icmp,esp,ah,sctp
Creating firewall...
Created [https://www.googleapis.com/compute/v1/projects/research-technologies-testbed/global/firewalls/your-first-cluster-1-to-all-vms-on-network].
NAME                                        NETWORK  DIRECTION  PRIORITY  ALLOW                     DENY  DISABLED
your-first-cluster-1-to-all-vms-on-network  default  INGRESS    1000      tcp,udp,icmp,esp,ah,sctp        False
```

- create the `nfs-home` persistent disk:
```
export PROJECT=research-technologies-testbed
export REGION=us-central1
export ZONE=$REGION-a
export CLUSTER=tutorial-cluster
export HUB_CONTAINER=dstndstn/tutorial-server
export SINGLEUSER_CONTAINER=dstndstn/tutorial-singleuser
export SECRET_CODE=Hello

gcloud config set project $PROJECT
gcloud beta compute disks create nfs-home --type=pd-balanced --size=10GB --project=$PROJECT  --zone=$ZONE
```

- create the Kubernetes cluster:
```
gcloud beta container \
  --project $PROJECT \
  clusters create $CLUSTER \
  --zone $ZONE \
  --no-enable-basic-auth --cluster-version "1.18.16-gke.302" --release-channel "regular" --machine-type "e2-medium" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
  --num-nodes "3" \
  --enable-stackdriver-kubernetes --enable-ip-alias \
  --network "projects/${PROJECT}/global/networks/default" \
  --subnetwork "projects/${PROJECT}/regions/${REGION}/subnetworks/default" \
  --default-max-pods-per-node "110" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes \
  --node-locations $ZONE
```

- start the `hub` VM with a command such as (replacing with relevant names for your project):
```
gcloud beta compute \
  --project=$PROJECT \
  instances create-with-container hub \
  --zone=$ZONE\
  --machine-type=e2-medium \
  --subnet=default --network-tier=PREMIUM --metadata=google-logging-enabled=true --maintenance-policy=MIGRATE \
  --service-account=310980440256-compute@developer.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
  --tags=http-server \
  --image=cos-stable-85-13310-1209-17 --image-project=cos-cloud \
  --boot-disk-size=10GB --boot-disk-type=pd-balanced --boot-disk-device-name=hub \
  --disk=name=nfs-home,device-name=nfs-home,mode=rw,boot=no \
  --container-image=$HUB_CONTAINER \
  --container-mount-disk=mount-path=/nfs,name=nfs-home,mode=rw \
  --container-restart-policy=always --labels=container-vm=cos-stable-85-13310-1209-17 \
  --container-privileged \
  --container-env=GCP_PROJECT=$PROJECT \
  --container-env=GCP_ZONE=$ZONE \
  --container-env=CLUSTER_NAME=$CLUSTER \
  --container-env=GOOGLE_APPLICATION_CREDENTIALS=/nfs/sys/svc.json \
  --container-env=NOTEBOOK_CONTAINER=$SINGLEUSER_CONTAINER \
  --container-env=TUTORIAL_SECRET_CODE=$SECRET_CODE  
```

It can take several minutes for the container to start!  (The VM
starts faster than that, but it still then takes several minutes for
the container to start.)

Open up the firewall between the Kubernetes cluster and the Hub VM, and
open up ports to the Hub machine.  (This need be done only once.  The 
```
IP=$(gcloud container clusters describe $CLUSTER --format=get"(clusterIpv4Cidr)" --zone $ZONE)
NET=$(gcloud container clusters describe $CLUSTER --format=get"(network)" --zone=$ZONE)
# Delete a previous version, if it exists
gcloud compute firewall-rules delete --quiet kube-to-all-vms-on-network
gcloud compute firewall-rules create kube-to-all-vms-on-network --network="$NET" --source-ranges="$IP" --allow=tcp,udp,icmp,esp,ah,sctp
gcloud compute firewall-rules create allow-2222 --direction=INGRESS --priority=1000 --network="$NET" --action=ALLOW --rules=tcp:2222 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-80   --direction=INGRESS --priority=1000 --network="$NET" --action=ALLOW --rules=tcp:80   --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-443  --direction=INGRESS --priority=1000 --network="$NET" --action=ALLOW --rules=tcp:443  --source-ranges=0.0.0.0/0
```



Need to turn on Cloud Resource Manager API:

https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=research-technologies-testbed

In the startup script, we get:
```
ERROR: (gcloud.compute.firewall-rules.create) Could not fetch resource:
 - Required 'compute.firewalls.create' permission for 'projects/research-technologies-testbed/global/firewalls/allow-2222'
```
and I couldn't figure out where to grant that permission...


If you want to run Kubernetes nodes with GPUs, you will need to run this magic:
```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml
```

To see the logs from an individual user's Jupyter server:
```
gcloud container clusters get-credentials tutorial-cluster --zone us-central1-a --project research-technologies-testbed
kubectl attach jupyter-dustin -c notebook
```
(as explained here, https://cloud.google.com/kubernetes-engine/docs/how-to/gpus)

