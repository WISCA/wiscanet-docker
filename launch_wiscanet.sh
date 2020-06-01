#!/bin/bash

echo "Determining available B210's..."
# 2500:0020 is the device ID for a B200/B210 series radio connected over USB
# This assumes there will only be 2 B210's attached, but could be modified to support arbitrary numbers
DEVS=$(lsusb -d 2500:0020 | awk '{print $2"/"substr($4, 1, length($4)-1)}')
RADIOBUS=(${DEVS[@]})
RADIO0="/dev/bus/usb/${RADIOBUS[0]}"
RADIO1="/dev/bus/usb/${RADIOBUS[1]}"

echo "Launching ENODE0 for Radio 0..."
echo "Radio 0 located at ${RADIO0}"
ENODE0_ID=$(sudo podman run --rm -dt --cap-add=sys_nice --device ${RADIO0} --name enode0 localhost/jholtom/wiscanet)
echo "Launched with ID: ${ENODE0_ID}"
ENODE0_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" enode0)
echo "IP Address of ENODE0: ${ENODE0_IP}"


echo "Launching ENODE1 for Radio 1..."
echo "Radio 1 located at ${RADIO1}"
ENODE1_ID=$(sudo podman run --rm -dt --cap-add=sys_nice --device ${RADIO1} --name enode1 localhost/jholtom/wiscanet)
echo "Launched with ID: ${ENODE1_ID}"
ENODE1_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" enode1)
echo "IP Address of ENODE1: ${ENODE1_IP}"


echo "Launching CNODE..."
CNODE_ID=$(sudo podman run --rm -dt --privileged --name cnode localhost/jholtom/wiscanet)
echo "Launched with ID: ${CNODE_ID}"
CNODE_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" cnode)
echo "IP Address of CNODE: ${CNODE_IP}"

echo "Configuring WISCANET parameters"
# Configuring CNODE iplist and node XMLs for UMAC_sin demo
sudo podman exec cnode /bin/bash -c "echo ${ENODE0_IP} > /home/wisca/wdemo/run/usr/cfg/iplist"
sudo podman exec cnode /bin/bash -c "echo ${ENODE1_IP} >> /home/wisca/wdemo/run/usr/cfg/iplist"
sudo podman exec cnode /bin/bash -c "mv /home/wisca/wdemo/run/usr/cfg/usrconfig_node0.xml /home/wisca/wdemo/run/usr/cfg/usrconfig_${ENODE0_IP}.xml"
sudo podman exec cnode /bin/bash -c "mv /home/wisca/wdemo/run/usr/cfg/usrconfig_node1.xml /home/wisca/wdemo/run/usr/cfg/usrconfig_${ENODE1_IP}.xml"

# Handle SSH configuration
# Generate keys on each node
sudo podman exec -u wisca cnode ssh-keygen -f /home/wisca/.ssh/id_rsa -q -N ''
sudo podman exec -u wisca enode0 ssh-keygen -f /home/wisca/.ssh/id_rsa -q -N ''
sudo podman exec -u wisca enode1 ssh-keygen -f /home/wisca/.ssh/id_rsa -q -N ''
# Copy all keys to all nodes
echo "Please log into cnode and use ssh-copy-id to distribute keys"
echo "Coming soon this will be handled automatically..."

# Configuring ENODE0 to talk to CNODE
sudo podman exec enode0 /bin/bash -c "sed -i 's/cnode_ip/${CNODE_IP}/' /home/wisca/wdemo/run/enode/bin/sysconfig.xml"

# Configuring ENODE1 to talk to CNODE
sudo podman exec enode1 /bin/bash -c "sed -i 's/cnode_ip/${CNODE_IP}/' /home/wisca/wdemo/run/enode/bin/sysconfig.xml"

echo "Login Credentials"
echo "i.e ssh wisca@${CNODE_IP}"
echo "Username: wisca"
echo "Password: wisca"

echo "To shutdown the network run: sudo podman stop cnode enode0 enode1"
