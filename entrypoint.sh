#!/bin/bash
set -m
# Start SSH Server
echo "Generating SSH Host Key"
sudo ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
echo "Starting SSHD"
sudo /usr/sbin/sshd &

echo "Container Internal IP is: $(awk 'END{print $1}' /etc/hosts)"

# Fire up a shell to interact with
/bin/bash
