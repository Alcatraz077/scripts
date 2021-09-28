#/bin/bash
### This script installs and configures apt-mirror
echo "### Installing apache2 and updating packages ###"

apt update -y >> /dev/null
### Installs apache2 and apt-mirror, but also installs some other useful packages
apt-get install curl wget apt-transport-https dirmngr ntp systemd apache2 apt-mirror -y >> /dev/null

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

echo "### Configuring Apache ###"
### Configures Apache
mkdir -p /var/www/html/packages
chown www-data:www-data /var/www/html/packages

cp /etc/apt/mirror.list /etc/apt/mirror.list.bak
rm /etc/apt/mirror.list
echo "
############# config ##################
#
set base_path    /var/www/html/packages
#
# set mirror_path  $base_path/mirror
# set skel_path    $base_path/skel
# set var_path     $base_path/var
# set cleanscript $var_path/clean.sh
# set defaultarch  <running host architecture>
# set postmirror_script $var_path/postmirror.sh
# set run_postmirror 0
set nthreads     20
set _tilde 0
#
############# end config ##############

###### Ubuntu Main Repos (Bionic - 18.04 LTS)
deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse 

###### Ubuntu Update Repos (Bionic - 18.04LTS)
deb http://us.archive.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse 
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse 

###### Ubuntu Main Repos (Focal - 20.04 LTS)
deb http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 

###### Ubuntu Update Repos (Focal - 20.04 LTS)
deb http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
deb http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 

###### Ubuntu Main Repos (Hirsute - 21.04 LTS)
deb http://us.archive.ubuntu.com/ubuntu/ hirsute main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ hirsute main restricted universe multiverse 

###### Ubuntu Update Repos (Hirsute - 21.04 LTS)
deb http://us.archive.ubuntu.com/ubuntu/ hirsute-security main restricted universe multiverse 
deb http://us.archive.ubuntu.com/ubuntu/ hirsute-updates main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ hirsute-security main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ hirsute-updates main restricted universe multiverse 


clean http://us.archive.ubuntu.com/ubuntu

#PopOS Sources
deb http://apt.pop-os.org/proprietary $(lsb_release -cs) main
" >> /etc/apt/mirror.list

echo "### Cron job to run apt-mirror at 5AM every Sunday ###" >> /var/spool/cron/crontabs/root
echo "0 5 * * 1 apt-mirror" >> /var/spool/cron/crontabs/root

apt-mirror


