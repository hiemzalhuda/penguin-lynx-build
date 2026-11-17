#!/usr/bin/env python3
"""Langkah 17 (16 Nov 2026): definisi add-radio-file-sha1-checked yang hilang.

Akar masalah: build direct-ninja run 0715 gagal 23:18 WIB di
aospa_lynx-target_files.zip.list (target_files packaging, [32329/32329]):
add_img_to_target_files.py CheckAbOtaImages — "AssertionError: Failed to
find abl.img". Penyebab: AB_OTA_PARTITIONS (gs201 BoardConfig-common.mk)
memuat abl (dan 8 image radio lain), tapi TIDAK SATU PUN image radio
tersalin ke out/target/product/lynx/ — tidak ada edge
"out/target/product/lynx/abl.img" di manifest ninja.

Rantai sebabnya: vendor/google/lynx/Android.mk (identik dengan Lineage)
memanggil $(call add-radio-file-sha1-checked,radio/abl.img,<sha1>) untuk
9 image (abl/bl1/bl2/bl31/gsa/ldfw/modem/pbl/tzsw — daftar di
device/google/lynx/lynx/proprietary-firmware.txt, file-file ada di
vendor/google/lynx/radio/, kesembilan sha1 TERVERIFIKASI cocok). Tapi
fungsi itu TIDAK DIDEFINISIKAN di mana pun di tree AOSPA — bukan di
build/make/core/definitions.mk (hanya ada add-radio-file dan
add-radio-file-checked), bukan di vendor/aospa (build/core/ hanya berisi
mkdir.mk), bukan di device/google, bukan di hardware/google. Di tree
Lineage/Infinity-X fungsi ini didefinisikan di
vendor/infinity/build/core/utils.mk:235-241 (di-include oleh
vendor/infinity/build/core/definitions.mk:9). Kati tidak error untuk
$(call) ke fungsi tak terdefinisi — hasilnya kosong diam-diam — jadi
tidak ada edge radio, INSTALLED_RADIOIMAGE_TARGET kosong, recipe
target_files tidak menyalin apa pun ke RADIO/, dan CheckAbOtaImages
gagal di akhir.

Perbaikan: tambahkan definisi itu (verbatim dari Lineage/Infinity-X)
ke build/make/core/definitions.mk, tepat setelah
add-radio-file-checked-internal — tempat yang sama dengan fungsi
saudaranya. Setelah ini manifest ninja HARUS digenerate ulang dengan
ckati langsung (bukan rom-build.sh/mka, bukan Soong) agar edge radio
muncul; baru restart direct-ninja.

Idempotent: bila definisi sudah ada, tidak mengubah apa pun.
"""
import sys
from pathlib import Path

DEFS_MK = Path("build/make/core/definitions.mk")

FUNC = """# $(call add-radio-file-sha1-checked,path,sha1)
define add-radio-file-sha1-checked
  $(eval path := $(LOCAL_PATH)/$(1))
  $(eval sha1 := $(shell sha1sum "$(path)" | cut -d" " -f 1))
  $(if $(filter $(sha1),$(2)),
    $(call add-radio-file,$(1)),
    $(error $(path) SHA1 mismatch ($(sha1) != $(2))))
endef
"""

ANCHOR = """define add-radio-file-checked-internal
INSTALLED_RADIOIMAGE_TARGET += $$(PRODUCT_OUT)/$(2)
BOARD_INFO_CHECK += $(3):$(LOCAL_PATH)/$(1)
$$(PRODUCT_OUT)/$(2) : $$(LOCAL_PATH)/$(1)
\t$$(transform-prebuilt-to-target)
endef
"""


def main():
    if not DEFS_MK.is_file():
        print(f"ERROR: {DEFS_MK} tidak ditemukan (jalankan dari root source).")
        return 1
    content = DEFS_MK.read_text(errors="ignore")
    if "define add-radio-file-sha1-checked" in content:
        print("add_radio_file_sha1_checked: sudah diterapkan, dilewati.")
        return 0
    if ANCHOR not in content:
        print("ERROR: anchor add-radio-file-checked-internal tidak ditemukan; "
              "definitions.mk berubah dari yang diharapkan.")
        return 1
    content = content.replace(ANCHOR, ANCHOR + "\n" + FUNC, 1)
    DEFS_MK.write_text(content)
    print("add_radio_file_sha1_checked: definisi ditambahkan ke "
          "build/make/core/definitions.mk.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
