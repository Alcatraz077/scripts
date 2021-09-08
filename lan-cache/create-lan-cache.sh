#/bin/bash
# This script creates, configures, and starts a LANCache, from lancache.net
echo "### This script creates, configures, and starts a LANCache ###"

apt update -y >> /dev/null

### Installs Docker prequisites, but also installs some other useful packages
apt-get install apt-transport-https ca-certificates curl gnupg lsb-release python3 lvm2 ntp systemd htop tmux sysstat python3-pip wget -y >> /dev/null

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> /dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

### These run to update the apt cache, upgrade packages, and cleanup
apt-get update -y >> /dev/null
apt-get upgrade -y >> /dev/null
apt autoremove -y >> /dev/null

echo "### Updating Timezone ###"
timedatectl set-timezone America/Chicago

### Installs Docker
echo "### Installing Docker ###"
apt-get install docker-ce docker-ce-cli containerd.io docker-compose -y >> /dev/null

echo "### Adding SSH Keys ###"
### Creates authorized_keys file if it doesn't already exist
mkdir -p ~/.ssh
echo -n > ~/.ssh/authorized_keys

### Adds my public SSH Key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd46vcJFhHitAx5FaEi66E1t2tfgZx8/XMdb14R/m7i alcatraz@pop-box" >> ~/.ssh/authorized_keys

echo "### Starting SSH Hardening ###"
### Removes and regenerates ssh host keys
echo "### Regenerating ssh host keys ###"

rm /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" >> /dev/null
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" >> /dev/null

### Regenerates moduli prime numbers used for DH key exchange
echo "### Regenerating Moduli Prime Numbers, please wait... ###"
### There is no way to disable output for this command, I've tried
ssh-keygen -G moduli-2048.candidates -b 2048
ssh-keygen -T moduli-2048 -f moduli-2048.candidates

cp moduli-2048 /etc/ssh/moduli
rm moduli-2048
rm moduli-2048.candidates

echo "### Regeneration of Moduli Prime Numbers Finished ###"
echo "### Backing up sshd_config before adding changes ###"
### Creates backup of sshd_config
cp /etc/ssh/sshd_config /etc/ssh/backup.sshd_config

echo "### Appending sshd_config ###"
### Appends the following lines to sshd_config
echo "Port 22
PermitRootLogin yes
ClientAliveInterval 300
ClientAliveCountMax 2
PasswordAuthentication no
X11Forwarding no
Banner /etc/issue.net
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
KexAlgorithms curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config

echo "### Restarting SSH service ###"
service ssh restart

### Installing needrestart here because it breaks the script if ran at the start
apt install needrestart -y >> /dev/null

echo "### Installing LANCache ###"
git clone https://github.com/lancachenet/docker-compose lancache
cp ~/lancache/.env ~/lancache/.env.bak
echo "
## See the 'Settings' section in README.md for more details

## Set this to true if you're using a load balancer, or set it to false if you're using seperate IPs for each service.
## If you're using monolithic (the default), leave this set to true
USE_GENERIC_CACHE=true

## IP addresses that the lancache monolithic instance is reachable on
## Specify one or more IPs, space separated - these will be used when resolving DNS hostnames through lancachenet-dns. Multiple IPs can improve cache priming performance for some services (e.g. Steam)
## Note: This setting only affects DNS, monolithic and sniproxy will still bind to all IPs by default
LANCACHE_IP=10.0.39.1

## IP address on the host that the DNS server should bind to
DNS_BIND_IP=10.0.39.1

## DNS Resolution for forwarded DNS lookups
UPSTREAM_DNS=9.9.9.9

## Storage path for the cached data
## Note that by default, this will be a folder relative to the docker-compose.yml file
CACHE_ROOT=./lancache

## Change this to customise the size of the disk cache (default 1000000m)
## If you have more storage, you'll likely want to increase this
## The cache server will prune content on a least-recently-used basis if it
## starts approaching this limit.
## Set this to a little bit less than your actual available space
CACHE_DISK_SIZE=1000000m

## Change this to customise the size of the nginx cache manager (default 500m)
## DO NOT CHANGE THIS LIGHTLY. The defaults are enough to address 8TB of cache storage.  
## Increasing this value will cause performance problems, and may cause the cache to fail to start entirely.
CACHE_MEM_SIZE=500m

## Change this to limit the maximum age of cached content (default 3650d)
CACHE_MAX_AGE=3650d

## Set the timezone for the docker containers, useful for correct timestamps on logs (default Europe/London)
## Formatted as tz database names. Example: Europe/Oslo or America/Los_Angeles
TZ=America/Chicago
" >> ~/lancache/.env
cd ~/lancache
docker-compose up -d



