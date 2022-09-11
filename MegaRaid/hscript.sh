#!/bin/bash

# prerequisites: lsscsi, smarmontools, MegaCli64
#
# This script lists for all attached drives:
# Target Id; Device Id; Location; Serial #; OS Device Name; Size; SMART Defects count and Power On hours
#
# Please retain the reference to:
# https://github.com/MyElectrons/bash-nuggets/MegaRaid


perform_target() {
  ./MegaCli64 -LdpdInfo -a0 |
    awk '/Target Id:/ {printf("%s \t", $3)} /Device Id:/ {printf("%s \t", $3)} /Connected Port Number:/ {printf("%s \t", $4)} /Inquiry Data:/ {printf("%s%s\t\n", $3, $5)}'
}


prn_all() {
  arg_arr=($1) # split line into array
  target_id=${arg_arr[0]}
  device_id=${arg_arr[1]}
  connection=${arg_arr[2]}
  serial_num=${arg_arr[3]}
# SCSI Id may need to be modified:
  scsi_id="0:2:"$target_id":0"
  dev_name=$(lsscsi -b $scsi_id | awk '{print $2}')
  dev_size=$(lsblk -n -d $dev_name -o SIZE)
  smart=$(smartctl -S on -a -d megaraid,"$device_id" "$dev_name" | awk '\
    /Reallocated_Sector_Ct/ {printf("Realloc %s ", $10)} \
    /Power_On_Hours/ {printf("Power_On %s\n", $10)} \
    /Elements in grown defect list:/ {printf("Defects  %s\n", $6)} \
    /Accumulated power on time, hours:minutes/ {printf("Power_On %s\n", $6)} \
    ')

    echo "Trgt:" ${arg_arr[0]} "Dev:" ${arg_arr[1]} "Loc:" $connection $serial_num $dev_name $dev_size $smart
}

export -f prn_all

echo "$(perform_target)" | xargs -I{} bash -c 'prn_all "$@"' _ {}


# lsscsi -b '*:2:0:*'
# lsblk -n -d /dev/sdb
# lsblk -n -d /dev/sdb -o SIZE
