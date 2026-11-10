#!/usr/bin/env python3
"""Tensor: stop CLO framework from retrying QTI-only lookups forever.

Run from the Penguin source root after repo sync. Safe to re-run."""

import sys


MARK = "penguin-tensor: qti-noretry"


def patch(path, edits):
    src = open(path).read()

    if MARK in src:
        print(f"skip (already patched): {path}"); return

    for old, new in edits:
        n = src.count(old)

        if n != 1:
            sys.exit(f"ERROR: expected 1 match, found {n} in {path}:\n  {old!r}")

        src = src.replace(old, new)

    open(path, "w").write(src)

    print(f"patched: {path}")


# 1. ActiveServices: remember that the servicetracker HAL is missing
patch("frameworks/base/services/core/java/com/android/server/am/ActiveServices.java", [
    ("    private boolean getServicetrackerInstance() {\n",
     f"    // {MARK}\n"
     "    private boolean mServicetrackerUnavailable = false;\n\n"
     "    private boolean getServicetrackerInstance() {\n"
     "        if (mServicetrackerUnavailable) return false;\n"),

    ("        if (mServicetracker == null) {\n",
     "        if (mServicetracker == null) {\n"
     "            mServicetrackerUnavailable = true;\n"),

])


# 2. BoostFramework: try loading com.qualcomm.qti.Performance only once per process
patch("frameworks/base/core/java/android/util/BoostFramework.java", [
    ("    private static boolean sIsLoaded = false;\n",
     "    private static boolean sIsLoaded = false;\n"
     f"    private static boolean sLoadAttempted = false; // {MARK}\n"),

    ("            if (sIsLoaded == false) {\n",
     "            if (sIsLoaded == false && sLoadAttempted == false) {\n"
     "                sLoadAttempted = true;\n"),

])
