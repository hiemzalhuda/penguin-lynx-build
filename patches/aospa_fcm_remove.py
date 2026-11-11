#!/usr/bin/env python3
"""Langkah 7 penguin-setup.sh (build #18): hapus entri FCM AOSPA dari
vendor/aospa/target/product/aospa-target.mk.

Latar: aospa-target.mk menaruh
aospa_vendor_framework_compatibility_matrix.xml ke partisi system lewat
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE — dilarang oleh artifact
path requirement generic_system.mk, dan TIDAK ada allowlist untuk FCM.
Percobaan pertama (build #17) membuang entri itu lewat `filter-out`
di aospa_lynx.mk GAGAL: nilai akhir di soong.aospa_lynx.variables
tetap berisi file itu — variabel ini digabung dari SEMUA file produk
dalam rantai inherit, jadi `:=` di file produk teratas tidak menghapus
entri dari file yang di-inherit. Satu-satunya cara yang bekerja adalah
menghapus entrinya di sumbernya (file ini).

Aman: matriksnya tetap disediakan sebagai modul
vintf_compatibility_matrix (system_ext_specific: true) oleh langkah 6
+ PRODUCT_PACKAGES di aospa_lynx.mk — isinya sama, hanya pindah
partisi.

Idempotent: bila entri sudah tidak ada, tidak diubah.
"""
import pathlib
import sys

F = pathlib.Path("vendor/aospa/target/product/aospa-target.mk")

OLD = """DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \\
     vendor/aospa/target/config/aospa_vendor_framework_compatibility_matrix.xml"""

NEW = """# penguin-tensor: entri FCM AOSPA dihapus (build #18) — file ini
# dilarang generic_system.mk di partisi system; matriksnya disediakan
# sebagai modul vintf_compatibility_matrix (system_ext) oleh langkah 6."""

MARK = "aospa_vendor_framework_compatibility_matrix.xml"


def main() -> int:
    if not F.exists():
        print(f"ERROR: {F} not found (run from the source root)", file=sys.stderr)
        return 1
    text = F.read_text()
    if OLD not in text:
        if MARK in text:
            print(f"WARNING: {F} still mentions the FCM file but in an unexpected form", file=sys.stderr)
            return 1
        print(f"already patched: {F}")
        return 0
    F.write_text(text.replace(OLD, NEW, 1))
    print(f"removed AOSPA FCM entry from: {F}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
