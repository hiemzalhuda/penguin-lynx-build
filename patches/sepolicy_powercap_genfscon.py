#!/usr/bin/env python3
"""Langkah 15 (15 Nov 2026): hapus genfscon powercap yang bentrok di plat compat.

Akar masalah: build gagal di precompiled_sepolicy (secilc) — "Problems
processing genfscon rules" / "Failed to compile cildb: -1".
Penyebabnya DUA genfscon untuk path yang SAMA dengan type BERBEDA:
  - plat (system/sepolicy/compat/plat_sepolicy_genfs_202604.cil):
      /class/powercap            -> sysfs_powercap
      /devices/virtual/powercap  -> sysfs_powercap
  - vendor (device/google/gs201/sepolicy/vendor/genfs_contexts:29,384):
      /class/powercap            -> sysfs_thermal
      /devices/virtual/powercap  -> sysfs_thermal
secilc (__cil_post_process_context_rules di libsepol cil_post.c) menolak
dua rule genfscon untuk (filesystem, path) yang sama bila context-nya
berbeda.

Di tree Lineage (Infinity-X, yang berhasil build), file plat compat ini
TIDAK punya kedua rule powercap itu (baris 3-nya /class/typec ->
sysfs_typec), jadi hanya rule vendor (sysfs_thermal) yang berlaku.
File genfs_contexts gs201 byte-identik antara AOSPA dan Lineage, jadi
perbedaannya murni di file plat compat AOSPA ini.

Perbaikan: hapus kedua baris powercap dari file plat compat AOSPA, agar
hanya rule vendor (sysfs_thermal) yang tersisa — sama persis dengan
Lineage. Type sysfs_powercap tetap dideklarasikan di public/private
file.te (tidak dihapus), jadi tidak ada referensi yang rusak; rule
allow untuk sysfs_powercap yang ada di plat sekadar jadi tidak terpakai.

Idempotent: bila kedua baris sudah tidak ada, tidak mengubah apa pun.
"""
import sys
from pathlib import Path

COMPAT = Path("system/sepolicy/compat/plat_sepolicy_genfs_202604.cil")
MARKER = 'sysfs_powercap'

def main():
    if not COMPAT.is_file():
        print(f"ERROR: {COMPAT} tidak ditemukan (jalankan dari root source).")
        return 1
    lines = COMPAT.read_text(errors="ignore").splitlines(keepends=True)
    kept = [l for l in lines if not ("genfscon" in l and "powercap" in l and MARKER in l)]
    removed = len(lines) - len(kept)
    if removed == 0:
        print("sepolicy_powercap_genfscon: rule powercap sudah tidak ada, dilewati.")
        return 0
    COMPAT.write_text("".join(kept))
    print(f"sepolicy_powercap_genfscon: {removed} baris genfscon powercap dihapus dari {COMPAT}.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
