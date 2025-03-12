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

echo -e "\e[1;36m"
echo "STORAGE NODE BY RISOLMAYOETH"
echo -e "\e[0m"

show_menu() {
    echo "=================================="
    echo "   STORAGE NODE MANAGER  "
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
    sudo apt-get update && sudo apt-get upgrade -y || { echo -e "\033[31m[-] Update system failed!\033[0m"; exit 1; }

    echo -e "\033[32m[+] Installing Dependencies...\033[0m"
    sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq || { echo -e "\033[31m[-] Dependency installation failed!\033[0m"; exit 1; }

    if ! command -v go &> /dev/null; then
        echo -e "\033[32m[+] Installing Go...\033[0m"
        ver="1.22.0"
        wget -q "https://golang.org/dl/go$ver.linux-amd64.tar.gz" || { echo -e "\033[31m[-] Failed to download Go!\033[0m"; exit 1; }
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
        rm "go$ver.linux-amd64.tar.gz"
        echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" | tee -a ~/.bashrc ~/.profile > /dev/null
        source ~/.bashrc
        source ~/.profile
    else
        echo -e "\033[33m[!] Go is already installed, skipping installation.\033[0m"
    fi

    if ! command -v cargo &> /dev/null; then
        echo -e "\033[32m[+] Installing Rust...\033[0m"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || { echo -e "\033[31m[-] Failed to install Rust!\033[0m"; exit 1; }
        echo "source \$HOME/.cargo/env" | tee -a ~/.bashrc ~/.profile > /dev/null
        source "$HOME/.cargo/env"
    else
        echo -e "\033[33m[!] Rust is already installed, skipping installation.\033[0m"
    fi

    echo -e "\033[32m[+] Cloning 0G Storage Node repository...\033[0m"
    rm -rf "$HOME/0g-storage-node"
    git clone https://github.com/0glabs/0g-storage-node.git "$HOME/0g-storage-node" || { echo -e "\033[31m[-] Failed to clone repository!\033[0m"; exit 1; }
    
    cd "$HOME/0g-storage-node"
    git checkout v0.8.4 || { echo -e "\033[31m[-] Failed to checkout branch!\033[0m"; exit 1; }
    git submodule update --init || { echo -e "\033[31m[-] Failed to update submodules!\033[0m"; exit 1; }

    echo -e "\033[32m[+] Building 0G Storage Node...\033[0m"
    cargo build --release || { echo -e "\033[31m[-] Build failed!\033[0m"; exit 1; }

    echo -e "\033[32m[+] Downloading Configuration File...\033[0m"
    mkdir -p "$HOME/0g-storage-node/run"
    wget -q -O "$HOME/0g-storage-node/run/config-testnet-turbo.toml" https://josephtran.co/config-testnet-turbo.toml || { echo -e "\033[31m[-] Failed to download configuration file!\033[0m"; exit 1; }

    echo -e "\033[34mEnter your private key (it will be displayed): \033[0m"
    read PRIVATE_KEY
    echo -e "\033[33m[!] Your private key: $PRIVATE_KEY\033[0m"

    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "\033[31m[-] Private key is empty! Exiting...\033[0m"
        exit 1
    fi

    sed -i 's|^\s*#\?\s*miner_key\s*=.*|miner_key = "'"$PRIVATE_KEY"'"|' "$HOME/0g-storage-node/run/config-testnet-turbo.toml"
    echo -e "\033[32m[+] Private key has been successfully added to the config file.\033[0m"

    echo -e "\033[32m[+] Creating systemd service...\033[0m"
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

    sudo systemctl daemon-reload
    sudo systemctl enable zgs

    echo -e "\033[32m[+] Installation Complete! You can now start your node using:\033[0m"
    echo -e "\033[36m sudo systemctl start zgs \033[0m"
}


start_node() {
    sudo systemctl stop zgs
    echo -e "\033[32m[+] Starting Storage Node...\033[0m"
    sudo systemctl daemon-reload && \
    sudo systemctl enable zgs && \
    sudo systemctl restart zgs && \
    sudo systemctl status zgs
}

change_rpc() {
    CONFIG_FILE="$HOME/0g-storage-node/run/config-testnet-turbo.toml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "\033[31m[-] Configuration file not found!\033[0m"
        return
    fi
    read -p "Enter new RPC endpoint: " NEW_RPC
    sed -i 's|blockchain_rpc_endpoint = .*|blockchain_rpc_endpoint = "'$NEW_RPC'"|' "$CONFIG_FILE"
    echo -e "\033[32m[+] RPC endpoint updated to: $NEW_RPC\033[0m"
}

check_logs() {
    LOG_FILE="$HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)"
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "\033[31m[-] Log file not found!\033[0m"
        return
    fi
    tail -f "$LOG_FILE"
}

check_peers() {
    trap "echo -e '\n\033[31m[-] Stopping peer check...\033[0m'; exit" SIGINT
    while true; do
        response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
        logSyncHeight=$(echo "$response" | jq '.result.logSyncHeight')
        connectedPeers=$(echo "$response" | jq '.result.connectedPeers')
        echo -e "logSyncHeight: \033[32m$logSyncHeight\033[0m, connectedPeers: \033[34m$connectedPeers\033[0m"
        sleep 5
    done
}

main_menu() {
    read -p "Enter your choice: " choice
    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) change_rpc ;;
        4) check_logs ;;
        5) check_peers ;;
        6) exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
}

show_menu
main_menu
