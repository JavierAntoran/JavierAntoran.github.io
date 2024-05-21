#!/bin/bash

# Secure Bash script to setup a Python coding environment with Conda, Git LFS, and necessary Python libraries.
# This script will also handle SSH key generation for use with GitHub and Huggingface.



# Check if wandb API key is provided
if [ -z "$1" ]; then
  echo "Error: No WANDB API key provided."
  echo "Usage: $0 <wandb_api_key> <workdir>"
  exit 1
fi
if [ -z "$2" ]; then
  echo "Error: No workdir key provided."
  echo "Usage: $0 <wandb_api_key> <workdir>"
  exit 1
fi

WANDB_API_KEY=$1
WORKDIR=$2

echo "Starting the setup of your Python coding environment..."

# Generate SSH key if it does not already exist

# Install Miniconda
echo "Downloading and installing Miniconda..."
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda3
rm miniconda.sh
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
conda init
source ~/.bashrc

# Create and activate conda environment
echo "Creating and activating the genmd conda environment..."
conda create -n genmd python=3.11 -y
conda activate genmd

# Install packages based on CUDA availability
echo "Checking for CUDA and installing appropriate packages..."
if command -v nvidia-smi &>/dev/null; then
    echo "CUDA detected. Installing CUDA-enabled packages..."
    conda install -y -c conda-forge openmm openmmtools mdtraj mdanalysis cudatoolkit=12.1
    conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
    pip install --upgrade "jax[cuda12]"
else
    echo "No CUDA detected. Installing CPU-only packages..."
    conda install -y -c conda-forge openmm openmmtools mdtraj mdanalysis
    conda install -y pytorch torchvision torchaudio cpuonly -c pytorch
    pip install -U jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html
fi

# Install additional Python packages
echo "Installing additional Python packages..."
cd $WORKDIR
pip install -r requirements.txt

# Install the current directory package in editable mode
pip install -e .

# Set WANDB API key
echo "export WANDB_API_KEY=$WANDB_API_KEY" >> ~/.bashrc
echo "WANDB API key set successfully."

# Final environment setup
echo "conda activate genmd" >> ~/.bashrc
echo "echo Device is set to \$DEVICE_NAME" >> ~/.bashrc

echo "export PYTHONPATH=$PWD" >> ~/.bashrc

source ~/.bashrc
