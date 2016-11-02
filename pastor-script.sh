#!/bin/bash

set -x
set -eu

# Following this tutorial:
# https://wiki.archlinux.org/index.php/TORQUE#Server_.28head_node.29_configuration

IS_MASTER=1
HOSTNAME="$(hostname)"
MASTER_NAME="torque-head-node"
MASTER_IP="192.168.0.239"

################################################################################
# Cleaning existing torque installation
################################################################################
killall -s 9 trqauthd || true
killall -s 9 pbs_server || true
rm -rf /var/spool/torque/ || true

################################################################################
# Configure node
################################################################################
#sudo yum -y install torque
echo "y" | ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
IP_ADDRESS=$(ifconfig -a | grep inet | grep -o -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | grep -v "127.0.0.1" | grep -E -v "*\.0$" | grep -E -v "*\.255$" | head -n 1)
echo "$IP_ADDRESS $HOSTNAME" >> /etc/hosts
echo "$MASTER_IP $MASTER_NAME" >> /etc/hosts
echo "$MASTER_IP headnode" >> /etc/hosts
mkdir -p /var/spool/torque/

if [ "$IS_MASTER" == "1" ]; then
    touch /var/spool/torque/server_name
    # echo "$MASTER_NAME" > /var/spool/torque/server_name
    echo "headnode" > /var/spool/torque/server_name
fi

#PBS_SERVER_LOCATION=$(which pbs_server)
PBS_SERVER_LOCATION=""
if [ "$PBS_SERVER_LOCATION" == "" ]; then

    # Install torque
    pushd /root
    yum install -y libxml2-devel openssl-devel gcc gcc-c++ boost-devel wget git
    if [ ! -d "4.5.1" ]; then
        git clone https://github.com/adaptivecomputing/torque.git -b 4.5.1 4.5.1
    fi
    pushd 4.5.1
    ./autogen.sh
    ./configure
    make
    make install
    # echo "y" | bash ./torque.setup root
    # Copy the torque executables in a folder accessible by all users
    cp /usr/local/sbin/* /usr/sbin
    popd
    popd
fi

if [ "$IS_MASTER" == "1" ]; then
    # Initializing Torque
    # rm -rf /var/spool/torque/server_priv/
    # mkdir -p /var/spool/torque/server_priv
    echo "y" | pbs_server -t create
    trqauthd start

    sleep 5

    # Configure Torque options
    qmgr -c "set server acl_hosts = $MASTER_NAME"
    qmgr -c "set server scheduling=true"
    qmgr -c "create queue batch queue_type=execution"
    qmgr -c "set queue batch started=true"
    qmgr -c "set queue batch enabled=true"
    qmgr -c "set queue batch resources_default.nodes=1"
    qmgr -c "set queue batch resources_default.walltime=3600"
    qmgr -c "set server default_queue=batch"
    qmgr -c "set server keep_completed = 86400"

    qterm
    pbs_server
else
    # Add the headnode in the compute nodes list
    echo "$MASTER_NAME" > /var/spool/torque/server_priv/nodes # Put all compute nodes here
    echo "\$pbsserver      $MASTER_NAME" > /var/spool/torque/mom_priv/config # Put the headnode name in the compute node's config file
    pbs_mom
fi

# qterm
# pbs_server


# pbs_server -t restart
# pbs_mom start

exit 0
