yum install -y torque torque-server torque-client torque-mom torque-libs

cat >> /etc/hosts <<eof
10.x.y.z head
10.x.y.w worker1
eof

echo 'head' > /var/lib/torque/server_name
cat >> /etc/hosts <<eof
10.x.y.z head
10.x.y.w worker1
eof

# * `/etc/hostname` is used for `/var/spool/torque/server_name` as well as an alias for `10.x.y.z head ...`

# 3. Create a key for munge (whatever that is)
cd /etc/munge
dd if=/dev/urandom bs=1 count=1024 > munge.key
chown munge munge.key
chmod 400 munge.key

# 4. Run the service
systemctl enable munge.service
systemctl start munge.service
systemctl status munge.service

# 5. Set up Torque on head
# cd /usr/share/doc/torque-4.2.10/
# vi torque.setup # modify as you see fit, or just leave as defaults for now
# chmod +x torque.setup
/bin/sh /usr/share/doc/torque-4.2.10/torque.setup root

# 6. Set up Torque on workers
cat > /var/lib/torque/mom_priv/torque.cfg <<eof
\$pbsserver head
\$logevent 255
eof

# 7. Launch `trqauthd` on head (whatever that is):
echo >/dev/null <<comment
systemctl start trqauthd.service

  * If it doesn't start, might already be running:
    ```
    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# systemctl start trqauthd.service
    Job for trqauthd.service failed because the control process exited with error code. See "systemctl status trqauthd.service" and "journalctl -xe" for details.
    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# systemctl status trqauthd.service
    ● trqauthd.service - trqauthd
       Loaded: loaded (/usr/lib/systemd/system/trqauthd.service; disabled; vendor preset: disabled)
       Active: failed (Result: exit-code) since Mon 2016-10-31 23:26:58 UTC; 13s ago
      Process: 48890 ExecStart=/usr/sbin/trqauthd (code=exited, status=252)

    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id systemd[1]: Starting trqauthd...
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id trqauthd[48890]: trqauthd unix domain file /tmp/trqauthd-unix already bound.
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id trqauthd[48890]: trqauthd may already be running
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id trqauthd[48890]: hostname: test-npt-nfs-2-nfs-server-eyqch4rdf6id
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id systemd[1]: trqauthd.service: control process exited, code=exited status=252
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id systemd[1]: Failed to start trqauthd.
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id systemd[1]: Unit trqauthd.service entered failed state.
    Oct 31 23:26:58 test-npt-nfs-2-nfs-server-eyqch4rdf6id systemd[1]: trqauthd.service failed.
    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# trqauthd
    hostname: test-npt-nfs-2-nfs-server-eyqch4rdf6id
    trqauthd unix domain file /tmp/trqauthd-unix already bound.
     trqauthd may already be running

    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# ps aux | grep [t]rq
    root      11266  0.0  0.0 153844  3648 ?        S    22:20   0:00 trqauthd
    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# kill 11266
    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# ps aux | grep [t]rq

    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# systemctl start trqauthd.service
    [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# systemctl status trqauthd.service
    ● trqauthd.service - trqauthd
       Loaded: loaded (/usr/lib/systemd/system/trqauthd.service; disabled; vendor preset: disabled)
       Active: active (running) since Mon 2016-10-31 23:28:02 UTC; 2s ago
      Process: 49185 ExecStart=/usr/sbin/trqauthd (code=exited, status=0/SUCCESS)
     Main PID: 49186 (trqauthd)
       CGroup: /system.slice/trqauthd.service
               └─49186 /usr/sbin/trqauthd

    ```

8. Try to issue q* commands...they run but report nothing.:

  ```
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# qstat
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# pbsnodes -a
  pbsnodes: Server has no node list MSG=node list is empty - check 'server_priv/nodes' file
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id etc]# cat /var/lib/torque/server_priv/nodes
  worker1 np=24
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id ~]# ps aux | grep [p]bs
  root      11245  0.0  0.0 491540 24100 ?        Sl   22:20   0:01 pbs_server -t create
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id ~]# kill 11245
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id ~]# ps aux | grep [p]bs
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id ~]# systemctl start pbs_server.service
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id ~]# qstat -n
  [root@test-npt-nfs-2-nfs-server-eyqch4rdf6id ~]# pbsnodes -a
  pbsnodes: Server has no node list MSG=node list is empty - check 'server_priv/nodes' file
  ```


9. IPTables!

```
iptables --policy INPUT ACCEPT
iptables --flush
iptables --append INPUT --in-interface lo --jump ACCEPT
iptables -A INPUT --match state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT --proto tcp --dport 22 -j ACCEPT
# server
iptables -A INPUT -p tcp --dport 15001 -j ACCEPT
iptables -A INPUT -p tcp --dport 15002 -j ACCEPT
iptables -A INPUT -p tcp --dport 15003 -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables --list --verbose
```
comment
