#!/bin/bash

echo "Configuring host accessible volume..."
echo "Note: This volume WILL be DESTROYED and recreated at every startup"
sudo podman volume rm cnode_wdemo
rm -rfI ${HOME}/wdemo
mkdir -p ${HOME}/wdemo
sudo podman volume create --opt type=none --opt o=bind --opt device=${HOME}/wdemo cnode_wdemo

# Specify Radio Device Strings eg. addr=1.2.3.4 here
RADIO0="addr=192.168.10.2"
RADIO1="addr=192.168.10.7"

# Specify Node MAC Addresses for MATLAB
CNODE_MAC_ADDR="A8:5E:45:8E:90:53"
ENODE0_MAC_ADDR="A8:5E:45:AA:FD:A6"
ENODE1_MAC_ADDR="A8:5E:45:2A:6F:91"

echo "Launching ENODE0 for Radio 0..."
echo "Radio 0 located at ${RADIO0}"
ENODE0_ID=$(sudo podman run --rm -dt --privileged --mac-address="${ENODE0_MAC_ADDR}" --name enode0 localhost/wisca/wiscanet)
echo "Launched with ID: ${ENODE0_ID}"
ENODE0_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" enode0)
echo "IP Address of ENODE0: ${ENODE0_IP}"

echo "Launching ENODE1 for Radio 1..."
echo "Radio 1 located at ${RADIO1}"
ENODE1_ID=$(sudo podman run --rm -dt --privileged --mac-address="${ENODE1_MAC_ADDR}"   --name enode1 localhost/wisca/wiscanet)
echo "Launched with ID: ${ENODE1_ID}"
ENODE1_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" enode1)
echo "IP Address of ENODE1: ${ENODE1_IP}"

echo "Launching CNODE..."
CNODE_ID=$(sudo podman run --rm -dt --privileged --mac-address="${CNODE_MAC_ADDR}" -v cnode_wdemo:/home/wisca/wdemo --name cnode localhost/wisca/wiscanet)
echo "Launched with ID: ${CNODE_ID}"
CNODE_IP=$(sudo podman inspect -f "{{.NetworkSettings.IPAddress}}" cnode)
echo "IP Address of CNODE: ${CNODE_IP}"

echo "Configuring WISCANET parameters"
# Configuring CNODE iplist and node XMLs for UMAC_sin demo
sudo podman exec cnode /bin/bash -c "echo ${ENODE0_IP} > /home/wisca/wdemo/run/usr/cfg/iplist"
sudo podman exec cnode /bin/bash -c "echo ${ENODE1_IP} >> /home/wisca/wdemo/run/usr/cfg/iplist"
sudo podman exec cnode /bin/bash -c "mv /home/wisca/wdemo/run/usr/cfg/usrconfig_node0.xml /home/wisca/wdemo/run/usr/cfg/usrconfig_${ENODE0_IP}.xml"
sudo podman exec cnode /bin/bash -c "mv /home/wisca/wdemo/run/usr/cfg/usrconfig_node1.xml /home/wisca/wdemo/run/usr/cfg/usrconfig_${ENODE1_IP}.xml"
sudo podman exec cnode /bin/bash -c "sed -i 's/replace_me/${RADIO0}/' /home/wisca/wdemo/run/usr/cfg/usrconfig_${ENODE0_IP}.xml"
sudo podman exec cnode /bin/bash -c "sed -i 's/replace_me/${RADIO1}/' /home/wisca/wdemo/run/usr/cfg/usrconfig_${ENODE1_IP}.xml"

# Handle SSH configuration
# Generate keys on each node
sudo podman exec -u wisca cnode ssh-keygen -f /home/wisca/.ssh/id_rsa -q -N ''
sudo podman exec -u wisca enode0 ssh-keygen -f /home/wisca/.ssh/id_rsa -q -N ''
sudo podman exec -u wisca enode1 ssh-keygen -f /home/wisca/.ssh/id_rsa -q -N ''

# Copy all keys to all nodes
mkdir -p keys
sudo podman cp cnode:/home/wisca/.ssh/id_rsa.pub ./keys/cnode.pub
sudo podman cp enode0:/home/wisca/.ssh/id_rsa.pub ./keys/enode0.pub
sudo podman cp enode1:/home/wisca/.ssh/id_rsa.pub ./keys/enode1.pub
cat ./keys/cnode.pub > ./keys/authorized_keys
cat ./keys/enode0.pub >> ./keys/authorized_keys
cat ./keys/enode1.pub >> ./keys/authorized_keys
sudo podman cp ./keys/authorized_keys cnode:/home/wisca/.ssh/authorized_keys
sudo podman cp ./keys/authorized_keys enode0:/home/wisca/.ssh/authorized_keys
sudo podman cp ./keys/authorized_keys enode1:/home/wisca/.ssh/authorized_keys
sudo podman exec -u wisca cnode /bin/bash -c "ssh-keyscan ${CNODE_IP} ${ENODE0_IP} ${ENODE1_IP} > /home/wisca/.ssh/known_hosts"
sudo podman exec -u wisca cnode /bin/bash -c "chown -R wisca:wisca /home/wisca/.ssh; chmod 700 /home/wisca/.ssh; chmod 640 /home/wisca/.ssh/authorized_keys"
sudo podman exec -u wisca enode0 /bin/bash -c "chown -R wisca:wisca /home/wisca/.ssh; chmod 700 /home/wisca/.ssh; chmod 640 /home/wisca/.ssh/authorized_keys"
sudo podman exec -u wisca enode1 /bin/bash -c "chown -R wisca:wisca /home/wisca/.ssh; chmod 700 /home/wisca/.ssh; chmod 640 /home/wisca/.ssh/authorized_keys"
# Removing local keys directory
rm -rf keys

# Configuring ENODE0 to talk to CNODE
sudo podman exec enode0 /bin/bash -c "sed -i 's/cnode_ip/${CNODE_IP}/' /home/wisca/wdemo/run/enode/bin/sysconfig.xml"

# Configuring ENODE1 to talk to CNODE
sudo podman exec enode1 /bin/bash -c "sed -i 's/cnode_ip/${CNODE_IP}/' /home/wisca/wdemo/run/enode/bin/sysconfig.xml"

# Adding MATLAB licenses to each node
sudo podman exec cnode /bin/bash -c "mkdir -p /usr/local/MATLAB/licenses/"
sudo podman exec enode0 /bin/bash -c "mkdir -p /usr/local/MATLAB/licenses/"
sudo podman exec enode1 /bin/bash -c "mkdir -p /usr/local/MATLAB/licenses/"
sudo podman cp ../licenses/cnode.lic cnode:/usr/local/MATLAB/licenses/
sudo podman cp ../licenses/enode0.lic enode0:/usr/local/MATLAB/licenses/
sudo podman cp ../licenses/enode1.lic enode1:/usr/local/MATLAB/licenses/

sudo podman exec cnode /bin/bash -c "echo 'export PATH="/usr/local/MATLAB/bin:$PATH"' >> /home/wisca/.bash_profile"
sudo podman exec enode0 /bin/bash -c "echo 'export PATH="/usr/local/MATLAB/bin:$PATH"' >> /home/wisca/.bash_profile"
sudo podman exec enode1 /bin/bash -c "echo 'export PATH="/usr/local/MATLAB/bin:$PATH"' >> /home/wisca/.bash_profile"

echo "Login Credentials"
echo "i.e ssh wisca@${CNODE_IP}"
echo "Username: wisca"
echo "Password: wisca"

echo "To shutdown the network run: sudo podman stop cnode enode0 enode1"
