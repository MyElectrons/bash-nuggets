#!/bin/bash

# HDD wiping complient with the DoD 3-pass wipe "standard" (see also: DoD 5220.22-M and NIST 800.88)
# The alogrythm is different from the original DoD 3-pass - wiping passes go in a reverse order:
# 1st pass - random
# 2nd pass - all ones
# 3rd pass - all zeroes
# This revised wiping secuence, while retaining the data shredding qualities of the original algorythm,
# delivers a ready to use drive, no hiccups at RAID controllers, nor during OS installation.
#
# Additional measures are taken to prevent an accidental wiping of devices in use.
#
# inspired by:
# https://wiki.archlinux.org/title/Securely_wipe_disk/Tips_and_tricks#dd_-_advanced_example
#
# Please retain the reference to:
# https://github.com/MyElectrons/bash-nuggets/Secure-Wipe-HDD



if [[ -e "$1" && -b "$1" ]];then
 NOT_safe="$(lsblk -o "NAME,MOUNTPOINT" ${1//[0-9]/} | grep -e / -e '\]')";
 if [[ -z "$NOT_safe" ]];then
# Here you can use any of your favourite wiping tools
# to wipe destination passed on command line and stored in variable "$1"
   echo 'Wipe it!'
#   exit
   date
   DEVICE=$1
   PASS=$(tr -cd '[:alnum:]' < /dev/urandom | head -c128)
   time openssl enc -aes-256-ctr -pass pass:"$PASS" -nosalt </dev/zero | dd obs=64K ibs=4K of=$DEVICE oflag=direct status=progress
   time tr '\0' '\377' < /dev/zero | dd ibs=4k obs=64K of=$DEVICE oflag=direct status=progress
   time dd if=/dev/zero obs=64K ibs=4K of=$DEVICE oflag=direct status=progress
#
# done wiping
#
  else
   echo 'Not allowed to destroy if any of the partitions is mounted: '"$NOT_safe"
  fi
else
 echo 'Does not exist or not a block device: '"$1"
fi

