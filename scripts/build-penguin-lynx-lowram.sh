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
export JAVA_TOOL_OPTIONS="-Xmx5120m -XX:+UseG1GC -XX:+UseStringDeduplication"
export LC_ALL=C
export OUT_DIR=out
free -h
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
