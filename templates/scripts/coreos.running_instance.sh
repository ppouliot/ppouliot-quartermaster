#!/bin/bash
ACTIVE_INTERFACE=`/usr/bin/ip route get 1 | /usr/bin/tr -s " " | /usr/bin/cut -d " " -f5`
NEWHOSTNAME=`/usr/bin/ifconfig $ACTIVE_INTERFACE | /usr/bin/grep "ether" | /usr/bin/tr -s " " | /usr/bin/cut -d " " -f3 | /usr/bin/sed -e "s/://g;"`
echo $ACTIVE_INTERFACE
echo $NEWHOSTNAME
sudo hostname -s $NEWHOSTNAME
sudo hostnamectl set-hostname $NEWHOSTNAME

# Download cloud-config
curl -O http://<%= @fqdn %>/<%= @distro %>/<%= @autofile %>/<%= @name %>.<%= @autofile %>
sed -i "/hostname: coreos/c\hostname: $NEWHOSTNAME" ./<%= @name %>.<%= @autofile %>

# Run install 

if [ -e "/dev/vda" ]
then
  for v_partition in $(sudo parted -s /dev/vda print|awk '/^ / {print $1}')
  do
    sudo parted -s /dev/vda rm ${v_partition}
  done
 # Zero MBR
  sudo dd if=/dev/zero of=/dev/vda bs=512 count=1
  sudo coreos-install -d /dev/vda -C <%= @release %> -c <%= @name %>.<%= @autofile %>
fi


if [ -e "/dev/sda" ]
then
  for partition in $(sudo parted -s /dev/sda print|awk '/^ / {print $1}')
  do
    sudo parted -s /dev/sda rm ${partition}
  done
  # Zero MBR
  sudo dd if=/dev/zero of=/dev/sda bs=512 count=1
  sudo coreos-install -d /dev/sda -C <%= @release %> -c <%= @name %>.<%= @autofile %>
fi

# Reboot 
sudo reboot