#!/usr/bin/env python3

# penguin-tensor: qti-a2dp-offload

# CLO's Bluetooth stack falls back to Qualcomm-only A2DP offload HCI commands
# when the controller lacks offload v2. Pixel's Broadcom controller rejects
# them (status 12), so A2DP offload never starts and there is no audio.

# Always use the AOSP offload start/stop path instead (same as LineageOS).

import pathlib, sys


F = pathlib.Path("packages/modules/Bluetooth/system/bta/av/bta_av_aact.cc")

MARK = "penguin-tensor: qti-a2dp-offload"

OLD = ("  if (!check_controller_support_offload_v2() ||\n"
       "      !is_a2dp_offload_codec_extensibility_enabled_) {\n")

NEW = ("  /* " + MARK + ": Pixel's controller rejects QTI A2DP offload opcodes */\n"
       "  if (false && (!check_controller_support_offload_v2() ||\n"
       "      !is_a2dp_offload_codec_extensibility_enabled_)) {\n")


if not F.exists():
    sys.exit(f"ERROR: {F} not found (run from the source root)")

text = F.read_text()

if MARK in text:
    print(f"already patched: {F}")
    sys.exit(0)

n = text.count(OLD)

if n != 2:
    sys.exit(f"ERROR: expected 2 matches in {F}, found {n}; anchors need updating")

F.write_text(text.replace(OLD, NEW))

print(f"patched: {F}")
