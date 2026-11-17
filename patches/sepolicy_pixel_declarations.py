#!/usr/bin/env python3
"""Langkah 13 (15 Nov 2026): deklarasi sepolicy Pixel yang hilang di tree AOSPA.

Akar masalah: repo hardware/google/pixel-sepolicy (142 file .te) TIDAK ADA di
tree AOSPA (manifest tidak sync repo ini), padahal BoardConfig-common.mk:266-268
merujuk subdirnya (googlebattery/input/powerstats). Akibatnya checkpolicy AOSPA
(yang strict; Lineage mentolerir) gagal beruntun saat membangun
recovery_sepolicy.cil:
  1. macro pixel_bugreport tidak didefinisikan (dipakai 23 file dump_*.te)
  2. type domain dump_* tidak dideklarasikan (macro harus mendeklarasikannya)
  3. atribut touch_property_type tidak dideklarasikan (dipakai lynx property.te)
  4. atribut pixel_battery_domain/service_type tidak dideklarasikan
  5. ~24 type (sysfs_*, hal_wifi_ext, pixelstats_vendor, vendor_sysfs_*, dll)
     tidak dideklarasikan (harusnya dari pixel-sepolicy + QCOM sepolicy_vndr)
  6. type debugfs_mgm & sysfs_soc (genfscon) tidak dideklarasikan

Perbaikan: tambahkan semua deklarasi itu ke
device/google/gs201/sepolicy/vendor/domain.te — file yang SUDAH ada di manifest
ninja (diproses tepat sebelum dump_aoc.te di .conf), sehingga direct-ninja
mengambil perubahan tanpa Soong ulang. File .te BARU tidak bisa dipakai karena
tidak ada di manifest ninja yang sudah digenerate.

Definisi macro pixel_bugreport direkonstruksi dari ekspansi yang teramati di
recovery_sepolicy.cil build Infinity-X 4.2 (yang berhasil). Deklarasi type
disalin verbatim dari repo upstream (LineageOS
android_hardware_google_pixel-sepolicy) + QCOM sepolicy_vndr di tree.

Idempotent: bila marker sudah ada, tidak mengubah apa pun.
"""
import sys
from pathlib import Path

DOMAIN_TE = Path("device/google/gs201/sepolicy/vendor/domain.te")
MARKER = "define(`pixel_bugreport'"

BLOCK = '''# pixel_bugreport(domain) — macro Pixel untuk domain dumpstate/bugreport.
# DITAMBAHKAN PORTER (15 Nov 2026): macro ini dipakai 23 file dump_*.te
# di vendor/ tapi tidak didefinisikan di tree manapun (AOSPA/Lineage/stock
# gs201-sepolicy). Definisi di bawah direkonstruksi dari ekspansi yang
# teramati di recovery_sepolicy.cil build Infinity-X 4.2 (yang berhasil):
# domain masuk ke atribut hal_dumpstate + izin interaksi dumpstate.
# Tanpa ini, checkpolicy gagal "syntax error at token pixel_bugreport"
# saat membangun recovery_sepolicy.cil.
define(`pixel_bugreport', `
type $1, domain;
type $1_exec, exec_type, file_type, vendor_file_type;
typeattribute $1 hal_dumpstate;
allow $1 $1_exec:file { read getattr map execute open entrypoint };
allow $1 dumpstate:fd use;
allow $1 dumpstate:fifo_file { write getattr };
allow $1 hal_dumpstate_default:fd use;
allow $1 hal_dumpstate_default:process sigchld;
allow $1 shell_data_file:file { write getattr };
')

# touch_property_type — atribut properti touchscreen Pixel.
# DITAMBAHKAN PORTER (15 Nov 2026): dipakai device/google/lynx/sepolicy/
# vendor/property.te tapi tidak dideklarasikan di tree manapun;
# checkpolicy AOSPA (strict) menolaknya, Lineage mentolerir.
attribute touch_property_type;

# Atribut dari hardware/google/pixel-sepolicy/common/vendor/attributes
attribute pixel_battery_domain;
attribute pixel_battery_service_type;
# ---- Deklarasi type dari hardware/google/pixel-sepolicy (repo hilang) ----
# DITAMBAHKAN PORTER (15 Nov 2026): hardware/google/pixel-sepolicy (142 file .te)
# TIDAK ADA di tree AOSPA (manifest tidak sync repo ini) padahal BoardConfig
# merujuk subdirnya (googlebattery/input/powerstats). Type-type di bawah
# dipakai file gs201/aospa sepolicy tapi tidak dideklarasikan di mana pun,
# sehingga checkpolicy AOSPA (strict) gagal. Deklarasi disalin verbatim dari
# repo upstream (LineageOS android_hardware_google_pixel-sepolicy) + QCOM
# sepolicy_vndr yang ada di tree.
type battery_history_device, dev_type;
type hal_googlebattery, domain, pixel_battery_domain;
type hal_power_stats_vendor_service, vndservice_manager_type;
type hal_wifi_ext, domain;
type hal_wifi_ext_hwservice, hwservice_manager_type;
type hal_wifi_ext_service, service_manager_type, hal_service_type;
type persist_file, file_type, vendor_persist_type;
type pixelstats_vendor, domain;
type pixelstats_vendor_exec, exec_type, vendor_file_type, file_type;
type proc_irq, fs_type, proc_type;
type rebalance_interrupts_vendor, domain;
type sysfs_chip_id, sysfs_type, fs_type;
type sysfs_display, sysfs_type, fs_type;
type sysfs_iio_devices, fs_type, sysfs_type;
type sysfs_irq, fs_type, sysfs_type;
type sysfs_pixel_stat, fs_type, sysfs_type;
type sysfs_pixelstats, fs_type, sysfs_type;
type sysfs_power_stats, fs_type, sysfs_type;
type sysfs_scsi_devices_0000, sysfs_type, fs_type;
type sysfs_vendor_mm, fs_type, sysfs_type;
type vendor_sysfs_battery_supply, sysfs_type, fs_type;
type vendor_sysfs_usb_supply, sysfs_type, fs_type;


# ---- Deklarasi type tambahan dari pixel-sepolicy (lanjutan) ----
type debugfs_mgm, debugfs_type, fs_type;

# ---- Deklarasi type tambahan (genfscon/dll, lanjutan) ----
type sysfs_soc, sysfs_type, fs_type;
'''

def main():
    if not DOMAIN_TE.is_file():
        print(f"ERROR: {DOMAIN_TE} tidak ditemukan (jalankan dari root source).")
        return 1
    content = DOMAIN_TE.read_text(errors="ignore")
    if MARKER in content:
        print("sepolicy_pixel_declarations: sudah diterapkan, dilewati.")
        return 0
    if not content.endswith("\n"):
        content += "\n"
    DOMAIN_TE.write_text(content + BLOCK)
    print("sepolicy_pixel_declarations: deklarasi Pixel ditambahkan ke domain.te.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
