#/bin/bash
# This script creates, configures, and starts Nextcloud, also hardens ssh. This script is intended to run on a new physical or virtual host. 

echo "### This script creates, configures, and starts a Nextcloud instance ###"
echo "### This script also hardens ssh ###"

apt update -y >> /dev/null

### Installs some useful packages
apt-get install apt-transport-https ca-certificates curl ntp systemd htop tmux sysstat wget -y >> /dev/null

### These run to update the apt cache, upgrade packages, and cleanup
apt-get update -y >> /dev/null
apt-get upgrade -y >> /dev/null
apt autoremove -y >> /dev/null

echo "### Updating Timezone ###"
timedatectl set-timezone America/Chicago

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
ssh-keygen -M generate -O bits=2048 moduli-2048.candidates
ssh-keygen -M screen -f moduli-2048.candidates moduli-2048

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

echo "### Installing Nextcloud ###"
snap install nextcloud
nextcloud.manual-install <username> <password>
nextcloud.occ user:add <username>
nextcloud.occ group:adduser admin <username>
nextcloud.occ config:system:set trusted_domains 1 --value=domain.example.com
nextcloud.occ config:system:set trusted_domains 2 --value=x.x.x.x
nextcloud.enable-https lets-encrypt
