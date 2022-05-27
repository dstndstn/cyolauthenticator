#! /bin/bash
echo Running inituser-root.sh as $USER home $HOME
echo With arguments $*
user=$1
echo User $user

setquota -u $user 5G 5G 500k 500k /nfs

