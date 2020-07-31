#!/bin/sh 

BOOT_CMD="bootp; setenv bootargs mem=256M console=\${console} root=/dev/nfs ip=dhcp nfsroot=\${serverip}:/iotlab/images/\${ipaddr}/image,nfsvers=3 rw rootwait eth=\${ethaddr}; bootm"

echo "Update U-boot bootcmd env value"
fw_setenv bootcmd ${BOOT_CMD}
