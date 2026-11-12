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
# Langkah 9 (analisa pencegahan 11 Nov 2026): sembunyikan 7 direktori QCOM
# yang terverifikasi kode mati buat lynx. Verifikasi: tidak ada referensi
# dari file produk lynx (device-lynx.mk/gs201/lynx-vendor.mk/aospa-target.mk);
# satu-satunya penyebutan adalah dari device/qcom/common (qti-telephony.mk)
# yang TIDAK ter-include buat lynx (components.mk digerbang
# is-board-platform-in-list(QCOM_BOARD_PLATFORMS) — gs201 bukan QCOM),
# plus file platform AOSPA buat HP QCOM lain (waipio/kalama/lahaina/kona/
# msmnile) yang tidak dipakai lynx; dibuktikan juga dari variabel produk
# hasil build (librmnetctl = 0, ipacm tidak ada di soong variables).
# .find-ignore hanya memangkas pemindaian find (Soong/Kati); inherit-product
# eksplisit tetap bisa membaca file di dalamnya bila suatu hari dibutuhkan.
# Daftar ini SAMA dengan yang dipakai raj-tirtha (panther/cheetah) — tapi
# di sini terverifikasi per direktori ke tree lynx, bukan disalin buta.
# JANGAN sembunyikan: hardware/qcom/wlan (PRODUCT_PACKAGES device-lynx.mk),
# device/qcom/common (di-inherit aospa-target.mk), vendor/qcom/sdclang
# (di-inherit aospa-target.mk), vendor/qcom/opensource/core-utils*
# (utils.mk di-include + vendor_bootjars.mk aktif buat lynx: tcmiface),
# vendor/qcom/common (sudah di-prune dari Soong, #12), vendor/qcom/build
# (sudah disembunyikan langkah 8).
for d in vendor/qcom/opensource/data-ipa-cfg-mgr \
         vendor/qcom/opensource/data-ipa-cfg-mgr-legacy \
         vendor/qcom/opensource/dataservices \
         vendor/qcom/opensource/recovery-ext \
         vendor/qcom/opensource/thermal-hal \
         vendor/qcom/opensource/libvmmem \
         hardware/qcom/bootctrl; do
  [ -d "$d" ] && touch "$d/.find-ignore"
done
echo "hid 7 dir QCOM mati (.find-ignore)" | tee -a "$LOG"
# Langkah 10 (build #20 gagal 11 Nov 22:34, error dtb.img yang SAMA dgn #19):
# .find-ignore langkah 8 TIDAK mempan buat file build/tasks/*.mk — file
# itu dikumpulkan Kati lewat jalur lain (configuration.list /
# subdir_makefiles) yang tidak menghormati .find-ignore; buktinya
# vendor_prop_context_restriction.mk dari dir yang sama tetap di-include
# Kati, dan kernel_definitions.mk ikut dievaluasi (warning baris 142/253).
# Perbaikan: guard di LEVEL FILE — lewati seluruh isi file bila
# TARGET_NO_KERNEL=true (lynx: gs201/BoardConfig-common.mk:56). Buat
# perangkat QCOM perilaku tidak berubah. Skrip idempotent.
python3 patches/qcom_kernel_definitions_guard.py . | tee -a "$LOG"
# Langkah 11 (build #21 gagal 12 Nov 02:19, "unknown target otapackage"):
# repo Lineage android_device_google_lynx-kernels HANYA berisi 8 file
# config — .ko/boot.img/dtbo TIDAK PERNAH ada di git (.gitignore
# mengabaikan *.img/*.ko). Tanpa boot.img, BOARD_PREBUILT_BOOTIMAGE
# kosong → INSTALLED_BOOTIMAGE_TARGET kosong → build_ota_package=false
# (build/make/core/Makefile:5916-5929) → target otapackage tidak ada.
# Kernel prebuilt yang dipakai di sini dibangun dari source 3 Nov 2026
# (Bazel 529/529, GKI android14-6.1-2026-03_r24, 6.1.162) dan TERBUKTI
# jalan di Infinity-X 4.2; salinannya ada di tree Infinity-X di server
# yang sama. Bila sumber tidak ada, JANGAN diam-diam lanjut: cetak
# peringatan keras (build akan gagal lagi di otapackage) — bangun kernel
# dari source via manifest Lineage android_kernel_google_gs-6.1_manifest
# + build_lynx.sh, lalu salin hasilnya ke device/google/lynx-kernels/6.1/.
if [ ! -f device/google/lynx-kernels/6.1/boot.img ]; then
  if [ -f /root/infinityx/device/google/lynx-kernels/6.1/boot.img ]; then
    cp -a /root/infinityx/device/google/lynx-kernels/6.1/. device/google/lynx-kernels/6.1/
    echo "kernel prebuilt disalin dari tree Infinity-X (113M)" | tee -a "$LOG"
  else
    echo "PERINGATAN: kernel prebuilt tidak ada (boot.img hilang) dan tree Infinity-X tidak ditemukan — build akan gagal 'unknown target otapackage'. Bangun kernel dari source (manifest android_kernel_google_gs-6.1_manifest, build_lynx.sh) lalu salin ke device/google/lynx-kernels/6.1/." | tee -a "$LOG"
  fi
fi
# Langkah 12 (build #22 gagal 12 Nov 09:37, ninja "symbols/.../dump_modem
# missing"): graft rust_prebuilt_binary langkah 3 tidak lengkap —
# build/soong/rust/rust.go AOSPA tidak punya case
# *prebuiltBinaryDecorator di getSymbolInfo() (dan cek di IsPrebuilt()),
# padahal Lineage punya keduanya. Akibatnya Soong tidak membuat rule
# symbols buat dump_modem/gpuflag, sementara rule install Kati memakai
# file symbols itu sebagai order-only dep. Modul cc_prebuilt_binary
# dengan strip:none yang sama (gs_watchdogd, dump_modemlog) PUNYA rule
# symbols — jadi ini spesifik rust_prebuilt_binary, bukan strip:none.
# Skrip idempotent; bandingkan dengan build/soong/rust/rust.go tree
# Lineage (Infinity-X).
echo "Applying soong_rust_prebuilt_binary_symbols.py (langkah 12)" | tee -a "$LOG"
python3 patches/soong_rust_prebuilt_binary_symbols.py >> "$LOG" 2>&1 || patch_error "soong_rust_prebuilt_binary_symbols.py FAILED - see $LOG"
echo "Penguin setup complete - see $LOG" | tee -a "$LOG"
