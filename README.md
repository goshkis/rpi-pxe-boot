# Raspberry netboot from PXE
I bought Turing Pi board and building a cluster. When things go south, reinstalling bad Raspberry module to slot0 and reflashing via USB is kinda annoying.

Instead, after intital flash I enable usbboot and later can boot a bad module from my devbox and automatically flash it.

This project is to boot Raspberries using PXE and NFS-hosted / and /boot partitions and flash with some default image.

This document is just my notes, and obviously not ready for someone's consumption.

## dnsmasq on host
`sudo dnsmasq -d --conf-file=/home/egor/proj/rpi-pxe-boot/dnsmasq.conf`
See the config file in this projects directory


## NFS on host
```
root@nuc:/home/egor/proj# cat /etc/exports 
...
/srv/nfs/client1 *(rw,sync,no_subtree_check,no_root_squash)
/srv/tftp *(rw,sync,no_subtree_check,no_root_squash)
```

## Client's configuration

### /etc/fstab
```root@nuc:/srv/nfs/client1/etc# cat ./fstab 
proc            /proc           proc    defaults          0       0
10.10.0.1:/srv/tftp /boot nfs defaults,vers=4.1,proto=tcp 0 0
```

### /boot/cmdline.txt
```root@nuc:/srv/tftp# cat ./cmdline.txt 
console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=10.10.0.1:/srv/nfs/client1,vers=4.1,proto=tcp rw ip=dhcp rootwait elevator=deadline
```

### Enabling network boot on a fresh node
`echo program_usb_boot_mode=1 | sudo tee -a /boot/config.txt`

### /etc/rc.local
```set -x
exec &> /tmp/rc.local.log

echo "Imaging local filesystem using device..."
sudo dd if=/home/pi/image/current.img of=/dev/mmcblk0 bs=1M

echo "Mounting /boot to enable ssh"
sudo mount /dev/mmcblk0p1 /home/pi/image/boot
sudo touch /home/pi/image/boot/ssh

echo "Unmounting /boot"
sudo umount /home/pi/image/boot

echo "Done imaging. Rebooting"
# I do not reboot actually. Instead I test installation via serial console
```

## Links
https://dbtechreviews.com/2020/10/turing-pi-installing-i2c-and-turing-pi-scripts/
https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/net.md
https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/net_tutorial.md

## Other

### Masquerade
`iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -j MASQUERADE`

### List partitions in RPi image file
`fdisk -l /home/egor/Downloads/2020-08-20-raspios-buster-armhf-lite.img`
see mountroot.sh on how to mount these partitions (filesystem offset needs to be specified)


### Turing Pi flip slot
```
pi@raspberrypi:~ $ cat ./slot2restart 
#!/bin/bash

i2cset -m 0x04 -y 1 0x57 0xf2 0x00
sleep 1
i2cset -m 0x04 -y 1 0x57 0xf2 0xff
```