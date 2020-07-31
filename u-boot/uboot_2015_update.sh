#!/bin/bash 

# Update U-Boot script on IoT-LAB boards

# U-Boot SPL
MTD0="/dev/mtd0"
# U-Boot
MTD1="/dev/mtd1"
# U-Boot Env
MTD2="/dev/mtd2"

echo "Erase NAND mtd partitions"
flash_erase ${MTD0} 0 0
flash_erase ${MTD1} 0 0
flash_erase ${MTD2} 0 0

echo "Write NAND mtd partitions"
nandwrite -n -o ${MTD0} dev_mtd0_uboot_2015_MLO
nandwrite -n -o ${MTD1} dev_mtd1_uboot_2015_uboot
nandwrite -n -o ${MTD2} dev_mtd2_uboot_2015_config 

ETHADDR=$(cat /sys/class/net/eth0/address)
echo "Write U-boot variable ETHADDR=${ETHADDR}" 
fw_setenv ethaddr ${ETHADDR}
