#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    apt update && apt upgrade -y && apt install libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential git -y
else
    required_packages=("libcurl4-openssl-dev" "libssl-dev" "libjansson-dev" "automake" "autotools-dev" "build-essential" "git")

    missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package "; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        echo "==================="
        echo "Jika terjadi kesalahan saat proses instalasi, silakan instal paket-paket ini terlebih dahulu."
        echo -e "Paket-paket berikut belum terinstal: \e[91m${missing_packages[*]}\e[0m"
        echo "==================="
    fi
fi


arch=$(uname -m)

if [[ "$arch" == "aarch64" || "$arch" == "armv7l" ]]; then
    branch="ARM"
elif [[ "$arch" == "x86_64" ]]; then
    branch="Verus2.2"
fi

cd ~
git clone --single-branch -b $branch https://github.com/monkins1010/ccminer.git
cd ccminer

if ! bash build.sh; then
    echo "==>  Error: Gagal menjalankan build.sh."
    exit 1
fi

if ! make; then
    echo "==>  Error: Gagal menjalankan make."
    exit 1
fi

cd ~

generate_random_number() {
    echo $(shuf -i 10-99 -n 1)
}

# Menghasilkan nomor acak 2 digit
random_number=$(generate_random_number)

# Membuat nama worker dengan nomor acak
worker="worker${random_number}"

cat <<EOL > autorun.sh
#!/bin/bash

./ccminer/ccminer -a verus -o stratum+tcp://ap.luckpool.net:3960 -u RFZ6jZEky1VxRjZ43oprGDS2ZrEwgpvZgZ.$worker -p x -t 3
EOL
chmod +x autorun.sh
echo
echo "==>  Kompilasi ccminer berhasil."
echo -e "==>  Silahkan ganti wallet addres dan nama worker di \e[92mautorun.sh\e[0m"
echo "==>  Contoh: ganti yang warna hijau"
echo
echo -e "./ccminer/ccminer -a verus -o stratum+tcp://ap.luckpool.net:3960 -u \e[92mRFZ6jZEky1VxRjZ43oprGDS2ZrEwgpvZgZ\e[0m.\e[92m$worker\e[0m -p x -t 3"
echo
