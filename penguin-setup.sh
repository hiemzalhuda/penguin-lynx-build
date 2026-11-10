#!/usr/bin/env bash
# penguin-setup.sh — run from the AOSPA source root after `repo sync`
# Applies local Penguin OS patches for Tensor devices (lynx / Pixel 7a).
#
# Diadaptasi dari raj-tirtha/local_manifests penguin-setup.sh
# (penguin-17, buat panther/cheetah). Salin file ini + folder patches/
# dari repo ini ke source root, lalu jalankan dari sana.
#
# PERBEDAAN dari skrip raj-tirtha: dua langkah viridian di skrip aslinya
# (patches/viridian/patch.py dan patches/viridian_brightness_boost/patch.py)
# TIDAK disertakan di sini, karena kedua file itu tidak ada di repo
# raj-tirtha yang terlihat di GitHub (folder patches/ di sana hanya berisi
# kedua file QTI di bawah) — menjalankan skrip aslinya apa adanya akan
# gagal di langkah viridian. Bila file viridian itu ditemukan sumbernya,
# tambahkan kembali langkahnya dan catat asalnya di patches/README.md.
set -euo pipefail
ROOT="$(pwd)"
PATCH_DIR="$ROOT/patches"
LOG="$ROOT/.penguin-setup.log"
: > "$LOG"

patch_error() { echo "ERROR: $1" | tee -a "$LOG"; exit 1; }

echo "Applying qti_a2dp_offload.py" | tee -a "$LOG"
python3 patches/qti_a2dp_offload.py >> "$LOG" 2>&1 || patch_error "qti_a2dp_offload.py FAILED - see $LOG"
echo "Applying qti_noretry.py" | tee -a "$LOG"
python3 patches/qti_noretry.py >> "$LOG" 2>&1 || patch_error "qti_noretry.py FAILED - see $LOG"
echo "Applying soong_rust_prebuilt_binary.py" | tee -a "$LOG"
python3 patches/soong_rust_prebuilt_binary.py >> "$LOG" 2>&1 || patch_error "soong_rust_prebuilt_binary.py FAILED - see $LOG"
echo "Applying soong_rust_prebuilt_image.py" | tee -a "$LOG"
python3 patches/soong_rust_prebuilt_image.py >> "$LOG" 2>&1 || patch_error "soong_rust_prebuilt_image.py FAILED - see $LOG"
echo "Penguin setup complete - see $LOG" | tee -a "$LOG"
