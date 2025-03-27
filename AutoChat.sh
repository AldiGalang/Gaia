#!/bin/bash

# Buat dan masuk ke folder Gaiabot
mkdir -p Gaiabot
cd Gaiabot

# Minta input jumlah clone dari user
read -p "Masukkan jumlah repo yang ingin di-clone: " clone_count

# Validasi input harus angka positif
if ! [[ "$clone_count" =~ ^[0-9]+$ ]]; then
    echo "Input harus berupa angka positif!"
    exit 1
fi

# Looping untuk melakukan git clone
for ((i=101; i<101+clone_count; i++)); do
    echo "Cloning gaiabot-$i..."
    git clone https://github.com/AldiGalang/Gaiabot.git "gaiabot-$i"
done

echo "✅ Semua repo telah berhasil di-clone!"

# File input yang berisi API keys
input_file="../nama.txt"

# Pastikan file nama.txt ada
if [[ ! -f "$input_file" ]]; then
    echo "❌ File $input_file tidak ditemukan!"
    exit 1
fi

# Baca semua folder gaiabot-* dalam array
folders=(gaiabot-*)

# Hitung jumlah folder & jumlah baris dalam nama.txt
folder_count=${#folders[@]}
line_count=$(wc -l < "$input_file")

# Pastikan jumlah baris cukup untuk jumlah folder
if [[ "$line_count" -lt "$folder_count" ]]; then
    echo "❌ Jumlah baris di $input_file kurang dari jumlah folder gaiabot-*!"
    exit 1
fi

echo "📂 Memasukkan API keys dari $input_file ke masing-masing folder gaiabot-*/file_api_keys.txt..."

# Loop untuk memasukkan setiap baris ke folder yang sesuai
index=0
while IFS= read -r line; do
    folder="${folders[$index]}"
    if [[ -d "$folder" ]]; then
        echo "$line" > "$folder/file_api_keys.txt"
        echo "✅ Baris ke-$((index+1)) dimasukkan ke $folder/file_api_keys.txt"
    fi
    ((index++))
    if [[ $index -ge $folder_count ]]; then
        break
    fi
done < "$input_file"

echo "✅ Semua API keys telah dimasukkan ke masing-masing folder gaiabot-*/file_api_keys.txt!"

# Hitung ulang jumlah folder
folders=(gaiabot-*)

# Jika tidak ada folder gaiabot-*, hentikan skrip
if [[ ${#folders[@]} -eq 0 ]]; then
    echo "❌ Tidak ada folder gaiabot-* ditemukan!"
    exit 1
fi

echo "📂 Ditemukan ${#folders[@]} folder gaiabot-*. Membuat screen dan menjalankan setup..."

# Menjalankan bot sesuai jumlah yang dimasukkan
for ((i=101; i<101+clone_count; i++))
do
    screen_name="gaiabot-$i"
    screen -dmS $screen_name bash -c "
        cd $screen_name && 
        sudo apt install -y python3 && 
        sudo apt install -y python3.12-venv && 
        python3 -m venv myenv && 
        source myenv/bin/activate && 
        pip install -r requirements.txt && 
        python3 bot.py
    "
done

echo "Menjalankan $clone_count bot dari gaiabot-101 hingga gaiabot-$((100+clone_count))"

