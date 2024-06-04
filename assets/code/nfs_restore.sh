#!/bin/bash

if [ -z "$FIRST_IP" ]; then
    if [ $# -eq 0 ]; then
        echo "No arguments supplied and FIRST_IP not set. Usage: $0 <first-ip>"
        exit 1
    fi
    FIRST_IP=$1
fi

MOUNT_LINE="-- sudo mount $FIRST_IP:/nfs_share /nfs_share"
./podrun $MOUNT_LINE
./podrun -i -- ln -sf /nfs_share ~/nfs_share

