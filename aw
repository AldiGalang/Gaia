#!/bin/bash

# Tampilkan banner
echo -e "\e[1;36m"
echo "████████╗ ██╗ ███████╗  ██████╗  ██╗      ███╗   ███╗  █████╗  ██╗   ██╗  ██████╗  ███████╗ ████████╗ ██╗  ██╗"
echo "██╔═══██║ ██║ ██╔════╝ ██╔═══██╗ ██║      ████╗ ████║ ██╔══██╗ ╚██╗ ██╔╝ ██╔═══██╗ ██╔════╝ ╚══██╔══╝ ██║  ██║"
echo "███████║  ██║ ███████╗ ██║   ██║ ██║      ██╔████╔██║ ███████║  ╚████╔╝  ██║   ██║ ███████╗    ██║    ███████║"
echo "██╔══███║ ██║ ╚════██║ ██║   ██║ ██║      ██║╚██╔╝██║ ██╔══██║   ╚██╔╝   ██║   ██║ ██═════║    ██║    ██╔══██║"
echo "██║   ██║ ██║ ███████║ ╚██████╔╝ ███████╗ ██║ ╚═╝ ██║ ██║  ██║    ██║    ╚██████╔╝ ███████║    ██║    ██║  ██║"
echo "╚═╝   ╚═╝ ╚═╝ ╚══════╝  ╚═════╝  ╚══════╝ ╚═╝     ╚═╝ ╚═╝  ╚═╝    ╚═╝     ╚═════╝  ╚══════╝    ╚═╝    ╚═╝  ╚═╝"
echo -e "\e[0m"

show_menu() {
    echo "=================================="
    echo "   STORAGE NODE BY RISOLMAYOETH  "
    echo "=================================="
    echo "1. Install Node"
    echo "2. Start Node"
    echo "3. Change RPC"
    echo "4. Check Logs"
    echo "5. Check Peers"
    echo "6. Exit"
}

install_node() {
    echo -e "\033[32m[+] Updating System...\033[0m"
    sudo apt-get update && sudo apt-get upgrade -y

    echo -e "\033[32m[+] Installing Dependencies...\033[0m"
    sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev

    echo -e "\033[32m[+] Checking Go installation...\033[0m"

    if command -v go &> /dev/null
    then
        echo -e "\033[33m[!] Go is already installed. Skipping installation.\033[0m"
    else
        echo -e "\033[32m[+] Installing Go...\033[0m"
        cd $HOME
        ver="1.22.0"
        wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
        rm "go$ver.linux-amd64.tar.gz"
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bashrc
        source ~/.bashrc
        echo -e "\033[32m[+] Go installation completed!\033[0m"
    fi

        echo -e "\033[32m[+] Checking Rust installation...\033[0m"
    
    if command -v rustc &> /dev/null
    then
        echo -e "\033[33m[!] Rust is already installed. Skipping installation.\033[0m"
    else
        echo -e "\033[32m[+] Installing Rust...\033[0m"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        echo -e "\033[32m[+] Rust installation completed!\033[0m"
    fi


    echo -e "\033[32m[+] Cloning 0g-storage-node repository...\033[0m"
    cd $HOME
    rm -rf 0g-storage-node
    git clone https://github.com/0glabs/0g-storage-node.git
    cd 0g-storage-node
    git checkout v0.8.4
    git submodule update --init
    cargo build --release

    echo -e "\033[32m[+] Downloading Configuration File...\033[0m"
    wget -O $HOME/0g-storage-node/run/config-testnet-turbo.toml https://josephtran.co/config-testnet-turbo.toml

    if [ -f "$HOME/0g-storage-node/run/config-testnet-turbo.toml" ]; then
        echo -e "\033[32m[+] Configuration file downloaded successfully.\033[0m"
    else
        echo -e "\033[31m[-] Failed to download configuration file!\033[0m"
        exit 1
    fi

    # Input private key tanpa hidden
    printf '\033[34mEnter your private key: \033[0m'
    read PRIVATE_KEY

    # Update konfigurasi miner_key
    sed -i 's|^\s*#\?\s*miner_key\s*=.*|miner_key = "'"$PRIVATE_KEY"'"|' $HOME/0g-storage-node/run/config-testnet-turbo.toml
    echo -e "\033[32m[+] Private key has been added to the config file.\033[0m"

    # Buat systemd service tanpa menjalankannya langsung
    echo -e "\033[32m[+] Creating Systemd Service...\033[0m"
    sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd tanpa langsung menjalankan service
    sudo systemctl daemon-reload

    echo -e "\033[32m[+] Node installation complete! Use option 2 to start the node.\033[0m"

    show_menu
}

start_node() {
    echo -e "\033[32m[+] Starting Storage Node...\033[0m"
    sudo systemctl enable --now zgs
    echo -e "\033[32m[+] Node is running! Use 'sudo journalctl -u zgs -f' to check logs.\033[0m"

    show_menu
}

show_menu

read -p "Enter your choice: " choice
case $choice in
    1) install_node ;;
    2) start_node ;;
    3) echo "Change RPC - Not implemented yet." ;;
    4) sudo journalctl -u zgs -f ;;
    5) echo "Check Peers - Not implemented yet." ;;
    6) exit 0 ;;
    *) echo "Invalid choice!" ;;
esac
