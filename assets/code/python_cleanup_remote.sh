#!/bin/bash

rm -rf /tmp/libtpu_lockfile /tmp/tpu_logs

# Get the current user's username
USERNAME=$(whoami)

# Find and kill processes with 'python' in their name belonging to the user
pgrep -u $USERNAME -f python | xargs -r kill

echo "All processes containing 'python' for user $USERNAME have been killed."



