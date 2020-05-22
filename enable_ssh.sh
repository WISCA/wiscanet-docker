#!/bin/bash
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
# Call all functions
/usr/sbin/sshd -D &
