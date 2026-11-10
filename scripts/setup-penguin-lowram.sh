#!/bin/bash
# DRAF setup mesin build PenguinOS lynx di rom-build-max.
# JANGAN dijalankan sebelum: (1) SSH bisa dibuka, (2) OS dikonfirmasi
# Ubuntu 22.04 LTS lewat `lsb_release -a` dan `df -h`.
# Isi skrip ini mengikuti setup AOSP Ubuntu + resep low-RAM bilalz.
set -e
echo "=== 1. Cek OS dan disk ==="
lsb_release -a
df -h
free -h
nproc
echo "=== 2. Paket build AOSP (Ubuntu 22.04) ==="
sudo apt update
sudo apt install -y git git-lfs repo curl python3 python-is-python3 \
  openjdk-17-jdk build-essential libssl-dev libncurses5-dev \
  libxml2-utils xsltproc unzip zip zlib1g-dev lib32z1-dev \
  libbz2-dev liblz4-tool libtinfo5 libncurses5 bc bison flex \
  g++-multilib gcc-multilib gnupg gperf imagemagick \
  lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool \
  libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-gtk3-dev \
  libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools \
  xsltproc zip zlib1g-dev
echo "=== 3. Swapfile 32 GB di mount terbesar (sesuaikan path) ==="
# JANGAN jalankan baris ini mentah-mentah bila mount terbesar bukan /.
# Periksa df -h dulu, ganti SWAPFILE bila perlu.
SWAPFILE=/swapfile
if [ ! -f "$SWAPFILE" ]; then
  sudo fallocate -l 32G "$SWAPFILE"
  sudo chmod 600 "$SWAPFILE"
  sudo mkswap "$SWAPFILE"
  sudo swapon "$SWAPFILE"
  echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi
echo "=== 4. Git identity ==="
git config --global user.name "hiemzalhuda"
git config --global user.email "hiemz.alhuda1@gmail.com"
echo "=== 5. Workspace + ccache ==="
mkdir -p ~/penguin ~/.ccache
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
# JANGAN turunkan limit: ccache ini dipakai bersama Infinity-X
# (limit 40G, terisi 13,4G, hit rate 49% per 10 Nov 2026).
ccache -M 40G || true
# Catatan: bila Soong/mterp gagal soal sintaks Python (Infinity-X butuh
# CPython 3.12 standalone karena sistem cuma 3.10), pasang Python 3.12
# di ~/python312 dan tambahkan ke PATH sebelum build, jangan ubah
# python3 sistem.
echo "Lanjut manual: cd ~/penguin && repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs"
echo "Lalu salin lynx.xml ke .repo/local_manifests/lynx.xml, repo sync, salin aospa_lynx.mk, lunch."
