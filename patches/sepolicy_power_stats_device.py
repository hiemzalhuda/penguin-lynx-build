#!/usr/bin/env python3
"""Langkah 16 (15 Nov 2026): deklarasi power_stats_device yang hilang.

Akar masalah: build gagal di file_contexts.device.sorted.tmp (checkfc) —
"libsepol.context_from_record: type power_stats_device is not defined",
"line 378 has invalid context u:object_r:power_stats_device:s0".
Sumbernya device/google/gs201/sepolicy/vendor/file_contexts:84:
  /dev/bbd_pwrstat u:object_r:power_stats_device:s0
Type itu dideklarasikan di hardware/google/pixel-sepolicy (yang TIDAK ADA
di tree AOSPA): powerstats/device.te:1 — "type power_stats_device,
dev_type;". Seperti langkah 13, deklarasikan di
device/google/gs201/sepolicy/vendor/domain.te (sudah ada di manifest
ninja). Scan menyeluruh 298 type unik di file_contexts.device.tmp vs
2962 type di policy membuktikan power_stats_device adalah SATU-SATUNYA
type yang hilang — tidak ada whack-a-mole lanjutan di langkah ini.

Idempotent: bila deklarasi sudah ada, tidak mengubah apa pun.
"""
import sys
from pathlib import Path

DOMAIN_TE = Path("device/google/gs201/sepolicy/vendor/domain.te")
DECL = "type power_stats_device, dev_type;"

def main():
    if not DOMAIN_TE.is_file():
        print(f"ERROR: {DOMAIN_TE} tidak ditemukan (jalankan dari root source).")
        return 1
    content = DOMAIN_TE.read_text(errors="ignore")
    if DECL in content:
        print("sepolicy_power_stats_device: sudah diterapkan, dilewati.")
        return 0
    if not content.endswith("\n"):
        content += "\n"
    DOMAIN_TE.write_text(
        content
        + "\n# ---- Deklarasi type tambahan (file_contexts, lanjutan) ----\n"
        + "# power_stats_device — dipakai gs201 file_contexts:84\n"
        + "# (/dev/bbd_pwrstat); deklarasi dari pixel-sepolicy\n"
        + "# powerstats/device.te (repo hilang di tree AOSPA).\n"
        + DECL
        + "\n"
    )
    print("sepolicy_power_stats_device: deklarasi power_stats_device ditambahkan ke domain.te.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
