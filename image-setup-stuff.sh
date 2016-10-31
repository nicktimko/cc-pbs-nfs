yum install -y torque-server torque-client # https://github.com/shundezhang/dynamictorque-heat/blob/master/template/dynamic_torque_nfs.yaml#L203
yum install -y nfs-utils # CC NFS example

# if head_node:
echo >/dev/null <<eof
    mkdir -p /exports/example
    chown -R cc:cc /exports
    echo '/exports/example 10.140.80.0/22(rw,async) 10.40.0.0/23(rw,async)' >> /etc/exports
    systemctl enable rpcbind && systemctl start rpcbind
    systemctl enable nfs-server && systemctl start nfs-server
eof

# if worker_node:
    echo "$nfs_server_ip:/exports/example    /mnt/    nfs" > /etc/fstab
    mount -a

    IP=$(ifconfig eno1 | python -c 'import sys;print(sys.stdin.readlines()[1].split()[1])')
