# Evaluation Board Docker image

This Docker image sets up the software environment to boot an IoT-LAB gateway based on Raspberry PI3 board. This setup used both DHCP/TFTP and NFS server and U-Boot bootloader write on the sdcard. The bootloader will fetch the Linux kernel from the TFTP server and the kernel will mount the root filesystem from the NFS server.

To find out to build a sdcard for RPI3 with U-boot go to the repository [iot-lab-uboot-rpi3](https://github.com/iot-lab/iot-lab-uboot-rpi3)

## Get IoT-LAB gateway image

``` bash
wget -O - https://www.iot-lab.info/yocto-images/dunfell/raspberrypi3/nightly/latest/iotlab-image-gateway-rpi3-raspberrypi3.tar.gz | tar -xzf - -C iotlab/images/gateway_image
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

## Create Docker network 

We use a Docker network with Macvlan driver. A Macvlan interface allows to add multiple MAC address-based logical interfaces to a single physical interface. Docker container attached to macvlan interface will be in the same broadcast domain (BOOTP/DHCP) as the associated physical interface, just attached directly to the host's network (no iptables rules or bridge). Replace `<physical_interface>` by the name of your network interface where the IoT-LAB gateway will be connected.

``` bash
sudo docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.254 -o parent=<physical_interface> macvlan
sudo docker network ls
```

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

To read the serial line you need to connect a USB to serial converter cable (TTL-232R-3V3) along the top edge of the board:

* GPIO14 TXD <-> Yellow
* GPIO15 RXD <-> Orange
* GROUND <-> Black

``` bash
sudo apt-get install python-serial
sudo miniterm.py /dev/ttyUSB0 115200
```

## Update kernel (Optional)

``` bash
cd tftp/rpi3/
wget --no-directories -r -l1 --no-parent -R "*.txt,*.html*,*.tmp" https://www.iot-lab.info/yocto-images/dunfell/linux-rpi3/nightly/latest/
```
