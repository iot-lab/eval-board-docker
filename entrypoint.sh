#!/bin/bash -e

echo "Starting rsyslog..."
service rsyslog start
echo "Starting tftpd-hpa..."
service tftpd-hpa start
echo "Starting nfsd..."
/sbin/rpcbind
service nfs-kernel-server start
echo "Starting dhcpd..."
service isc-dhcp-server start

exec "$@"
