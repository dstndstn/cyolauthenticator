#! /bin/bash

cd /

service ssh start
service rsyslog start

# The way environment variables get passed to GCE containers,
# they appear (only) in the "main" process, not in subsequent
# ssh connections, etc.  So save the variable values if we haven't already.
if [ -f /envvars ]; then
    . /envvars
else
    cat > /envvars <<EOF
export GCP_PROJECT=${GCP_PROJECT}
export GCP_ZONE=${GCP_ZONE}
export CLUSTER_NAME=${CLUSTER_NAME}
export GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}
export NOTEBOOK_CONTAINER=${NOTEBOOK_CONTAINER}
export TUTORIAL_SECRET_CODE=${TUTORIAL_SECRET_CODE}
EOF
fi

# Set the secret code word
if [ x$TUTORIAL_SECRET_CODE != x ]; then
    echo $TUTORIAL_SECRET_CODE > /usr/enable_mkuser
fi

# Set the notebook container
if [ x$NOTEBOOK_CONTAINER != x ]; then
    cat /jup-config-template.py | sed "s+NOTEBOOK_CONTAINER+${NOTEBOOK_CONTAINER}+g" > /jup-config.py
fi

# # Set this to the Google Cloud Platform project name
# export GCP_PROJECT=schrodingers-hack
# export GCP_ZONE=us-central1-c
# # Kubernetes cluster
# export CLUSTER_NAME=cluster-1
# # Authorize to use kubernetes using service account,
# # assumed to be stored in /nfs/sys/svc.json
# export GOOGLE_APPLICATION_CREDENTIALS="/nfs/sys/svc.json"

gcloud config configurations create hub-config
gcloud config configurations activate hub-config

# activate gcp powers!
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS

# GCP Project name.
gcloud projects describe $GCP_PROJECT

gcloud config set project $GCP_PROJECT
gcloud config set compute/zone $GCP_ZONE

gcloud container clusters get-credentials $CLUSTER_NAME

#gcloud config set container/use_client_certificate True

# (Re-)add firewall entries.  This complains if they already exist.
NET=$(gcloud container clusters describe $CLUSTER_NAME --format=get"(network)")
IP=$(gcloud container clusters describe $CLUSTER_NAME --format=get"(clusterIpv4Cidr)")

gcloud compute firewall-rules create allow-2222 --direction=INGRESS --priority=1000 --network="$NET" --action=ALLOW --rules=tcp:2222 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-80   --direction=INGRESS --priority=1000 --network="$NET" --action=ALLOW --rules=tcp:80   --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-443  --direction=INGRESS --priority=1000 --network="$NET" --action=ALLOW --rules=tcp:443  --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create kube-to-all-vms-on-network --network="$NET" --source-ranges="$IP" --allow=tcp,udp,icmp,esp,ah,sctp

# Need to run in a "privileged" container for this!!
mount -t nfsd nfsd /proc/fs/nfsd

mkdir -p /run/sendsigs.omit.d/
service rpcbind start
service nfs-common start
service nfs-kernel-server start

exportfs -a

## If you create a new Kubernetes cluster, you must do:
kubectl apply -f nfs-pv.yaml
kubectl apply -f nfs-pvc.yaml


# Reset the LDAP passwords
slappasswd -g > /tmp/slappasswd
chmod 400 /tmp/slappasswd
slappasswd -T /tmp/slappasswd > /tmp/hashpass
# Copy password for ldapscripts
cp /tmp/slappasswd /etc/ldapscripts/ldapscripts.passwd
chmod 600 /etc/ldapscripts/ldapscripts.passwd

if [ -f /nfs/sys/ldap/data.mdb ]; then
    echo "/nfs/sys/ldap/data.mdb exists -- symlinking!"
    mv /var/lib/ldap /var/lib/ldap.orig
    ln -s /nfs/sys/ldap /var/lib/
    service slapd start

    echo -e "dn: olcDatabase={1}mdb,cn=config\nchangetype: modify\nreplace: olcRootPW\nolcRootPW: $(cat /tmp/hashpass)" | ldapmodify -Y EXTERNAL -H ldapi:///
    echo -e "dn: cn=admin,dc=hub\nchangetype: modify\nreplace: userPassword\nuserPassword: $(cat /tmp/hashpass)" | ldapmodify -H ldap:// -x -D "cn=admin,dc=hub" -y /tmp/slappasswd

else
    service slapd start

    echo -e "dn: olcDatabase={1}mdb,cn=config\nchangetype: modify\nreplace: olcRootPW\nolcRootPW: $(cat /tmp/hashpass)" | ldapmodify -Y EXTERNAL -H ldapi:///
    # https://www.digitalocean.com/community/tutorials/how-to-change-account-passwords-on-an-openldap-server
    echo -e "dn: cn=admin,dc=hub\nchangetype: modify\nreplace: userPassword\nuserPassword: $(cat /tmp/hashpass)" | ldapmodify -H ldap:// -x -D "cn=admin,dc=hub" -y /tmp/slappasswd
    ldapadd -y /tmp/slappasswd -x -D cn=admin,dc=hub -f /tmp/add_content.ldif
    ldapaddgroup users
fi
rm /tmp/slappasswd

# Enable user quotas
mount -o remount,usrquota /nfs

for ((;;)); do
  # If we have a certificate directory...
  if [ -d /etc/pki/tls/certs/tutorial.cer ]; then
      PORT=443
  else
      PORT=80
  fi
  jupyterhub --port $PORT -f jup-config.py >> jupyterhub.log 2>&1
  sleep 5
done

