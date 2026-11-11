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
echo "Applying qcom_gps_legacy_namespace.py" | tee -a "$LOG"
python3 patches/qcom_gps_legacy_namespace.py >> "$LOG" 2>&1 || patch_error "qcom_gps_legacy_namespace.py FAILED - see $LOG"
echo "Applying aospa_vintf_matrix.py (langkah 6)" | tee -a "$LOG"
python3 patches/aospa_vintf_matrix.py >> "$LOG" 2>&1 || patch_error "aospa_vintf_matrix.py FAILED - see $LOG"
echo "Applying aospa_fcm_remove.py (langkah 7)" | tee -a "$LOG"
python3 patches/aospa_fcm_remove.py >> "$LOG" 2>&1 || patch_error "aospa_fcm_remove.py FAILED - see $LOG"
# Langkah 8 (build #19): sembunyikan vendor/qcom/build dari Kati/Soong.
# File vendor/qcom/build/tasks/kernel_definitions.mk ikut ter-include Kati
# dan mendefinisikan ulang target dtb.img (bentrok dengan
# build/make/core/Makefile:1049) karena guard-nya hanya
# TARGET_PREBUILT_KERNEL — kosong buat lynx (kernel prebuilt di boot.img,
# TARGET_NO_KERNEL=true). .find-ignore memangkas direktori dari pemindaian
# find yang menghasilkan daftar subdir-makefiles Kati (pola yang sama
# dipakai raj-tirtha untuk tree QCOM lain). Keenam file tasks di sana
# semuanya khusus QCOM, tidak dibutuhkan lynx.
if [ -d vendor/qcom/build ]; then
  touch vendor/qcom/build/.find-ignore
  echo "hid vendor/qcom/build (.find-ignore)" | tee -a "$LOG"
fi
echo "Penguin setup complete - see $LOG" | tee -a "$LOG"
