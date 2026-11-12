#!/usr/bin/env python3

# penguin-tensor: soong-rust-prebuilt-binary-symbols
#
# Build #22 gagal 12 Nov 2026 09:37 WIB di ninja (90 detik setelah
# start, sebelum kompilasi apa pun):
#   "out/target/product/lynx/symbols/vendor/bin/dump/dump_modem",
#   needed by ".../dump_modem_intermediates/dump_modem", missing
# dump_modem + gpuflag adalah dua modul `rust_prebuilt_binary` di
# vendor/google/lynx/Android.bp (TheMuppets, lineage-24.0). Langkah 3
# (soong_rust_prebuilt_binary.py) sudah mendaftarkan tipe modulnya
# dengan menyalin prebuilt.go dari Lineage — tapi graft itu TIDAK
# lengkap: build/soong/rust/rust.go AOSPA tidak punya penanganan
# *prebuiltBinaryDecorator di dua tempat yang dimiliki Lineage:
#
# 1. IsPrebuilt() — Lineage memeriksa *prebuiltLibraryDecorator DAN
#    *prebuiltBinaryDecorator; AOSPA hanya library. Akibatnya modul
#    rust_prebuilt_binary tidak dianggap prebuilt.
# 2. getSymbolInfo() — Lineage punya
#      case *prebuiltBinaryDecorator:
#          mod.getSymbolInfo(ctx, tt.baseCompiler, info)
#    AOSPA tidak punya. Tanpa case ini, SymbolInfo modul tidak
#    mendapat UnstrippedBinaryPath → getSymbolicOutputInfos() di
#    cc/cc.go mengembalikan nil → TIDAK ADA rule yang menyalin
#    prebuilt ke out/.../symbols/... — padahal rule install Kati
#    (target Prebuilt) memakai file symbols itu sebagai order-only dep.
#    Ninja gagal di validasi graph.
#
# Bukti perbandingan (tree Infinity-X 4.2 yang jalan vs Penguin):
# - Lineage rust.go: case *prebuiltBinaryDecorator di getSymbolInfo
#   + cek di IsPrebuilt(); AOSPA: keduanya tidak ada.
# - Rule symbols ADA di soong ninja Infinity-X
#   (build.infinity_lynx.0.ninja: CpNoPreserveSymlink, tag
#   module_type=rust_prebuilt_binary) dan TIDAK ADA di ninja Penguin.
# - Modul cc_prebuilt_binary dgn strip:none yang sama (gs_watchdogd,
#   dump_modemlog) PUNYA rule symbols di ninja Penguin — jadi ini
#   spesifik rust_prebuilt_binary, BUKAN masalah strip:none umum
#   (semua 283 prebuilt di vendor/google/lynx/Android.bp pakai
#   strip:none, dan 281 modul cc-nya baik-baik saja).
#
# Skrip ini menambahkan dua potongan yang hilang, mengikuti kode
# Lineage persis. Idempotent; bila sudah ada, tidak mengubah apa pun.
# `repo sync` mengembalikan file stock, jadi jalankan ulang
# penguin-setup.sh setelah sync.

import pathlib
import sys


TARGET = pathlib.Path("build/soong/rust/rust.go")

OLD_ISPREBUILT = (
    "func (mod *Module) IsPrebuilt() bool {\n"
    "\tif _, ok := mod.compiler.(*prebuiltLibraryDecorator); ok {\n"
    "\t\treturn true\n"
    "\t}\n"
    "\treturn false\n"
    "}\n"
)
NEW_ISPREBUILT = (
    "func (mod *Module) IsPrebuilt() bool {\n"
    "\tif _, ok := mod.compiler.(*prebuiltLibraryDecorator); ok {\n"
    "\t\treturn true\n"
    "\t}\n"
    "\tif _, ok := mod.compiler.(*prebuiltBinaryDecorator); ok {\n"
    "\t\treturn true\n"
    "\t}\n"
    "\treturn false\n"
    "}\n"
)

OLD_SYMBOLINFO = (
    "\tcase *prebuiltLibraryDecorator:\n"
    "\t\tmod.getSymbolInfo(ctx, tt.baseCompiler, info)\n"
    "\tcase *toolchainLibraryDecorator:\n"
)
NEW_SYMBOLINFO = (
    "\tcase *prebuiltLibraryDecorator:\n"
    "\t\tmod.getSymbolInfo(ctx, tt.baseCompiler, info)\n"
    "\tcase *prebuiltBinaryDecorator:\n"
    "\t\tmod.getSymbolInfo(ctx, tt.baseCompiler, info)\n"
    "\tcase *toolchainLibraryDecorator:\n"
)


if not TARGET.exists():
    sys.exit(f"ERROR: {TARGET} not found (run from the source root)")

text = TARGET.read_text()

if NEW_ISPREBUILT in text and NEW_SYMBOLINFO in text:
    print(f"already patched: {TARGET}")
    sys.exit(0)

if OLD_ISPREBUILT not in text:
    sys.exit(
        f"ERROR: IsPrebuilt anchor not found in {TARGET}; "
        "file changed upstream, anchors need updating"
    )
if text.count(OLD_SYMBOLINFO) != 1:
    sys.exit(
        f"ERROR: getSymbolInfo anchor found {text.count(OLD_SYMBOLINFO)} "
        f"times in {TARGET} (expected exactly 1); anchors need updating"
    )

text = text.replace(OLD_ISPREBUILT, NEW_ISPREBUILT)
text = text.replace(OLD_SYMBOLINFO, NEW_SYMBOLINFO)

TARGET.write_text(text)

after = TARGET.read_text()
if NEW_ISPREBUILT not in after or NEW_SYMBOLINFO not in after:
    sys.exit(f"ERROR: patch did not apply cleanly to {TARGET}")

print(f"patched: {TARGET} (prebuiltBinaryDecorator: IsPrebuilt + getSymbolInfo)")
