#!/usr/bin/env python3
"""Tambah guard TARGET_NO_KERNEL ke vendor/qcom/build/tasks/kernel_definitions.mk.

Kenapa (build #20, 11 Nov 2026):
  Langkah 8 (touch vendor/qcom/build/.find-ignore) TIDAK mempan buat file
  ini. .find-ignore hanya memangkas pemindaian file Blueprint (Android.bp)
  oleh Soong; file build/tasks/*.mk dikumpulkan Kati lewat jalur lain
  (configuration.list / subdir_makefiles) yang TIDAK menghormati
  .find-ignore — buktinya vendor/qcom/build/tasks/vendor_prop_context_restriction.mk
  tetap di-include Kati di #20, dan kernel_definitions.mk ikut dievaluasi
  (warning baris 142 & 253 di log) lalu gagal di baris 354 (dtb.img ganda).
  Guard di level FILE adalah satu-satunya perbaikan yang tahan terhadap
  jalur koleksi mana pun.

Apa yang dilakukan:
  File ini seluruhnya dibungkus `ifeq ($(TARGET_PREBUILT_KERNEL),)` (baris 1
  s.d. endif terakhir). Patch ini menambahkan `ifneq ($(TARGET_NO_KERNEL),true)`
  tepat setelah baris 1 dan `endif` pasangannya tepat sebelum endif terakhir.
  Buat lynx TARGET_NO_KERNEL=true (device/google/gs201/BoardConfig-common.mk:56)
  sehingga seluruh isi file dilewati — tidak ada lagi aturan dtb.img dari
  file ini. Buat perangkat QCOM (TARGET_NO_KERNEL kosong/false) perilaku
  tidak berubah sama sekali.

Idempotent: bila TARGET_NO_KERNEL sudah ada di file, tidak melakukan apa-apa.
Jalankan dari source root (argumen: path tree, default ".").
"""
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
F = ROOT / "vendor/qcom/build/tasks/kernel_definitions.mk"

text = F.read_text()
if "TARGET_NO_KERNEL" in text:
    print("guard sudah ada, lewati")
    sys.exit(0)

lines = text.splitlines(keepends=True)
assert lines[0].rstrip() == "ifeq ($(TARGET_PREBUILT_KERNEL),)", (
    "baris 1 bukan guard TARGET_PREBUILT_KERNEL yang diharapkan: "
    + repr(lines[0])
)
# endif terakhir file menutup guard baris 1.
assert lines[-1].strip() == "endif", (
    "baris terakhir bukan endif penutup: " + repr(lines[-1])
)
lines.insert(1, "ifneq ($(TARGET_NO_KERNEL),true)\n")
lines.insert(len(lines) - 1, "endif # TARGET_NO_KERNEL\n")
F.write_text("".join(lines))
print("guard TARGET_NO_KERNEL dipasang di vendor/qcom/build/tasks/kernel_definitions.mk")
