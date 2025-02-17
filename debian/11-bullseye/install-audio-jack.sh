#!/bin/bash
# ---------------------------
# This is a bash script for configuring Debian 11 (bullseye) for pro audio.
# ---------------------------
# NOTE: Execute this script by running the following command on your system:
# wget -O - https://raw.githubusercontent.com/mattiabonafini/linux-audio-setup-scripts/blob/main/debian/11-bullseye/install-audio-jack.sh | bash

# Exit if any command fails
set -e

notify () {
  echo "--------------------------------------------------------------------"
  echo $1
  echo "--------------------------------------------------------------------"
}

echo "deb http://deb.debian.org/debian/ bullseye main contrib
deb-src http://deb.debian.org/debian/ bullseye main contrib

deb http://security.debian.org/debian-security bullseye-security main contrib
deb-src http://security.debian.org/debian-security bullseye-security main contrib

# bullseye-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
deb http://deb.debian.org/debian/ bullseye-updates main contrib
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib" | sudo tee /etc/apt/sources.list


# ---------------------------
# Update our system
# ---------------------------
notify "Update the system"
sudo apt update && sudo apt dist-upgrade -y


# ---------------------------
# Install Liquorix kernel
# https://liquorix.net/
# ---------------------------
sudo apt install curl -y
curl 'https://liquorix.net/add-liquorix-repo.sh' | sudo bash
sudo apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64


# ---------------------------
# Install kxstudio and cadence
# Cadence is a tool for managing audio connections to our hardware
# NOTE: Select "YES" when asked to enable realtime privileges
# ---------------------------
notify "Install kxstudio and cadence"
sudo apt-get install apt-transport-https gpgv -y
wget https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_10.0.3_all.deb
sudo dpkg -i kxstudio-repos_10.0.3_all.deb
rm kxstudio-repos_10.0.3_all.deb
sudo apt update
sudo apt install cadence -y


# ---------------------------
# grub
# ---------------------------
notify "Modify GRUB options"
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet threadirqs mitigations=off cpufreq.default_governor=performance"/g' /etc/default/grub
sudo update-grub


# ---------------------------
# sysctl.conf
# ---------------------------
notify "sysctl.conf"
# See https://wiki.linuxaudio.org/wiki/system_configuration for more information.
echo 'vm.swappiness=10
fs.inotify.max_user_watches=600000' | sudo tee -a /etc/sysctl.conf


# ---------------------------
# Add the user to the audio group
# ---------------------------
notify "Add user to the audio group"
sudo adduser $USER audio


# ---------------------------
# The i386 architecture is required for Bitwig and Wine
# ---------------------------
notify "Enable i386 architecture"
sudo dpkg --add-architecture i386
sudo apt update


# ---------------------------
# Install Bitwig
# ---------------------------
# notify "Install Bitwig"
# wget -O bitwig.deb https://downloads.bitwig.com/4.2.3/bitwig-studio-4.2.3.deb
# sudo apt install ./bitwig.deb -y
# rm bitwig.deb


# ---------------------------
# Install Reaper
# ---------------------------
# notify "Install Reaper"
# wget -O reaper.tar.xz http://reaper.fm/files/6.x/reaper658_linux_x86_64.tar.xz
# mkdir ./reaper
# tar -C ./reaper -xf reaper.tar.xz
# sudo ./reaper/reaper_linux_x86_64/install-reaper.sh --install /opt --integrate-desktop --usr-local-bin-symlink
# rm -rf ./reaper
# rm reaper.tar.xz


# ---------------------------
# Yabridge
# Detailed instructions can be found at: https://github.com/robbert-vdh/yabridge/blob/master/README.md
# ---------------------------

# Install Wine (yabridge needs this)
notify "Install Wine"
sudo dpkg --add-architecture i386
wget -nc https://dl.winehq.org/wine-builds/winehq.key
sudo apt-key add winehq.key
rm winehq.key
echo 'deb https://dl.winehq.org/wine-builds/debian/ bullseye main' | sudo tee -a /etc/apt/sources.list
sudo apt update
sudo apt install --install-recommends winehq-staging zenity winetricks -y

# Base wine packages required for proper plugin functionality
winetricks corefonts

# Download and install yabridge
# NOTE: When you run this script, there may be a newer version.
# Check https://github.com/robbert-vdh/yabridge/releases and update the version numbers below if necessary
notify "Install yabridge"
wget -O yabridge.tar.gz https://github.com/robbert-vdh/yabridge/releases/download/3.8.1/yabridge-3.8.1.tar.gz
mkdir -p ~/.local/share
tar -C ~/.local/share -xavf yabridge.tar.gz
rm yabridge.tar.gz
echo '' >> ~/.bash_aliases
echo '# Audio: yabridge path' >> ~/.bash_aliases
echo 'export PATH="$PATH:$HOME/.local/share/yabridge"' >> ~/.bash_aliases
. ~/.bash_aliases

# Create common VST paths
mkdir -p "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
mkdir -p "$HOME/.wine/drive_c/Program Files/Common Files/VST2"
mkdir -p "$HOME/.wine/drive_c/Program Files/Common Files/VST3"

# Add them into yabridge
yabridgectl add "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST2"
yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST3"

# ---------------------------
# Install Windows VST plugins
# This is a manual step for you to run when you download plugins.
# First, run the plugin installer .exe file
# When the installer asks for a directory, make sure you select
# one of the directories above.

# VST2 plugins:
#   C:\Program Files\Steinberg\VstPlugins
# OR
#   C:\Program Files\Common Files\VST2

# VST3 plugins:
#   C:\Program Files\Common Files\VST3
# ---------------------------

# Each time you install a new plugin, you need to run:
# yabridgectl sync

# ---------------------------
# FINISHED!
# Now just reboot, and make music!
# ---------------------------
notify "Done - please reboot."
