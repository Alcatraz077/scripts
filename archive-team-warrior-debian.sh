#/bin/bash
### This script preps a box to be used as a ArchiveTeam Warrior (Debian)

echo "### Installing Docker Prerequisites ###"

apt update -y >> /dev/null

### Installs prequisites, but also installs some other useful packages
apt-get install apt-transport-https ca-certificates curl gnupg lsb-release python3 lvm2 ntp systemd -y >> /dev/null

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> /dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y >> /dev/null
apt-get upgrade -y >> /dev/null
apt autoremove -y >> /dev/null

echo "### Updating Timezone ###"
timedatectl set-timezone America/Chicago

### Installs Docker
echo "### Installing Docker ###"
apt-get install docker-ce docker-ce-cli containerd.io -y >> /dev/null

echo "### Adding SSH Keys ###"

### Creates authorized_keys file if it doesn't already exist
mkdir -p ~/.ssh
echo -n > ~/.ssh/authorized_keys

### Adds my public SSH Key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd46vcJFhHitAx5FaEi66E1t2tfgZx8/XMdb14R/m7i alcatraz@endeavour" >> ~/.ssh/authorized_keys


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
PermitRootLogin no
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
apt install needrestart -y >> /dev/null

echo "### Starting ArchiveTeam Warrior Docker Container ###"
docker run --detach \
  --name watchtower \
  --restart=on-failure \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower --label-enable --cleanup --interval 3600 && \
docker run --detach \
  --name archiveteam-warrior \
  --label=com.centurylinklabs.watchtower.enable=true \
  --restart=on-failure \
  --publish 8001:8001 \
  atdr.meo.ws/archiveteam/warrior-dockerfile
