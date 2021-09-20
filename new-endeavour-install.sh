#/bin/bash

echo "### Updating System ###"
sudo pacman -Syu -y
sudo pacman -S blender discord firefox thunderbird keepassxc filezilla vscode htop neofetch ntfs-3g nvidia nvidia-dkms lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader linux-zen curl wget wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader lutris steam meson systemd git dbus glibc openssl zlib expat qt5 sudo pacman python-curio python-requests-toolbelt python-sniffio python-trio libreoffice -y


echo "RADV_PERFTEST=aco" >> /etc/environment
echo "### Installing Minecraft ###"
cd ~
git clone https://aur.archlinux.org/minecraft-launcher.git
cd minecraft-launcher
makepkg -si

echo "### Downloading MakeMKV ###"
cd ~
sudo usermod -a -G optical alcatraz
mkdir MakeMKV
cd MakeMKV
wget https://www.makemkv.com/download/makemkv-oss-1.16.4.tar.gz
wget https://www.makemkv.com/download/makemkv-bin-1.16.4.tar.gz
tar -xf makemkv-oss-1.16.4.tar.gz
tar -xf makemkv-bin-1.16.4.tar.gz
echo "### cd into MakeMKV/makemkv-oss-1.16.4 and run ./configure, then make, then sudo make install. Then, cd into MakeMKV/makemkv-bin-1.16.4, run make, then sudo make install ###"



