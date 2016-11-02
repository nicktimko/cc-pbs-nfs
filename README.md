# Abstract cluster for MIDAS

## Components

* An image that can serve as both head & worker nodes, and
* A Heat template that can launch & connect them.

### Image

Needs to support NFS and PBS. Runs as either head or worker depending on...


### Heat Template.


## Operation

### Existing NFS
1. NFS server launches.
2. Server runs script from template that installs NFS and configures it
3. NFS clients launch.
4. Clients run script that mounts the exported volume.


### Torque
* Launch all the nodes
* Kill all Torque services until configuration done
* Configure hostnames on all nodes as appropriate.
* Set up `/etc/hosts` (with private IPs) with that mapping
  * All files across all nodes should be identical, could maybe link it from the NFS share, or at least copy it from there.
* Key exchange all the things
  * Host keys
  * Client keys
* On head node
  * Configure `(torque)/server_priv/nodes` with all the node hostnames
* On worker nodes
  * Configure `(torque)/mom_priv/config` with `$pbsserver (head-node-name)`

## References

* Torque
  * Install from source http://docs.adaptivecomputing.com/torque/5-1-1/Content/topics/torque/1-installConfig/overview.htm
  * Command overview http://docs.adaptivecomputing.com/torque/4-1-7/Content/topics/12-appendices/commandsOverview.htm

* Heat
  * Resource Types: http://docs.openstack.org/developer/heat/template_guide/openstack.html

* HOT examples
  * MPI CA: https://www.chameleoncloud.org/appliances/api/appliances/29/template
