# Evaluation Board Docker image

This Docker image sets up the software environment to boot an IoT-LAB gateway board. This setup used both DHCP/TFTP and NFS server and U-Boot bootloader write on the NAND flash memory (eg. Variscite VAR-SOM-AM35 ARM Cortex A8). The bootloader will fetch the Linux kernel from the TFTP server and the kernel will mount the root filesystem from the NFS server. This image can also be used to update the U-boot bootloader from Linux or via USB to Serial Converter cable and can replace VAR-SOM-AM35 evaluation kit board.

## Get IoT-LAB gateway image

``` bash
wget -O - https://www.iot-lab.info/yocto-images/krogoth/var-som-am35/stable/latest/iotlab-image-gateway-var-som-am35.tar.gz | tar -xzf - -C iotlab/images/gateway_image
```

## Generate a SSH key-pair

Generate ssh keys (without passphrase) and add public key on the gateway image filesystem

``` bash
mkdir ssh && ssh-keygen -f $PWD/ssh/id_rsa
mkdir -m 755 iotlab/images/gateway_image/home/root/.ssh
cat ssh/id_rsa.pub > iotlab/images/gateway_image/home/root/.ssh/authorized_keys
chmod 644 iotlab/images/gateway_image/home/root/.ssh/authorized_keys
```

The gateway image filesystem will be mount as a Docker volume. The file permissions in the volume are identical for Docker host as well as container. The sshd server of the IoT-LAB gateway board only works with root permissions. 

``` bash 
sudo chown -R root:root iotlab/images/gateway_image
```

## Build Docker image

``` bash
sudo docker build -t eval-board:latest .
```

> This image uses Debian Jessie to be compatible with the old U-boot configuration (i.e. U-boot bootcmd env variable without nfsvers=3 option). So it is possible to update U-boot on older boards.

## Create Docker network 

We use a Docker network with Macvlan driver. A Macvlan interface allows to add multiple MAC address-based logical interfaces to a single physical interface. Docker container attached to macvlan interface will be in the same broadcast domain (BOOTP/DHCP) as the associated physical interface, just attached directly to the host's network (no iptables rules or bridge). Replace `<physical_interface>` by the name of your network interface where the IoT-LAB gateway will be connected.

``` bash
sudo docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.254 -o parent=<physical_interface> macvlan
sudo docker network ls
```

> The Docker network host mode (the container shares the host's networking namespace) could also work but the NFS server (i.e. nfs-kernel-server) doesn't work properly with this configuration.


## Start Docker container

For the NFS server we need to load Kernel NFS modules on Docker host and runs the container with privileged support.

``` bash
sudo modprobe nfsd
sudo modprobe nfs
sudo docker run --hostname eval-board --privileged --network macvlan -it -v $PWD/iotlab:/iotlab -v $PWD/tftp:/var/iot-lab/tftp eval-board bash
sudo docker ps
sudo docker stop <container_id>
sudo docker rm <container_id> 
```

## Debug serial line

To read the serial line of the IoT-LAB gateway you need to connect a USB to serial converter cable (TTL-232R-3V3) at the back of it:

* TXD <-> Yellow
* RXD <-> Orange
* GND <-> Black

``` bash
sudo apt-get install python-serial
sudo miniterm.py /dev/ttyUSB0 115200
```

## Update U-boot from serial line

Stop the U-boot sequence (Hit any key to stop autoboot ...) and from the prompt type this comand

``` bash
VAR-SOM-AM35 # setenv bootfile boot.scr; bootp; source
VAR-SOM-AM35 # reset
```

## Update U-boot from Linux

``` bash
root@eval-board:~# scp -r u-boot <gateway_ip> (192.168.1.[2..10])
root@eval-board~# ssh <gateway_ip>
*-iotlab-board~# cd u-boot
*-iotlab-board~# ./uboot_2015_update.sh (update U-boot with 2015.01 version)
*-iotlab-board~# ./uboot_bootcmd_update.sh (Debian Stretch migration = update U-boot bootcmd env variable with nfsvers=3)
```
