#!/bin/bash

show_menu() {
    echo "Installation Script By RisolMayoETH"
    echo "1. Install Node"
    echo "2. Node Information"
    echo "3. Exit"
}

install_multiple_nodes() {
  read -p "How many nodes do you want to install?: " node_count

  # Validasi input (hanya angka positif)
  if ! [[ "$node_count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Input should be a positive number, example: 1" 
    return 1
  fi

  sudo apt update && sudo apt upgrade -y
  sudo apt-get update && sudo apt-get upgrade -y

  for ((i=1; i<=node_count; i++)); do
    node_name=$(printf "gaia-%02d" $i)
    node_path="$HOME/$node_name"
    port=$((8000 + i - 1))             

    # **Cek apakah node sudah ada**
    if [[ -d "$node_path" ]]; then
      echo "⚠️ Node $node_name already exists, skipping..."
      continue
    fi

    echo "🚀 Installing node: $node_name..."
    mkdir -p "$node_path"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$node_path"
    source $HOME/.bashrc
    gaianet init --base "$node_path" --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
    gaianet config --base "$node_path" --port "$port"
    gaianet init --base "$node_path"
  done

  # Running all nodes
  for node_path in "$HOME"/gaia-*; do
    if [[ -d "$node_path" ]]; then
      echo "🟢 Starting node: $(basename $node_path)..."
      gaianet start --base "$node_path"
    fi
  done
  
  echo "✅ All new nodes have been installed successfully!"
  sleep 2
  return
}

show_info() {
    echo "📡 Displaying Node Info..."
    base_dir="$HOME"
    
    # Loop untuk membaca semua folder node yang ada
    for node_path in "$base_dir"/gaia-*; do
        if [[ -d "$node_path" ]]; then
            echo "ℹ️  Node Info for: $(basename $node_path)"
            gaianet info --base "$node_path"
        fi
    done
}

# **Loop Menu**
while true; do
    show_menu
    read -p "Select an option (1-3): " choice
    case $choice in
        1) install_multiple_nodes ;;
        2) show_info ;;
        3) echo "🚪 Exiting..."; exit 0 ;;
        *) echo "❌ Invalid option. Please try again." ;;
    esac
    echo ""
done
