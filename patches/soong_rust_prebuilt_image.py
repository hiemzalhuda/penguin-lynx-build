#!/usr/bin/env python3

# penguin-tensor: soong-rust-prebuilt-image

# vendor/google/lynx/Android.bp declares `libgpuflag_aconfig_rust` as a
# `rust_prebuilt_dylib` with soc_specific: true (a vendor image module).
# AOSP's Soong (build/soong/rust/image.go) refuses that in
# ImageMutatorBegin: "Rust prebuilt modules not supported for
# non-system images." — so Soong bootstrap fails (build #5).
#
# LineageOS's Soong simply deletes that check (their image.go is 8
# lines shorter, the only difference). The module builds and installs
# fine there — the Infinity-X 4.2 lynx build carries the identical
# module definition and boots.
#
# This script replaces build/soong/rust/image.go with the reference
# copy in patches/soong_rust_image.go (byte-identical to the file in
# the working Infinity-X 4.2 tree, Apache-2.0 AOSP/Lineage code).
# Idempotent: if the error string is already gone, it does nothing.
# A plain `repo sync` restores the stock file, so re-run
# penguin-setup.sh after syncing.

import pathlib, shutil, sys


TARGET = pathlib.Path("build/soong/rust/image.go")
REF = pathlib.Path("patches/soong_rust_image.go")

ERR = "Rust prebuilt modules not supported for non-system images."
ANCHOR = "func (mod *Module) ImageMutatorBegin"


if not TARGET.exists():
    sys.exit(f"ERROR: {TARGET} not found (run from the source root)")
if not REF.exists():
    sys.exit(f"ERROR: {REF} not found (patches/ not copied to the tree?)")

text = TARGET.read_text()

if ERR not in text:
    print(f"already patched: {TARGET}")
    sys.exit(0)

if ANCHOR not in text:
    sys.exit(f"ERROR: anchor not found in {TARGET}; file changed upstream, anchors need updating")

ref_text = REF.read_text()
if ERR in ref_text:
    sys.exit(f"ERROR: reference {REF} still contains the error string")
if ANCHOR not in ref_text:
    sys.exit(f"ERROR: reference {REF} is missing {ANCHOR}")

shutil.copyfile(REF, TARGET)

after = TARGET.read_text()
if ERR in after:
    sys.exit(f"ERROR: copy failed, error string still present in {TARGET}")

print(f"patched: {TARGET} (rust prebuilt vendor-image check removed)")
