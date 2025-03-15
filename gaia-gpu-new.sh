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

# Minta input jumlah node dari user
read -p "Masukkan jumlah node yang ingin dijalankan: " node_count

# Validasi input agar hanya menerima angka
if ! [[ "$node_count" =~ ^[0-9]+$ ]]; then
    echo "Input harus berupa angka positif!"
    exit 1
fi

# Hanya hapus node lama sekali di awal
echo "Menghapus instalasi lama GaiaNet..."
curl -sSfL "https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh" | bash
echo "Instalasi lama telah dihapus."

# Fungsi untuk mengatur dan menjalankan node baru
install_node() {
    i=$1
    home_dir="$HOME/gaia-node-$i"
    gaia_port="8$i"

    # Cek apakah node sudah ada
    if [ -d "$home_dir" ]; then
        echo "Node $i sudah ada, melewati instalasi ulang."
    else
        echo "=== Mengatur GaiaNet Node $i ==="

        # Buat folder node baru & instalasi GaiaNet
        mkdir -p "$home_dir"
        curl -sSfL "https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh" | bash -s -- --ggmlcuda 12 --base "$home_dir"

        # Update konfigurasi GaiaNet
        CONFIG_URL="https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen-2.5-coder-7b-instruct_rustlang/config.json"
        CONFIG_FILE="$home_dir/config.json"

        wget -O "$CONFIG_FILE" "$CONFIG_URL"
        jq '.chat = "https://huggingface.co/gaianet/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q5_K_M.gguf"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
        jq '.chat_name = "Qwen2.5-Coder-3B-Instruct"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"

        # Cek apakah konfigurasi telah diperbarui
        grep '"chat":' "$CONFIG_FILE"
        grep '"chat_name":' "$CONFIG_FILE"
    fi

    # Hentikan proses yang menggunakan port Gaia jika ada
    lsof -t -i:$gaia_port | xargs kill -9 2>/dev/null

    # Jalankan node GaiaNet
    gaianet config --base "$home_dir" --port "$gaia_port"
    gaianet init --base "$home_dir"
    gaianet start --base "$home_dir"
    gaianet info --base "$home_dir"

    echo "=== Node $i selesai dijalankan ==="
}

# Loop untuk menjalankan sejumlah node sesuai input user
for ((i=101; i<101+node_count; i++)); do
    install_node "$i"
done
