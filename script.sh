#!/bin/bash

# Set API URL untuk mode VPS
set_api_url() {
    API_URL="https://optimize.gaia.domains/v1/chat/completions"
    API_NAME="Optimize"
    echo "🔗 Using API: ($API_NAME)"
}

# Set API URL
set_api_url

# Pastikan jq terinstal sebelum melanjutkan
if ! command -v jq &> /dev/null; then
    echo "❌ jq not found. Installing jq..."
    if sudo -v &>/dev/null; then
        sudo apt update && sudo apt install jq -y
    else
        echo "❌ No sudo access. Please install jq manually."
        exit 1
    fi
fi

# Fungsi untuk menghasilkan pertanyaan acak
generate_random_general_question() {
    local general_questions=(
        "Why is the Renaissance considered a turning point in history?"
        "What is artificial intelligence?"
        "How does machine learning work?"
    )
    echo "${general_questions[RANDOM % ${#general_questions[@]}]}"
}

# Fungsi untuk mengirim permintaan API
send_request() {
    local message="$1"
    local api_key="$2"

    json_data=$(jq -n --arg msg "$message" '{messages: [{role: "system", content: "You are a helpful assistant."}, {role: "user", content: $msg}]}' )

    response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
        -H "Authorization: Bearer $api_key" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$json_data")

    http_status=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)
    response_message=$(echo "$body" | jq -r '.choices[0].message.content' 2>/dev/null)

    if [[ "$http_status" -eq 200 && -n "$response_message" ]]; then
        echo "✅ Response Received: $response_message"
    else
        echo "⚠️ API request failed | Status: $http_status"
    fi
}

# Direktori untuk menyimpan API Key
API_KEY_DIR="$HOME/gaianet"
mkdir -p "$API_KEY_DIR"
API_KEY_LIST=($(ls "$API_KEY_DIR" 2>/dev/null | grep '^apikey_'))

# Pilih atau simpan API Key
if [ ${#API_KEY_LIST[@]} -gt 0 ]; then
    if [ ${#API_KEY_LIST[@]} -eq 1 ]; then
        api_key=$(cat "$API_KEY_DIR/${API_KEY_LIST[0]}")
        echo "✅ Using existing API key: ${API_KEY_LIST[0]}"
    else
        echo "🔑 Select an API key to use:"
        select key in "${API_KEY_LIST[@]}"; do
            if [[ -n "$key" ]]; then
                api_key=$(cat "$API_KEY_DIR/$key")
                echo "✅ Loaded API key from $key"
                break
            else
                echo "❌ Invalid selection. Please try again."
            fi
        done
    fi
else
    read -r -p "Enter your API Key: " api_key
    while true; do
        read -r -p "Enter a name to save this key: " key_name
        key_name=$(echo "$key_name" | tr -d ' ')  # Hapus spasi
        if [ -z "$key_name" ]; then
            echo "❌ Error: Name cannot be empty!"
        elif [ -f "$API_KEY_DIR/apikey_$key_name" ]; then
            echo "⚠️ A key with this name already exists! Choose a different name."
        else
            echo "$api_key" > "$API_KEY_DIR/apikey_$key_name"
            chmod 600 "$API_KEY_DIR/apikey_$key_name"  # Amankan file API Key
            echo "✅ API Key saved as 'apikey_$key_name'"
            break
        fi
    done
fi

# Menanyakan durasi bot akan berjalan
while true; do
    read -r -p "⏳ How many hours do you want the bot to run? " bot_hours
    if [[ "$bot_hours" =~ ^[0-9]+$ && "$bot_hours" -gt 0 ]]; then
        max_duration=$((bot_hours * 3600))
        echo "🕒 The bot will run for $bot_hours hour(s) ($max_duration seconds)."
        break
    else
        echo "⚠️ Invalid input! Please enter a positive number."
    fi
done

# Loop untuk mengirim permintaan secara berkala
start_time=$(date +%s)
while (( $(date +%s) - start_time < max_duration )); do
    message=$(generate_random_general_question)
    send_request "$message" "$api_key"
    sleep 5  # Delay antara permintaan
done

echo "🛑 Time limit reached. Exiting..."
