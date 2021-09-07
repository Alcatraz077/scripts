#/bin/bash

cp /etc/apt/sources.list /etc/apt/sources.list.bak

echo "
###### Ubuntu Main Repos (Bionic - 18.04 LTS)
deb http://apt-mirror/ubuntu/ bionic main restricted universe multiverse 
deb-src http://apt-mirror/ubuntu/ bionic main restricted universe multiverse 

###### Ubuntu Update Repos (Bionic - 18.04LTS)
deb http://apt-mirror/ubuntu/ bionic-security main restricted universe multiverse 
deb http://apt-mirror/ubuntu/ bionic-updates main restricted universe multiverse 
deb-src http://apt-mirror/ubuntu/ bionic-security main restricted universe multiverse 
deb-src http://apt-mirror/ubuntu/ bionic-updates main restricted universe multiverse 

###### Ubuntu Main Repos (Focal - 20.04 LTS)
deb http://apt-mirror/ubuntu/ focal main restricted universe multiverse 
deb-src http://apt-mirror/ubuntu/ focal main restricted universe multiverse 

###### Ubuntu Update Repos (Focal - 20.04 LTS)
deb http://apt-mirror/ubuntu/ focal-security main restricted universe multiverse 
deb http://apt-mirror/ubuntu/ focal-updates main restricted universe multiverse 
deb-src http://apt-mirror/ubuntu/ focal-security main restricted universe multiverse 
deb-src http://apt-mirror/ubuntu/ focal-updates main restricted universe multiverse  
" >> /etc/apt/sources.list
