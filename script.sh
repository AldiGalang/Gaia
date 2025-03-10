#!/bin/bash

show_menu() {
    echo "Installation Script By RisolMayoETH"
    echo "1. Install Node"
    echo "2. Exit"
    echo "============================"
}

install_multiple_nodes() {
  read -p "Masukkan jumlah node Gaia yang ingin diinstal: " node_count

  # Validasi input (hanya angka positif)
  if ! [[ "$node_count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Input harus berupa angka positif!" 
    return 1
  fi

  sudo apt update && sudo apt upgrade -y
  sudo apt-get update && sudo apt-get upgrade -y

  for ((i=1; i<=node_count; i++)); do
    node_name=$(printf "gaia-%02d" $i)  # Format nama: gaia-01, gaia-02, ...
    port=$((8000 + i - 1))              # Port mulai dari 8000, 8001, 8002, ...

    mkdir -p "$HOME/$node_name"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$HOME/$node_name"
    source $HOME/.bashrc
    gaianet init --base "$HOME/$node_name" --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
    gaianet config --base "$HOME/$node_name" --port "$port"
    gaianet init --base "$HOME/$node_name"
  done

  # Kill proses yang berjalan di semua port jika ada
  sudo lsof -t -i:8000-$(($port)) | xargs kill -9 2>/dev/null

  # Menjalankan semua node
  for ((i=1; i<=node_count; i++)); do
    node_name=$(printf "gaia-%02d" $i)
    gaianet start --base "$HOME/$node_name" &
  done
}
  show_info() {
    echo "Displating Node Info..."
    # Direktori tempat node Gaianet disimpan
    base_dir="$HOME"
    
      # Loop melalui setiap folder dengan nama yang sesuai pola gaia-*
    for node_path in "$base_dir"/gaia-*; do
        # Pastikan hanya folder yang diproses
        if [[ -d "$node_path" ]]; then
            echo "Menampilkan informasi untuk node: $node_path"
            gaianet info --base "$node_path"
        fi
    done
}
while true; do
    show_menu
    read -p "Select an option (1-7): " choice
    case $choice in
        1) install_multiple_nodes ;;
        2) show_info ;;
        3) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    echo ""
done
