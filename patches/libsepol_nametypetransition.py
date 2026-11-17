#!/usr/bin/env python3
"""Hapus blok penolakan CIL_NAMETYPETRANSITION/CIL_TYPE_RULE di
__extract_attributees_helper (external/selinux/libsepol/cil/src/android.c).

Akar masalah (15 Nov 2026, build gagal 17:36 WIB di plat_pub_versioned.cil):
AOSPA punya blok extra yang menolak typetransition di fase extract-attributees
(libsepol) sehingga version_policy gagal "typetransition unsupported statement
in attributee policy (line 6024)" — baris itu adalah
(typetransition ssr_detector_app tmpfs file appdomain_tmpfs) dari ekspansi macro
app_domain(ssr_detector_app) di public policy. Lineage TIDAK punya blok ini:
di sana CIL_NAMETYPETRANSITION/CIL_TYPE_RULE jatuh ke default (di-skip) dan
ditangani belakangan oleh cil_attrib_nametypetransition — makanya Infinity-X
berhasil build dengan input yang sama persis (pub_policy.cil sama-sama berisi
4 typetransition). Menghapus blok ini menyamakan AOSPA dengan Lineage.

Idempotent: bila blok sudah tidak ada, tidak mengubah apa pun.
"""
from pathlib import Path

P = Path("external/selinux/libsepol/cil/src/android.c")

BLOCK = (
    "\tcase CIL_NAMETYPETRANSITION:\n"
    "\tcase CIL_TYPE_RULE:\n"
    "\t\tcil_log(CIL_ERR, \"%s unsupported statement in attributee policy (line %d)\\n\",\n"
    "\t\t\tCIL_KEY_TYPETRANSITION, node->line);\n"
    "\t\tgoto exit;\n"
    "\t\tbreak;\n"
)

def main():
    if not P.is_file():
        print(f"ERROR: {P} tidak ditemukan (jalankan dari root source).")
        return 1
    content = P.read_text(errors="ignore")
    if BLOCK not in content:
        print("libsepol_nametypetransition: blok sudah tidak ada, dilewati.")
        return 0
    P.write_text(content.replace(BLOCK, "", 1))
    print("libsepol_nametypetransition: blok penolakan typetransition dihapus dari android.c.")
    return 0

if __name__ == "__main__":
    import sys
    sys.exit(main())
