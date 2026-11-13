#!/bin/bash
# DRAF build PenguinOS lynx low-RAM di rom-build-max.
# Jalankan di root tree hasil repo sync, SETELAH aospa_lynx.mk terdaftar.
# Build pertama: vanilla + userdebug + -j2, untuk memisahkan kegagalan
# porting dari konflik GMS (lihat README.md).
set -e
cd ~/penguin
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
# Pelajaran Infinity-X (build 4.2, terbukti): perintah java turbine/KSP
# tidak membawa -Xmx sendiri, jadi heap default JVM (~1,9 GiB) yang
# membatasi — naikkan lewat JAVA_TOOL_OPTIONS sebelum build apa pun.
# 2026-11-13: naik 5120m -> 6144m (gagal 13 Nov 12:59, KSP OOM) -> 6656m, mentok waras mesin 7,7 GB.
export JAVA_TOOL_OPTIONS="-Xmx6656m -XX:+UseG1GC -XX:+UseStringDeduplication"
export LC_ALL=C
export OUT_DIR=out
free -h
# File lokal tree (11 Nov 2026): repo penguin-lynx-build TIDAK disync
# repo, jadi file-file ini harus disalin ke tree sebelum build, dan
# verifikasi marker-nya supaya salinan basi langsung ketahuan.
# - aospa_lynx.mk (produk kita) -> device/google/lynx/
# - tree-files/hardware/qcom-caf/common/Android.bp (shim
#   qti_kernel_headers, pengganti repo caf yang bentrok) ->
#   hardware/qcom-caf/common/
# - daftarkan aospa_lynx.mk di device/google/lynx/AndroidProducts.mk
#   (idempotent; backup .orig-penguin dibuat sekali).
REPO=~/penguin-lynx-build
cp "$REPO/aospa_lynx.mk" device/google/lynx/aospa_lynx.mk
grep -q "VENDOR_PATH := vendor/google/lynx" device/google/lynx/aospa_lynx.mk \
  || { echo "ERROR: aospa_lynx.mk di $REPO basi (tanpa VENDOR_PATH) — sync dulu repo clone-nya"; exit 1; }
mkdir -p hardware/qcom-caf/common
cp "$REPO/tree-files/hardware/qcom-caf/common/Android.bp" hardware/qcom-caf/common/Android.bp
grep -q 'name: "qti_kernel_headers"' hardware/qcom-caf/common/Android.bp \
  || { echo "ERROR: shim qti_kernel_headers hilang di $REPO/tree-files"; exit 1; }
if ! grep -q "aospa_lynx.mk" device/google/lynx/AndroidProducts.mk; then
  [ -f device/google/lynx/AndroidProducts.mk.orig-penguin ] \
    || cp device/google/lynx/AndroidProducts.mk device/google/lynx/AndroidProducts.mk.orig-penguin
  printf 'PRODUCT_MAKEFILES += $(LOCAL_DIR)/aospa_lynx.mk\n' >> device/google/lynx/AndroidProducts.mk
fi
# Patch lokal tree (QTI + Soong rust); idempotent, wajib tiap habis sync.
if [ -f penguin-setup.sh ]; then
  bash penguin-setup.sh || { echo "ERROR: penguin-setup.sh gagal"; exit 1; }
else
  echo "PERINGATAN: penguin-setup.sh tidak ada di tree — patch QTI/Soong belum jalan"
fi
LOG="build-penguin-lynx-$(date +%Y%m%d-%H%M).log"
echo "Log: $LOG"
# rom-build.sh adalah builder resmi PenguinOS (vendor AOSPA).
# Verifikasi dulu di tree: lokasi skrip dan opsi -j/-t/-l setelah sync.
# Bila skrip itu tidak ada di root tree, ganti blok di bawah dengan
# lunch manual: source build/envsetup.sh && lunch aospa_lynx-userdebug
# lalu mka -j2 bacon, dengan log yang sama.
set +e
./rom-build.sh lynx -j2 -t userdebug -l 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
set -e
if [ "$STATUS" -eq 0 ]; then
  echo "BUILD SUKSES. ZIP ada di out/target/product/lynx/"
else
  echo "BUILD GAGAL. Cari 'error:' / 'Killed' (= OOM) di $LOG."
  echo "Jangan make clean. Coba lagi -j1, lalu laporkan 30 baris terakhir log."
fi
exit "$STATUS"
