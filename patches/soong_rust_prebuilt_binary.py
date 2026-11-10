#!/usr/bin/env python3

# penguin-tensor: soong-rust-prebuilt-binary

# The vendor blobs (TheMuppets, lineage-24.0) declare two modules in
# vendor/google/lynx/Android.bp as `rust_prebuilt_binary` (dump_modem,
# gpuflag). AOSPA's Soong (build/soong/rust/prebuilt.go, 259 lines, the
# android-17.0.0_r1 version) has no such module type, so Soong bootstrap
# fails with `unrecognized module type "rust_prebuilt_binary"`.
#
# LineageOS's Soong has it (build/soong/rust/prebuilt.go, 362 lines):
# the RegisterModuleType("rust_prebuilt_binary", PrebuiltBinaryFactory)
# line plus the prebuiltBinaryDecorator type and its factory/helpers.
# All symbols the added code references (NewRustBinary, setNoStdlibs,
# addSrcSupplier, getStem, srcPathFromModuleSrcs, prebuiltPath) already
# exist in the PenguinOS rust package, so the Lineage file drops in.
#
# This script replaces build/soong/rust/prebuilt.go with the reference
# copy in patches/soong_rust_prebuilt.go (byte-identical to the file in
# the working Infinity-X 4.2 tree, itself Apache-2.0 AOSP/Lineage code).
# Idempotent: if rust_prebuilt_binary is already registered, it does
# nothing. A plain `repo sync` restores the stock file, so re-run
# penguin-setup.sh after syncing.

import pathlib, shutil, sys


TARGET = pathlib.Path("build/soong/rust/prebuilt.go")
REF = pathlib.Path("patches/soong_rust_prebuilt.go")

MARK = 'RegisterModuleType("rust_prebuilt_binary", PrebuiltBinaryFactory)'
ANCHOR = 'RegisterModuleType("rust_prebuilt_library", PrebuiltLibraryFactory)'


if not TARGET.exists():
    sys.exit(f"ERROR: {TARGET} not found (run from the source root)")
if not REF.exists():
    sys.exit(f"ERROR: {REF} not found (patches/ not copied to the tree?)")

text = TARGET.read_text()

if MARK in text:
    print(f"already patched: {TARGET}")
    sys.exit(0)

if ANCHOR not in text:
    sys.exit(f"ERROR: anchor not found in {TARGET}; file changed upstream, anchors need updating")

ref_text = REF.read_text()
if MARK not in ref_text:
    sys.exit(f"ERROR: reference {REF} does not contain the registration line")

shutil.copyfile(REF, TARGET)

after = TARGET.read_text()
if MARK not in after:
    sys.exit(f"ERROR: copy failed, {MARK} still missing from {TARGET}")

print(f"patched: {TARGET} (rust_prebuilt_binary registered)")
