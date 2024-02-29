#!/bin/bash

# Download latest: wget https://raw.githubusercontent.com/omiq/piusb/main/setup.sh -O setup.sh

if [[ $EUID -ne 0 ]]; then
    echo "_______________________________"
    echo "Please use Sudo or run as root."
    echo "==============================="
    echo ""
    echo ""
    exit
fi

wget https://raw.githubusercontent.com/omiq/piusb/main/usb_share_watchdog.py -O usb_share_watchdog.py

echo "dtoverlay=dwc2" >> /boot/config.txt
echo "dwc2" >> /etc/modules

# 16GB = 16384
echo "Creating the USB stick storage. This might take some time!"
dd bs=1M if=/dev/zero of=/piusb.bin count=16384
mkdosfs /piusb.bin -F 32 --mbr=yes -n PIUSB
echo "USB storage created. Continuing configuration ..."

# Create the mount
mkdir /mnt/usbstick
chmod +w /mnt/usbstick
echo "/piusb.bin /mnt/usbstick vfat rw,users,user,exec,umask=000 0 0" >> /etc/fstab
mount -a
sudo modprobe g_mass_storage file=/piusb.bin stall=0 ro=0

# Dependencies
apt-get install samba winbind python3 python3-pip -y
pip3 install watchdog

# Share
echo "[usbstick]" >> /etc/samba/smb.conf
echo "browseable = yes" >> /etc/samba/smb.conf
echo "path = /mnt/usbstick" >> /etc/samba/smb.conf
echo "guest ok = yes" >> /etc/samba/smb.conf
echo "read only = no" >> /etc/samba/smb.conf
echo "create mask = 0777" >> /etc/samba/smb.conf
echo "comment = PiUSB" >> /etc/samba/smb.conf
echo "public = yes" >> /etc/samba/smb.conf
echo "only guest = yes" >> /etc/samba/smb.conf
echo "browseable = yes" >> /etc/samba/smb.conf
echo "directory mask = 0755" >> /etc/samba/smb.conf
echo "force create mask = 0777" >> /etc/samba/smb.conf
echo "force directory mask = 0755" >> /etc/samba/smb.conf
echo "force user = root" >> /etc/samba/smb.conf
echo "force group = root" >> /etc/samba/smb.conf
systemctl restart smbd.service

# Watchdog
cp usb_share_watchdog.py /usr/local/share/
chmod +x /usr/local/share/usb_share_watchdog.py

# Run on boot
echo "/usr/bin/python3 /usr/local/share/usb_share_watchdog.py &" >> /etc/rc.local
/usr/bin/python3 /usr/local/share/usb_share_watchdog.py &

# Fin?
echo ""
echo "Done!"
echo ""
