#!/bin/bash

# Start SSH Server
sudo /usr/sbin/sshd &

echo "Container Internal IP is: $(awk 'END{print $1}' /etc/hosts)"

# Fire up a shell to interact with
/bin/bash
