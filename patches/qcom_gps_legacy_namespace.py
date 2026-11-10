#!/usr/bin/env python3

# penguin-tensor: qcom-gps-legacy-namespace

# vendor/qcom/common/vendor/gps-legacy/Android.bp (AOSPA's QCOM GPS
# stack) declares a soong_namespace that imports only display/qseecomd
# namespaces — but 29 places in the file depend on `libgps.utils`,
# which is defined ONLY as a prebuilt in vendor/google/lynx/Android.bp
# (Google's blobs, owner google). So Soong bootstrap fails (build #10)
# with `"libcdfw_remote_api" depends on undefined module "libgps.utils"`.
#
# The gps-legacy stack is dead code for lynx (nothing in
# device-lynx.mk / gs201 / lynx-vendor.mk / aospa-target.mk references
# it; lynx GPS comes from Google's own GNSS HAL in the vendor blobs),
# but Soong still needs every dependency to resolve. The fix is to
# let the gps-legacy namespace see the vendor blob namespace by
# adding "vendor/google/lynx" to its imports. No import cycle: the
# vendor/google/lynx namespace imports only hardware/google/* and
# hardware/qcom/wlan/wcn6740.
#
# Idempotent: if the import is already present, it does nothing.
# A plain `repo sync` restores the stock file, so re-run
# penguin-setup.sh after syncing.

import pathlib, sys


F = pathlib.Path("vendor/qcom/common/vendor/gps-legacy/Android.bp")

MARK = '"vendor/google/lynx",'

# Perangkap (build #11): file .bp TIDAK mengenal komentar `#` (itu
# sintaks Python) — parser Blueprint menolaknya. Komentar di .bp harus
# `//`. Bila file masih berisi versi `#` yang salah, perbaiki dulu.
BAD = '"vendor/google/lynx",  # penguin-tensor: libgps.utils lives in the Google blobs'
GOOD = '"vendor/google/lynx",  // penguin-tensor: libgps.utils lives in the Google blobs'

OLD = ('    imports: [\n'
       '        "vendor/qcom/common/vendor/display/4.19",\n'
       '        "vendor/qcom/common/vendor/display/5.4",\n'
       '        "vendor/qcom/common/vendor/qseecomd-legacy",\n'
       '        "vendor/qcom/common/vendor/qseecomd",\n'
       '    ],')

NEW = ('    imports: [\n'
       '        "vendor/qcom/common/vendor/display/4.19",\n'
       '        "vendor/qcom/common/vendor/display/5.4",\n'
       '        "vendor/qcom/common/vendor/qseecomd-legacy",\n'
       '        "vendor/qcom/common/vendor/qseecomd",\n'
       '        ' + GOOD + '\n'
       '    ],')


if not F.exists():
    sys.exit(f"ERROR: {F} not found (run from the source root)")

text = F.read_text()

if BAD in text:
    F.write_text(text.replace(BAD, GOOD))
    print(f"fixed bad '#' comment in: {F}")
    sys.exit(0)

if MARK in text:
    print(f"already patched: {F}")
    sys.exit(0)

n = text.count(OLD)

if n != 1:
    sys.exit(f"ERROR: expected 1 match in {F}, found {n}; anchors need updating")

F.write_text(text.replace(OLD, NEW))

print(f"patched: {F}")
