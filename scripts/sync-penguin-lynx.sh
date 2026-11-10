#!/bin/bash
# Sync pertama PenguinOS (manifest celerity) + local manifest lynx.
# Dijalankan di /root/penguin di rom-build-max, dalam tmux:
#   tmux new-session -d -s penguin-sync -c /root/penguin \
#     'bash /root/penguin-lynx-build/scripts/sync-penguin-lynx.sh'
# Log: /root/penguin/sync-penguin-lynx-YYYYMMDD-HHMM.log (dibaca watchdog).
# Marker akhir SYNC_DONE / SYNC_FAILED dibaca watchdog buat klasifikasi.
set -u
cd /root/penguin || exit 1
export LC_ALL=C
TS=$(date +%Y%m%d-%H%M)
LOG="/root/penguin/sync-penguin-lynx-${TS}.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== sync start $(date '+%F %T %Z') ==="
if [ ! -d .repo ]; then
  repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs
fi
mkdir -p .repo/local_manifests
cp /root/penguin-lynx-build/lynx.xml .repo/local_manifests/lynx.xml
repo sync --current-branch --no-tags -j4
RC=$?
if [ "$RC" -eq 0 ]; then echo "SYNC_DONE $(date '+%F %T')"; else echo "SYNC_FAILED rc=$RC $(date '+%F %T')"; fi
exit "$RC"
