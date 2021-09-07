#/bin/bash
### This script configures Ceph, adds ceph host(s) into hosts file, and copys ceph pub key
### into the other hosts in the cluster
echo "### Ceph Installed, running cephadm bootstrap to configure Ceph and Ceph Networking ###"

### This runs the cephadm boostrap command, actually bringing up the cluster via MonIP and declaring
### the cluster network
cephadm bootstrap --mon-ip 172.16.168.6 --cluster-network 172.16.40.0/24 --initial-dashboard-user admin --initial-dashboard-password CHANGEME!

### This declares the public network for the monitors, this ensures that any nodes that are added in that
### network are eligable for becomming monitors
ceph config set mon public_network 172.16.168.0/24

### This defines the cluster network as above and puts it into the ceph.conf file
echo "        cluster_network = 172.16.40.0/24" >> /etc/ceph/ceph.conf

### This tells Ceph to scan for new drives and make them osds automatticly
ceph orch apply osd --all-available-devices

### This just tells the OSD daemons to autotune memory
ceph config set osd osd_memory_target_autotune true

echo "### Adding Ceph Hosts Into hosts file ###"
echo "#Ceph Hosts" >> /etc/hosts
echo "172.16.168.6    ceph01" >> /etc/hosts
echo "172.16.168.8    ceph02" >> /etc/hosts
echo "172.16.168.10   ceph03" >> /etc/hosts
echo "172.16.168.12   ceph04" >> /etc/hosts
echo "172.16.168.14   ceph05" >> /etc/hosts
echo "172.16.168.16   ceph06" >> /etc/hosts

ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph02
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph03
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph04
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph05
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph06

ceph orch host add ceph02 172.16.168.8 
ceph orch host label add ceph02 _admin
ceph orch host add ceph03 172.16.168.10
ceph orch host label add ceph03 _admin

