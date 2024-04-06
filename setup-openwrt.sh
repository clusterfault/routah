#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Remove old img if it exists
rm -f *.img

# Download and extract openwrt x86_64 img
curl -O https://downloads.openwrt.org/releases/23.05.3/targets/x86/64/openwrt-23.05.3-x86-64-generic-ext4-combined-efi.img.gz
set +o errexit
# openwrt gz has trailing garbage
gunzip openwrt-23.05.3-x86-64-generic-ext4-combined-efi.img.gz
set -o errexit

# Flash the image to disk
sudo dd if=openwrt-23.05.3-x86-64-generic-ext4-combined-efi.img of=/dev/sda

# Fix partition table
printf 'p\nw\n' | sudo fdisk /dev/sda

#Grow root partition to fill the disk
sudo growpart /dev/sda 2
sudo resize2fs /dev/sda2

#Create files and dirs for openwrt chroot
sudo mkdir -p /mount/openwrt/{proc,sys,dev}
sudo mount /dev/sda2 /mount/openwrt
sudo mount -t proc /proc /mount/openwrt/proc/
sudo mount --rbind /sys /mount/openwrt/sys/
sudo mount --rbind /dev /mount/openwrt/dev/
echo "nameserver 8.8.8.8" > resolv.conf
sudo mkdir -p /mount/openwrt/tmp/lock
sudo mv resolv.conf /mount/openwrt/tmp/resolv.conf

# Install packages in OpenWRT
sudo chroot /mount/openwrt/ opkg update
sudo chroot /mount/openwrt/ opkg install dockerd docker luci-app-dockerman
sudo chroot /mount/openwrt/ wget https://github.com/jerrykuku/luci-theme-argon/releases/download/v1.8.3/luci-theme-argon_1.8.3-20230710_all.ipk -O luci-theme-argon_1.8.3-20230710_all.ipk 
sudo chroot /mount/openwrt/ opkg install luci-theme-argon_1.8.3-20230710_all.ipk
sudo chroot /mount/openwrt/ wget https://github.com/jerrykuku/luci-app-argon-config/releases/download/v0.9/luci-app-argon-config_0.9_all.ipk -O luci-app-argon-config_0.9_all.ipk
sudo chroot /mount/openwrt/ opkg install luci-app-argon-config_0.9_all.ipk
