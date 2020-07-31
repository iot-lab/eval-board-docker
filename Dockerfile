FROM debian:jessie

RUN apt-get update && apt-get install -y --no-install-recommends \
  isc-dhcp-server \
  tftpd-hpa \
  nfs-kernel-server \
  rsyslog \
  tcpdump \
  net-tools \
  ssh \
  vim \
  && apt-get clean \ 
  && rm -rf /var/lib/apt/lists/*

ADD entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]

# SSH
RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh
ADD ssh/id_rsa /root/.ssh/id_rsa
ADD ssh/id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa && \
    chmod 644 /root/.ssh/id_rsa.pub

# DHCP
ADD dhcpd/isc-dhcp-server /etc/default/isc-dhcp-server
ADD dhcpd/dhcpd.conf /etc/dhcp/dhcpd.conf

# NFS
ADD nfsd/exports /etc/exports
ADD nfsd/nfs-kernel-server /etc/default/nfs-kernel-server
ADD nfsd/nfs-common /etc/default/nfs-common
ADD nfsd/hosts.allow /etc/hosts.allow
ADD nfsd/services /etc/services
RUN mkdir -p /iotlab
VOLUME /iotlab

# TFTP
RUN mkdir -p /var/iot-lab/tftp 
ADD tftpd/tftpd-hpa /etc/default/tftpd-hpa
VOLUME /var/iot-lab/tftp 
RUN chmod -R 777 /var/iot-lab/tftp && chown -R nobody /var/iot-lab/tftp

# U-BOOT
COPY u-boot /root/u-boot

WORKDIR /root/
