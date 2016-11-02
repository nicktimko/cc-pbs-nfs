Still to do:

* On head node
  * Add workers to `/etc/hosts`
  * Add workers to `/var/lib/torque/server_priv/nodes` with `num_node_boards=1` (some NUMA thing, see below)
  * (? not sure if needed) `killall trqauthd`, `trqauthd`
  * `pbs_server -t create`

* On worker
  * (???) Restart `pbs_mom`

`qsub`ing

    #!/bin/sh
    for i in {1..10}; do echo $i; sleep 1; done

Queues it up, but it doesn't seem to run. Scheduler not configured? Manual `qrun` seems a bit tedious...

---

Without `num_node_boards=1`, `pbsnodes` reports nodes, but they're down, probably because `tail /var/lib/torque/server_logs/*` is complaining that

    11/02/2016 20:51:57;0001;PBS_Server.11877;Svr;PBS_Server;LOG_ERROR::get_numa_from_str, Node midas-worker-0 isn't declared to be NUMA, but mom is reporting

Also, for some reason the following line in the HOT doesn't run, so if a little polling script were to run on the head node, it wouldn't be able to see there's a new node to add:

    echo $(facter ipaddress) $(hostname) >> /mnt/hosts
