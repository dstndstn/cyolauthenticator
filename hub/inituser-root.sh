#! /bin/bash
echo Running inituser-root.sh as $USER home $HOME
echo With arguments $*
user=$1
echo User $user

setquota -u $user 5G 5G 500k 500k /nfs

# In case the username previously existed and was deleted, make sure the home directory is chowned.
# (could also rm -R the previous contents...)
chown -R $user /nfs/home/$user
