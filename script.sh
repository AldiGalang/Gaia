#!/bin/bash

show_menu() {
    echo "Installation Script By RisolMayoETH"
    echo "1. Install Node"
    echo "2. Node Information"
    echo "3. Exit"
}

install_multiple_nodes() {
  read -p "How much you want install node?: " node_count

  # Validasi input (hanya angka positif)
  if ! [[ "$node_count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Input should positif example 1" 
    return 1
  fi

  sudo apt update && sudo apt upgrade -y
  sudo apt-get update && sudo apt-get upgrade -y

  for ((i=1; i<=node_count; i++)); do
    node_name=$(printf "gaia-%02d" $i)
    port=$((8000 + i - 1))  
    
    # **Cek apakah node sudah ada**
    if [[ -d "$node_path" ]]; then
      echo "⚠️ Node $node_name already exists, skipping..."
      continue
    fi

    mkdir -p "$HOME/$node_name"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$HOME/$node_name"
    source $HOME/.bashrc
    gaianet init --base "$HOME/$node_name" --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
    gaianet config --base "$HOME/$node_name" --port "$port"
    gaianet init --base "$HOME/$node_name"
  done

  # Kill proses yang berjalan di semua port jika ada
  sudo lsof -t -i:8000-$(($port)) | xargs kill -9 2>/dev/null

  # Running all node
  for ((i=1; i<=node_count; i++)); do
    node_name=$(printf "gaia-%02d" $i)
    gaianet start --base "$HOME/$node_name"
  done
  
  echo "✅ All nodes have been installed successfully!"
  sleep 2
  return
}
  show_info() {
    echo "Displating Node Info..."
    # Save Directory Gaia Node Information
    base_dir="$HOME"
    
      # Loop*
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
    read -p "Select an option (1-3): " choice
    case $choice in
        1) install_multiple_nodes ;;
        2) show_info ;;
        3) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    echo ""
done
