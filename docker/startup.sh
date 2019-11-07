cd /
#echo jtest789 > /usr/enable_mkuser

krb5kdc
kadmind

# from https://github.com/GoogleCloudPlatform/nfs-server-docker/blob/master/1/debian9/1.3/docker-entrypoint.sh
rpcbind -w
mount -t nfsd nfds /proc/fs/nfsd
/usr/sbin/rpc.mountd -N 2 -V 3
/usr/sbin/exportfs -r
# -G 10 to reduce grace time to 10 seconds (the lowest allowed)
/usr/sbin/rpc.nfsd -G 10 -N 2 -V 3
/sbin/rpc.statd --no-notify


#cp --update /home/passwd /home/group /home/shadow /etc/

# Set my local IP address -- passed to spawned notebook servers (?)
#export HUB_CONNECT_IP=$(ip route ls | tail -n 1 | awk '{print $NF}')

# If we have a certificate directory...
if [ -d /etc/pki/tls/certs/tutorial.cer ]
then
  PORT=443
else
  PORT=80
fi
jupyterhub --ip 0.0.0.0 --port $PORT -f jup-config.py
