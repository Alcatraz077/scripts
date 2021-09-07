#/bin/bash

cp /etc/apt/sources.list /etc/apt/sources.list.bak

echo "
# deb cdrom:[Debian GNU/Linux 10.4.0 _Buster_ - Official amd64 NETINST 20200509-10:25]/ buster main

# deb cdrom:[Debian GNU/Linux 10.4.0 _Buster_ - Official amd64 NETINST 20200509-10:25]/ buster main

deb http://apt-mirror/debian buster main contrib non-free
deb-src http://apt-mirror/debian buster main contrib non-free

deb http://apt-mirror/debian-security buster/updates main
deb-src http://apt-mirror/debian-security buster/updates main

# buster-updates, previously known as 'volatile'
deb http://apt-mirror/debian/ buster-updates main
deb-src http://apt-mirror/debian/ buster-updates main

# This system was installed using small removable media
# (e.g. netinst, live or single CD). The matching 'deb cdrom'
# entries were disabled at the end of the installation process.
# For information about how to configure apt package sources,
# see the sources.list(5) manual.
" >> /etc/apt/sources.list
