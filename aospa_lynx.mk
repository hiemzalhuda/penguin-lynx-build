#
# SPDX-FileCopyrightText: Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#
# PenguinOS product makefile for Pixel 7a (lynx), Android 17.
# Adapted from LineageOS lineage_lynx.mk (lineage-24.0) and from the
# Infinity-X infinity_lynx.mk pattern, because Project-PenguinOS ships
# no lynx product (its products list is Xiaomi/OnePlus/Nothing/Sony only).
# Place this file at vendor/aospa/products/lynx/aospa_lynx.mk in the
# synced tree, and register it in vendor/aospa/products/AndroidProducts.mk
# next to aospa_sky.mk / aospa_marble.mk.
#
ifeq (aospa_lynx,$(TARGET_PRODUCT))

# Path variables — SAMA seperti lineage_lynx.mk. WAJIB ada sebelum inherit
# aosp_lynx.mk: device/google/lynx/lynx/BoardConfig.mk memakai
# $(VENDOR_PATH)/BoardConfigVendor.mk dan $(DEVICE_PATH)/sepolicy/*.
# aosp_lynx.mk TIDAK mendefinisikan ketiganya (hanya lineage_lynx.mk yang
# melakukannya), jadi tanpa ini build #2 mati di lunch dengan
# "/BoardConfigVendor.mk: No such file or directory".
DEVICE_CODENAME := lynx
DEVICE_PATH := device/google/lynx
VENDOR_PATH := vendor/google/lynx

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

# Inherit from the custom device configuration.
# device/google/lynx/aosp_lynx.mk pulls gs201 common + device-lynx.mk.
$(call inherit-product, device/google/lynx/aosp_lynx.mk)

# Inherit from the AOSPA/PenguinOS configuration.
$(call inherit-product, vendor/aospa/target/product/aospa-target.mk)

# ViPER4AndroidFX DIHAPUS 10 Nov 2026: repo TeamWin/android_external_v4afx
# 404 di GitHub API, commit ef9f1d7b… tidak bisa diverifikasi. V4A cuma
# efek audio, bukan kebutuhan boot — jangan inherit sebelum ada sumber
# V4A terverifikasi.

PRODUCT_BRAND := google
PRODUCT_DEVICE := lynx
PRODUCT_MANUFACTURER := Google
PRODUCT_MODEL := Pixel 7a
PRODUCT_NAME := aospa_lynx

PRODUCT_GMS_CLIENTID_BASE := android-google

# Boot animation resolution, same panel as Infinity-X lynx (1080x2400).
TARGET_BOOT_ANIMATION_RES := 1080
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_WIDTH := 1080
TARGET_USES_BLUR := true

# Vendor blobs, same as the Infinity-X lynx build.
$(call inherit-product, vendor/google/lynx/lynx-vendor.mk)

# PRUNE vendor/qcom/common dari Soong (build #12): tree itu berisi
# modul HAL/vendor khusus QCOM (display 4.19/5.4/5.10/5.14/5.15,
# gps-legacy, ...) yang dependensinya (libdisplaydebug, libgps.utils,
# ...) hanya resolve bila repo HAL QCOM yang cocok ikut disync —
# tidak satu pun dibutuhkan lynx (Tensor). Build Infinity-X lynx
# bekerja tanpa tree itu di source sama sekali, dan tidak ada satu
# pun modulnya yang direferensi file produk lynx (device-lynx.mk /
# gs201 / lynx-vendor.mk / aospa-target.mk). Soong mem-parsing semua
# Android.bp dalam cakupan meski modulnya tak pernah dibangun produk,
# jadi mengecualikan direktorinya mematikan seluruh kelas error itu
# sekaligus — daripada menambal satu modul tiap build.
PRODUCT_SOURCE_ROOT_DIRS += -vendor/qcom/common

# PRUNE vendor/aospa/interfaces/health (build #14): AOSPA mem-fork
# interface health Lineage ke sini dan mendefinisikan modul yang SAMA
# (vendor.lineage.health, vendor.lineage.health-service.default) dengan
# hardware/lineage/interfaces/health yang baru ditambah di #13 → Soong
# mati "module already defined". Versi Lineage adalah superset (plus
# android.hardware.health-service.batteryless*), jadi memangkas salinan
# AOSPA tidak menghilangkan apa pun. Subdir interfaces AOSPA lain
# (biometrics, power, powershare, qcom, richtap, usb) tidak berbenturan
# — sudah dicek, tidak mendefinisikan modul vendor.lineage.*.
PRODUCT_SOURCE_ROOT_DIRS += -vendor/aospa/interfaces/health

# ARTIFACT PATH REQUIREMENT (build #17): gs201/aosp_common.mk mewarisi
# generic_system.mk (GSI) — partisi system hanya boleh berisi artefak
# GSI. PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS=relaxed di aosp_common
# TIDAK mematikan pemeriksaan ini (hanya "false" yang mematikan; lihat
# build/soong/fsgen/artifact_path_requirements.go). Mekanisme yang
# disahkan adalah allowlist — preseden: infinity_lynx.mk:51 dan
# vendor/infinity/config/common.mk di tree Infinity-X.
PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/bin/curl \
    system/etc/default-permissions/default_permissions_co.aospa.sense.xml \
    system/etc/permissions/privapp_whitelist_co.aospa.sense.xml \
    system/etc/sysconfig/hiddenapi-whitelist-co.aospa.sense.xml \
    system/etc/sysconfig/preinstalled-packages-platform-full-base.xml \
    system/etc/textclassifier/actions_suggestions.universal.model \
    system/etc/textclassifier/lang_id.model \
    system/etc/textclassifier/textclassifier.en.model \
    system/etc/textclassifier/textclassifier.universal.model \
    system/framework/tcmiface.jar \
    system/framework/telephony-ext.jar \
    system/lib/android.hidl.manager@1.0.so \
    system/lib64/android.hidl.manager@1.0.so \
    system/lib64/libFaceDetectCA.so \
    system/lib64/libMegviiUnlock-jni-1.2.so \
    system/lib64/libMegviiUnlock.so \
    system/lib64/libmegface.so \
    system/priv-app/ParanoidSense/ParanoidSense.apk

# Dua properti AOSPA (aospa-target.mk) yang ditulis ke partisi system —
# diizinkan lewat allowlist sysprop (nama saja, tanpa nilai; Go
# menambahkan "=%" sendiri). Preseden: product_config.mk memakai
# mekanisme yang sama untuk apexd.config.compressed_apex.
PRODUCT_ARTIFACT_PATH_REQUIREMENT_SYSPROP_ALLOWED_LIST += \
    persist.sys.strictmode.disable \
    ro.config.media_vol_steps

# FCM AOSPA (build #17-#18): DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE
# di aospa-target.mk menaruh aospa_vendor_framework_compatibility_matrix.xml
# ke partisi system — dilarang generic_system.mk, dan TIDAK ada allowlist
# untuk FCM. Per pesannya: matriks didefinisikan sebagai modul
# vintf_compatibility_matrix dengan system_ext_specific: true (dibuat
# penguin-setup.sh langkah 6 di vendor/aospa/target/config/Android.bp)
# dan ditambahkan ke PRODUCT_PACKAGES. PERHATIAN: membuang entrinya lewat
# `filter-out` di file ini GAGAL (build #18) — variabel ini digabung dari
# SEMUA file produk dalam rantai inherit, jadi `:=` di sini tidak
# menghapus entri dari file yang di-inherit (terbukti: nilai akhir di
# soong.aospa_lynx.variables tetap berisi file itu). Entrinya dihapus
# di sumbernya oleh penguin-setup.sh langkah 7
# (patches/aospa_fcm_remove.py). Isi matriksnya tetap sama — hanya
# pindah dari system ke system_ext.
PRODUCT_PACKAGES += aospa_vendor_framework_compatibility_matrix

# Build Mainline APEX modules from source. This fixed the Infinity-X
# build #2 failure (undefined *.google.contributions.prebuilt modules)
# and is carried over as a precaution; drop it only if the PenguinOS
# tree builds cleanly without it and the reason is documented.
PRODUCT_MODULE_BUILD_FROM_SOURCE := true

endif
