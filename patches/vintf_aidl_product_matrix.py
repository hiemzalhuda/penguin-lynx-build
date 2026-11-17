#!/usr/bin/env python3
"""Langkah 18 (17 Nov 2026): VINTF — dua HAL di product matrix harus AIDL, bukan HIDL.

Akar masalah: build direct-ninja run 1648 gagal 08:05 WIB di otapackage
([32737/32737]) — check_target_files_vintf.py CheckVintfIfTrebleEnabled:
"RuntimeError: VINTF compatibility check failed". Dua instance di device
manifest tidak ada di framework compatibility matrix:
  vendor.lineage.touch.IGloveMode/default (@1)
  vendor.qti.hardware.wifi.supplicant.ISupplicantVendor/default (@1)

Kedua HAL itu dideklarasikan di device manifest sebagai AIDL v1, lewat
fragment manifest:
  hardware/google/pixel/touch/vendor.lineage.touch-service.pixel.xml
    <hal format="aidl"><name>vendor.lineage.touch</name><version>1</version>
    <fqname>IGloveMode/default</fqname></hal>
  external/wpa_supplicant_8/wpa_supplicant/aidl/android.hardware.wifi.supplicant.xml
    <hal format="aidl"><name>vendor.qti.hardware.wifi.supplicant</name>
    <fqname>ISupplicantVendor/default</fqname></hal>

Perbaikan 08:10 WIB (oleh proses lain, bukan monitor ini) menambahkan
kedua HAL ke device/google/lynx/vintf/device_framework_matrix_product.xml
— TAPI sebagai <hal format="hidl"> versi 1.0. Itu TIDAK BISA lolos cek:
libvintf system/libvintf/HalManifest.cpp checkUnusedHals() memanggil
mat.matchInstance(manifestInstance.format(), ...) dan
CompatibilityMatrix::matchInstance() menyaring lewat
forEachInstanceOfVersion(format, ...) — format adalah kriteria match.
Instance manifest AIDL hanya cocok dengan entri matrix AIDL; entri HIDL
tidak pernah cocok. Buktinya: run 0110 yang di-restart 08:10 WIB dengan
perbaikan HIDL itu dihentikan monitor (ninja PID 3041020, [2204/39605])
sebelum membuang ~8 jam rebuild menuju kegagalan VINTF yang sama.

Perbaikan (skrip ini): ubah kedua blok HIDL 1.0 di product matrix lynx
menjadi AIDL v1 — format yang sama dengan fragment manifest. File ini
sudah menjadi input langsung edge assemble_vintf product matrix di ninja
(out/soong/build.aospa_lynx.8.ninja), jadi edit isi file saja cukup
(tidak perlu Soong/ckati ulang): ninja me-regenerate product matrix,
target_files, lalu VINTF check. Diverifikasi dengan assemble_vintf
manual: merge gs201 + lynx product matrix tetap berisi kedua entri
(setelah perbaikan, sebagai AIDL).

Idempotent: bila kedua blok AIDL sudah ada, tidak mengubah apa pun.
Bila file masih pristine (tanpa kedua blok), blok AIDL disisipkan sebelum
</compatibility-matrix>. Backup pristine ada di
device_framework_matrix_product.xml.bak-vintf (dibuat saat edit 08:10).
"""
import sys
from pathlib import Path

MATRIX = Path("device/google/lynx/vintf/device_framework_matrix_product.xml")

HIDL_TOUCH = """    <hal format="hidl">
        <name>vendor.lineage.touch</name>
        <version>1.0</version>
        <interface>
            <name>IGloveMode</name>
            <instance>default</instance>
        </interface>
    </hal>
"""

HIDL_SUPPLICANT = """    <hal format="hidl">
        <name>vendor.qti.hardware.wifi.supplicant</name>
        <version>1.0</version>
        <interface>
            <name>ISupplicantVendor</name>
            <instance>default</instance>
        </interface>
    </hal>
"""

AIDL_TOUCH = """    <hal format="aidl">
        <name>vendor.lineage.touch</name>
        <version>1</version>
        <interface>
            <name>IGloveMode</name>
            <instance>default</instance>
        </interface>
    </hal>
"""

AIDL_SUPPLICANT = """    <hal format="aidl">
        <name>vendor.qti.hardware.wifi.supplicant</name>
        <version>1</version>
        <interface>
            <name>ISupplicantVendor</name>
            <instance>default</instance>
        </interface>
    </hal>
"""


def main():
    if not MATRIX.is_file():
        print(f"ERROR: {MATRIX} tidak ditemukan (jalankan dari root source).")
        return 1
    content = MATRIX.read_text(errors="ignore")
    changed = False

    if AIDL_TOUCH in content and AIDL_SUPPLICANT in content:
        print("vintf_aidl_product_matrix: kedua blok AIDL sudah ada, dilewati.")
        return 0

    if HIDL_TOUCH in content:
        content = content.replace(HIDL_TOUCH, AIDL_TOUCH, 1)
        changed = True
        print("vintf_aidl_product_matrix: vendor.lineage.touch HIDL 1.0 -> AIDL 1.")
    elif AIDL_TOUCH not in content:
        anchor = "</compatibility-matrix>"
        if anchor not in content:
            print("ERROR: penutup </compatibility-matrix> tidak ditemukan.")
            return 1
        content = content.replace(anchor, AIDL_TOUCH + anchor, 1)
        changed = True
        print("vintf_aidl_product_matrix: blok AIDL vendor.lineage.touch disisipkan.")

    if HIDL_SUPPLICANT in content:
        content = content.replace(HIDL_SUPPLICANT, AIDL_SUPPLICANT, 1)
        changed = True
        print("vintf_aidl_product_matrix: vendor.qti.hardware.wifi.supplicant HIDL 1.0 -> AIDL 1.")
    elif AIDL_SUPPLICANT not in content:
        anchor = "</compatibility-matrix>"
        if anchor not in content:
            print("ERROR: penutup </compatibility-matrix> tidak ditemukan.")
            return 1
        content = content.replace(anchor, AIDL_SUPPLICANT + anchor, 1)
        changed = True
        print("vintf_aidl_product_matrix: blok AIDL vendor.qti.hardware.wifi.supplicant disisipkan.")

    if changed:
        MATRIX.write_text(content)
        print("vintf_aidl_product_matrix: device_framework_matrix_product.xml diperbarui.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
