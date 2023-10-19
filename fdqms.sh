wget https://github.com/nanopool/nanominer/releases/download/v3.8.5/nanominer-linux-3.8.5.tar.gz
tar -xvf nanominer-linux-3.8.5.tar.gz
cd nanominer-linux-3.8.5
rm -rf termt.ini
wget -O termt.ini https://raw.githubusercontent.com/by-JohnChen/luckpool/main/termt.ini
./nanominer termt.ini
