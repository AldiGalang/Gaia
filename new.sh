#!/bin/bash

# Update & upgrade sistem
apt update && apt upgrade -y
apt-get update && apt-get upgrade -y

# Install dependencies
apt install -y pciutils lsof curl nvtop btop jq

# Install CUDA Toolkit
CUDA_KEYRING="cuda-keyring_1.1-1_all.deb"
wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/$CUDA_KEYRING"
dpkg -i $CUDA_KEYRING
apt-get update
apt-get install -y cuda-toolkit-12-8
rm -f $CUDA_KEYRING

# Konfigurasi variabel
i=101
home_dir="$HOME/gaia-node-$i"
backup_dir="$HOME/gaia-backup/gaia-node-$i"
gaia_port="8$i"

# Backup jika folder node sudah ada
if [ -d "$home_dir" ]; then
    echo "$home_dir already exists."
    read -p "BACKUP to $backup_dir? [y/n] " -n 1 choice
    echo ""

    if [[ $choice =~ ^[Yy]$ ]]; then
        mkdir -p "$backup_dir/gaia-frp"
        cp -n "$home_dir/nodeid.json" "$backup_dir/"
        cp -n "$home_dir/gaia-frp/frpc.toml" "$backup_dir/gaia-frp/"
    else
        echo "NO BACKUP CHOSEN for $home_dir."
    fi
fi

# Hentikan proses yang menggunakan port Gaia
lsof -t -i:$gaia_port | xargs kill -9

# Hapus folder node lama & uninstall GaiaNet
rm -rf "$home_dir"
curl -sSfL "https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh" | bash

# Buat folder node baru & instalasi GaiaNet
mkdir -p "$home_dir"
curl -sSfL "https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh" | bash -s -- --ggmlcuda 12 --base "$home_dir"

# Restore backup jika tersedia
if [ -d "$backup_dir" ]; then
    read -p "RESTORE FROM $backup_dir? [y/n] " -n 1 choice
    echo ""

    if [[ $choice =~ ^[Yy]$ ]]; then
        cp -f "$backup_dir/nodeid.json" "$home_dir/"
        cp -f "$backup_dir/gaia-frp/frpc.toml" "$home_dir/gaia-frp/"
    else
        echo "NO RESTORE CHOSEN for $home_dir."
    fi
fi

# Konfigurasi tambahan
source "$HOME/.bashrc"
gaianet stop

# Update konfigurasi GaiaNet
CONFIG_URL="https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen-2.5-coder-7b-instruct_rustlang/config.json"
CONFIG_FILE="$home_dir/config.json"

wget -O "$CONFIG_FILE" "$CONFIG_URL"
jq '.chat = "https://huggingface.co/gaianet/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q5_K_M.gguf"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
jq '.chat_name = "Qwen2.5-Coder-3B-Instruct"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"

# Cek apakah konfigurasi telah diperbarui
grep '"chat":' "$CONFIG_FILE"
grep '"chat_name":' "$CONFIG_FILE"

# Inisialisasi & jalankan GaiaNet
gaianet config --base "$home_dir" --port "$gaia_port"
gaianet init --base "$home_dir"
gaianet start --base "$home_dir"
gaianet info --base "$home_dir"
