#!/bin/bash

# Update & upgrade sistem
apt update && apt upgrade -y
apt-get update && apt-get upgrade -y

# Install dependencies
apt install -y pciutils lsof curl nvtop btop jq

# Install CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update
apt-get -y install cuda-toolkit-12-8

lsof -t -i:8101 | xargs kill -9
rm -rf $HOME/gaianet
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh' | bash
mkdir $HOME/gaianet
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --ggmlcuda 12
source $HOME/.bashrc
wget -O "$HOME/gaianet/config.json" https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen-2.5-coder-7b-instruct_rustlang/config.json
CONFIG_FILE="$HOME/gaianet/config.json"
jq '.chat = "https://huggingface.co/gaianet/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q5_K_M.gguf"' "$CONFIG_FILE" > tmp.$$.json && mv tmp.$$.json "$CONFIG_FILE"
jq '.chat_name = "Qwen2.5-Coder-3B-Instruct"' "$CONFIG_FILE" > tmp.$$.json && mv tmp.$$.json "$CONFIG_FILE"
grep '"chat":' $HOME/gaianet/config.json
grep '"chat_name":' $HOME/gaianet/config.json
gaianet config --port 8101
gaianet init
gaianet start
gaianet info
