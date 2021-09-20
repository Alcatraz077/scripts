#/bin/bash
### This script installs and configures cacti
echo "### Installing apache2, php, mariadb and updating packages ###"

apt update -y >> /dev/null
### Installs php, apache2, and mariadb also installs some other useful packages
apt-get install curl wget apt-transport-https ntp php apache2 mariadb-server snmp snmpd snmp-mibs-downloader rrdtool libapache2-mod-php php-{mysql,curl,net-socket,gd,intl,pear,imap,memcache,pspell,tidy,xmlrpc,snmp,mbstring,gmp,json,xml,common,ldap} -y >> /dev/null

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

echo "### Configuring PHP ###"
### Configuring PHP
cp /etc/php/7.2/apache2/php.ini /etc/php/*/apache2/php.ini.bak
sed -i 's#;date.timezone =#date.timezone = America/Chicago#' /etc/php/7.2/apache2/php.ini
sed -i 's#memory_limit = 128M#memory_limit = 512M#' /etc/php/7.2/apache2/php.ini
sed -i 's#max_execution_time = 30#max_execution_time = 300#' /etc/php/7.2/apache2/php.ini

echo "### Configuring Apache ###"
cp /etc/apache2/conf-enabled/security.conf /etc/apache2/conf-enabled/security.conf.bak
sed -i 's#ServerTokens OS#ServerTokens Prod#' /etc/apache2/conf-enabled/security.conf

cp /etc/apache2/apache2.conf
echo "ServerName cacti.example.com" >> /etc/apache2/apache2.conf
echo "ServerAdmin admin@example.com" >> /etc/apache2/apache2.conf

echo "### Configuring UFW ###"
ufw allow http
ufw allow https

systemctl restart apache2 >> /dev/null

echo "### Configuring mariadb ###"
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak

echo "
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]

#
# * Basic Settings
#
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking

innodb_file_format=Barracuda
innodb_large_prefix=1
collation-server=utf8mb4_unicode_ci
character-set-server=utf8mb4
innodb_doublewrite=ON
max_heap_table_size=128M
tmp_table_size=128M
join_buffer_size=128M
innodb_buffer_pool_size=1G
innodb_flush_log_at_timeout=3
innodb_read_io_threads=32
innodb_write_io_threads=16
innodb_io_capacity=5000
innodb_io_capacity_max=10000
innodb_buffer_pool_instances=9

# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
bind-address            = 127.0.0.1

#
# * Fine Tuning
#
key_buffer_size         = 16M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched
myisam_recover_options  = BACKUP
#max_connections        = 100
#table_cache            = 64
#thread_concurrency     = 10

#
# * Query Cache Configuration
#
query_cache_limit       = 1M
query_cache_size        = 16M

#
# * Logging and Replication
#
# Both location gets rotated by the cronjob.
# Be aware that this log type is a performance killer.
# As of 5.1 you can enable the log at runtime!
#general_log_file        = /var/log/mysql/mysql.log
#general_log             = 1
#
# Error log - should be very few entries.
#
log_error = /var/log/mysql/error.log
#
# Enable the slow query log to see queries with especially long duration
#slow_query_log_file    = /var/log/mysql/mariadb-slow.log
#long_query_time = 10
#log_slow_rate_limit    = 1000
#log_slow_verbosity     = query_plan
#log-queries-not-using-indexes
#
# The following can be used as easy to replay backup logs or for replication.
# note: if you are setting up a replication slave, see README.Debian about
#       other settings you may need to change.
#server-id              = 1
#log_bin                        = /var/log/mysql/mysql-bin.log
expire_logs_days        = 10
max_binlog_size   = 100M
#binlog_do_db           = include_database_name
#binlog_ignore_db       = exclude_database_name

#
# * InnoDB
#
# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!

#
# * Security Features
#
# Read the manual, too, if you want chroot!
# chroot = /var/lib/mysql/
#
# For generating SSL certificates you can use for example the GUI tool "tinyca".
#
# ssl-ca=/etc/mysql/cacert.pem
# ssl-cert=/etc/mysql/server-cert.pem
# ssl-key=/etc/mysql/server-key.pem
#
# Accept only connections using the latest and most secure TLS protocol version.
# ..when MariaDB is compiled with OpenSSL:
# ssl-cipher=TLSv1.2
# ..when MariaDB is compiled with YaSSL (default in Debian):
# ssl=on

#
# * Character sets
#
# MySQL/MariaDB default is Latin1, but in Debian we rather default to the full
# utf8 4-byte character set. See also client.cnf
#
#character-set-server  = utf8mb4
#collation-server      = utf8mb4_general_ci

#
# * Unix socket authentication plugin is built-in since 10.0.22-6
#
# Needed so the root database user can authenticate without a password but
# only when running as the unix root user.
#
# Also available for other users if required.
# See https://mariadb.com/kb/en/unix_socket-authentication-plugin/

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

# This group is only read by MariaDB-10.1 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-10.1]
" >> /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl restart mariadb

echo "### Creating and configuring SQL Database ###"
mysql -u root -p
CREATE DATABASE cacti DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ;
echo "
GRANT ALL PRIVILEGES ON cacti.* TO 'cacti_user'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT SELECT ON mysql.time_zone_name TO cacti_user@localhost;
ALTER DATABASE cacti CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
FLUSH PRIVILEGES;
" >> cacti.sql
mysql cacti < cacti.sql > output.tab

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

echo "### Installing Cacti ###"
git clone -b 1.2.x  https://github.com/Cacti/cacti.git
mv cacti /var/www/html
mysql -u root cacti < /var/www/html/cacti/cacti.sql
mv /var/www/html/cacti/include/config.php.dist /var/www/html/cacti/include/config.php
