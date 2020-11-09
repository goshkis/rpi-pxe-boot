#!/bin/bash

[[ -z $1 ]] && echo "Specify raspios image to mount root partition from" && exit 1

#IMAGE=/home/egor/Downloads/2020-08-20-raspios-buster-armhf-lite.img

IMAGE=$1
PSTART=$(fdisk -o Device,Start -l $IMAGE | awk '$1 ~ /img2/ {print $2}')
mount $IMAGE -o loop,offset=$(( 512 * $PSTART)) ./imageroot