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
ENODE0_ID=$(sudo podman run --rm -dt --device ${RADIO0} --name enode0 localhost/jholtom/wiscanet)
echo "Launched with ID: ${ENODE0_ID}"
ENODE0_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" enode0)
echo "IP Address of ENODE0: ${ENODE0_IP}"


echo "Launching ENODE1 for Radio 1..."
echo "Radio 1 located at ${RADIO1}"
ENODE1_ID=$(sudo podman run --rm -dt --device ${RADIO1} --name enode1 localhost/jholtom/wiscanet)
echo "Launched with ID: ${ENODE1_ID}"
ENODE1_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" enode1)
echo "IP Address of ENODE1: ${ENODE1_IP}"


echo "Launching CNODE..."
CNODE_ID=$(sudo podman run --rm -dt --name cnode localhost/jholtom/wiscanet)
echo "Launched with ID: ${CNODE_ID}"
CNODE_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" cnode)
echo "IP Address of CNODE: ${CNODE_IP}"

echo "Configuring WISCANET parameters"
sudo podman exec cnode /bin/bash -c "echo ${ENODE0_IP} > /home/wisca/wdemo/run/usr/cfg/iplist"
sudo podman exec cnode /bin/bash -c "echo ${ENODE1_IP} >> /home/wisca/wdemo/run/usr/cfg/iplist"

echo "Login Credentials"
echo "i.e ssh wisca@${CNODE_IP}"
echo "Username: wisca"
echo "Password: wisca"

echo "To shutdown the network run: sudo podman rm cnode enode0 enode1"

echo "Now opening terminal into CNODE"
sudo podman exec -it cnode /bin/bash
