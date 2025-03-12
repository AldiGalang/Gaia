#!/bin/bash

# Ask user for the screen session name
read -rp "Enter the name for the screen session: " SCREEN_NAME

# Function to terminate an old session
terminate_old_session() {
    echo "🔴 Terminating any existing session named '$SCREEN_NAME'..."
    screen -ls | awk -v name="$SCREEN_NAME" '/[0-9]+\.'name'/ {print $1}' | xargs -r -I{} screen -X -S {} quit
}

# Function to check if GaiaNet is running by port
check_port() {
    local port=$1
    if sudo lsof -i :$port > /dev/null 2>&1; then
        echo "✅ Port $port is active. GaiaNet is running."
        return 0
    else
        return 1
    fi
}

# Function to check if GaiaNet is installed correctly
check_gaianet() {
    if ! command -v ~/gaianet/bin/gaianet &> /dev/null; then
        echo "❌ GaiaNet is not found! Please install it first."
        exit 1
    fi
    gaianet_info=$( ~/gaianet/bin/gaianet info 2>/dev/null )
    if [[ -z "$gaianet_info" ]]; then
        echo "❌ GaiaNet is installed but not properly configured. Please reinstall."
        exit 1
    fi
    echo "✅ GaiaNet detected."
}

# Main function to run the chatbot
run_chatbot() {
    echo "🚀 Starting GaiaNet chatbot..."
    terminate_old_session
    check_gaianet

    # Check if any port is active
    ports=(8080 8081 8082 8083)
    active_port_found=0
    echo "🔍 Checking active ports..."
    for port in "${ports[@]}"; do
        if check_port $port; then
            active_port_found=1
        fi
    done

    if [[ $active_port_found -eq 0 ]]; then
        echo "❌ No active ports found! Check node status at: https://www.gaianet.ai/setting/nodes"
        exit 1
    fi

    # Run the chatbot in a screen session
    screen -dmS "$SCREEN_NAME" bash -c '
    curl -O https://raw.githubusercontent.com/AldiGalang/Gaia/refs/heads/main/script.sh && chmod +x script.sh;
    if [ -f "script.sh" ]; then
        ./script.sh | tee -a script.log
    else
        echo "❌ Failed to download gaiachat.sh" | tee -a script.log
        sleep 10
        exit 1
    fi'

    echo "✅ Chatbot is now running in screen session '$SCREEN_NAME'."
    echo "📜 Use the following command to attach to the session: screen -r $SCREEN_NAME"
}

# Run the main function
run_chatbot
