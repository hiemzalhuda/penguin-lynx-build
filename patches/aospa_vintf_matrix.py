#!/usr/bin/env python3
"""Langkah 6 penguin-setup.sh (build #17): definisikan matriks
kompatibilitas framework AOSPA sebagai modul vintf_compatibility_matrix
dengan system_ext_specific: true.

Latar: vendor/aospa/target/product/aospa-target.mk menaruh
aospa_vendor_framework_compatibility_matrix.xml ke partisi system lewat
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE — dilarang oleh artifact
path requirement generic_system.mk (diwarisi gs201/aosp_common.mk), dan
TIDAK ada allowlist untuk FCM. Per pesan errornya, matriks harus jadi
modul vintf_compatibility_matrix di Android.bp (system_ext_specific:
true) + masuk PRODUCT_PACKAGES, sementara entri lamanya dibuang dari
variabel (dilakukan di aospa_lynx.mk). Isi matriks tetap sama — hanya
pindah dari system ke system_ext.

Idempotent: bila modul sudah ada di Android.bp, tidak diubah.
"""
import pathlib
import sys

F = pathlib.Path("vendor/aospa/target/config/Android.bp")
MARK = "aospa_vendor_framework_compatibility_matrix"

CONTENT = """// Dibuat penguin-setup.sh langkah 6 (build #17): matriks kompatibilitas
// framework AOSPA sebagai modul, supaya pindah dari partisi system
// (dilarang generic_system.mk) ke system_ext.
vintf_compatibility_matrix {
    name: "aospa_vendor_framework_compatibility_matrix",
    srcs: ["aospa_vendor_framework_compatibility_matrix.xml"],
    system_ext_specific: true,
}
"""


def main() -> int:
    if not F.parent.exists():
        print(f"ERROR: {F.parent} not found (run from the source root)", file=sys.stderr)
        return 1
    if F.exists() and MARK in F.read_text():
        print(f"already present: {F}")
        return 0
    with F.open("a") as f:
        f.write(CONTENT)
    print(f"added vintf_compatibility_matrix module to: {F}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
