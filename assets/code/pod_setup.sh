#!/bin/bash

# Check if the required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <tpu-name> <zone>"
    exit 1
fi

TPU_NAME=$1
ZONE=$2

# Fetch TPU details using the gcloud command
TPU_INFO=$(gcloud compute tpus describe $TPU_NAME --zone=$ZONE --format="value(networkEndpoints.ipAddress)")

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Failed to get TPU information. Please check the TPU name and zone."
    exit 1
fi

# Split IP addresses on semicolon and convert to array
IFS=';' read -ra ADDR <<< "$TPU_INFO"

# Extract the first IP address
FIRST_IP=${ADDR[0]}

# Extract the first three sections of the first IP address for SSH config
INTERNAL_IP_PREFIX=$(echo $FIRST_IP | cut -d '.' -f 1-3)

# Generate SSH configuration
SSH_CONFIG="Host $INTERNAL_IP_PREFIX.* 127.0.0.1\n   StrictHostKeyChecking no\n   UserKnownHostsFile /dev/null\n   LogLevel ERROR"

# Append to .ssh/config, creating the directory and file if they don't exist
mkdir -p ~/.ssh
echo -e "$SSH_CONFIG" >> ~/.ssh/config

chmod 600 ~/.ssh/config

# Create or overwrite ~/podips.txt with remaining IPs
for (( i=1; i<${#ADDR[@]}; i++ )); do
    echo "${ADDR[i]}" >> ~/podips.txt
done

# Output the IP addresses and SSH config path
echo "IP Addresses for TPU $TPU_NAME in zone $ZONE:"
echo "${ADDR[@]}"
echo "SSH configuration added to ~/.ssh/config"
echo "Remaining IP addresses written to ~/podips.txt"

# Generate SSH key if it does not already exist
SSH_KEY="$HOME/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
    echo "SSH key generated at $SSH_KEY."
else
    echo "SSH key already exists."
fi

# Output SSH public key
echo "Please add this public key to your Gcloud, GitHub and Hugging Face accounts:"
cat "${SSH_KEY}.pub"
echo ""

# Wait for user to confirm SSH key upload
read -p "Press ENTER once you have uploaded the SSH key to continue with the setup."

# Set WANDB API key
echo "Please enter your WANDB API key:"
read wandb_key

# Prompt for device name and set it
echo "Please enter your device name (e.g., cpu, gpu, tpu_v3d):"
read device_name
echo "export DEVICE_NAME=$device_name" >> ~/.bashrc
echo "Device name set as $device_name."

echo "downloading podrun"
wget https://raw.githubusercontent.com/ayaka14732/llama-2-jax/18e9625f7316271e4c0ad9dea233cfe23c400c9b/podrun
chmod +x podrun

pip3 install fabric
./podrun -iw -- echo meow

echo "Installing NFS server and client..."

./podrun -i -- sudo apt-get update -y -qq
./podrun -i -- sudo apt-get upgrade -y -qq

./podrun -- sudo apt-get install -y -qq nfs-common

sudo apt-get install -y -qq nfs-kernel-server
sudo mkdir -p /nfs_share
sudo chown -R nobody:nogroup /nfs_share
sudo chmod 777 /nfs_share

echo "NFS server and client installed."

echo "Adding entry to /etc/exports"

# Add NFS export entry, using sudo
NFS_LINE="/nfs_share  $INTERNAL_IP_PREFIX.0/24(rw,sync,no_subtree_check)"
echo "Adding NFS export entry to /etc/exports"
echo $NFS_LINE | sudo tee -a /etc/exports

echo "NFS export entry added: $NFS_LINE"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

./podrun -- sudo mkdir -p /nfs_share
MOUNT_LINE="-- sudo mount $FIRST_IP:/nfs_share /nfs_share"
./podrun $MOUNT_LINE
./podrun -i -- ln -sf /nfs_share ~/nfs_share



echo "NFS Setup complete!"

# Download data 

echo "Downloading code and data"

# Secure Bash script to setup a Python coding environment with Conda, Git LFS, and necessary Python libraries.
# This script will also handle SSH key generation for use with GitHub and Huggingface.

SHARE_DIR="/nfs_share"
cd $SHARE_DIR
print $PWD

echo "Downloading code and data to $SHARE_DIR..."

# Function to install packages safely
safe_install() {
    sudo apt-get install -y "$@" || { echo "Failed to install $1. Exiting."; exit 1; }
}




# Clone gen-md repository
echo "Cloning gen-md repository..."
git clone git@github.com:lollcat/gen-md.git
cd gen-md
WORKDIR=$(pwd)

# Install Git LFS and clone water_data repository
echo "Installing Git LFS and cloning water_data repository..."
safe_install git-lfs
git lfs install
git clone git@hf.co:datasets/lollcat/water_data




source ~/.bashrc

echo "Setup complete! Running installs on all devices..."

cp ~/slice_install.sh ~/nfs_share/

cd ~
chmod +x ~/nfs_share/slice_install.sh
./podrun -i ~/nfs_share/slice_install.sh $wandb_key $WORKDIR

