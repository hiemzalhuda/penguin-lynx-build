#!/usr/bin/env bash
# penguin-setup.sh — run from the AOSPA source root after `repo sync`
# Applies local Penguin OS patches for Tensor devices (lynx / Pixel 7a).
#
# Diadaptasi dari raj-tirtha/local_manifests penguin-setup.sh
# (penguin-17, buat panther/cheetah). Salin file ini + folder patches/
# dari repo ini ke source root, lalu jalankan dari sana.
#
# PERBEDAAN dari skrip raj-tirtha: dua langkah viridian di skrip aslinya
# (patches/viridian/patch.py dan patches/viridian_brightness_boost/patch.py)
# TIDAK disertakan di sini, karena kedua file itu tidak ada di repo
# raj-tirtha yang terlihat di GitHub (folder patches/ di sana hanya berisi
# kedua file QTI di bawah) — menjalankan skrip aslinya apa adanya akan
# gagal di langkah viridian. Bila file viridian itu ditemukan sumbernya,
# tambahkan kembali langkahnya dan catat asalnya di patches/README.md.
set -euo pipefail
ROOT="$(pwd)"
PATCH_DIR="$ROOT/patches"
LOG="$ROOT/.penguin-setup.log"
: > "$LOG"

patch_error() { echo "ERROR: $1" | tee -a "$LOG"; exit 1; }

echo "Applying qti_a2dp_offload.py" | tee -a "$LOG"
python3 patches/qti_a2dp_offload.py >> "$LOG" 2>&1 || patch_error "qti_a2dp_offload.py FAILED - see $LOG"
echo "Applying qti_noretry.py" | tee -a "$LOG"
python3 patches/qti_noretry.py >> "$LOG" 2>&1 || patch_error "qti_noretry.py FAILED - see $LOG"
echo "Applying soong_rust_prebuilt_binary.py" | tee -a "$LOG"
python3 patches/soong_rust_prebuilt_binary.py >> "$LOG" 2>&1 || patch_error "soong_rust_prebuilt_binary.py FAILED - see $LOG"
echo "Applying soong_rust_prebuilt_image.py" | tee -a "$LOG"
python3 patches/soong_rust_prebuilt_image.py >> "$LOG" 2>&1 || patch_error "soong_rust_prebuilt_image.py FAILED - see $LOG"
echo "Applying qcom_gps_legacy_namespace.py" | tee -a "$LOG"
python3 patches/qcom_gps_legacy_namespace.py >> "$LOG" 2>&1 || patch_error "qcom_gps_legacy_namespace.py FAILED - see $LOG"
echo "Applying aospa_vintf_matrix.py (langkah 6)" | tee -a "$LOG"
python3 patches/aospa_vintf_matrix.py >> "$LOG" 2>&1 || patch_error "aospa_vintf_matrix.py FAILED - see $LOG"
echo "Applying aospa_fcm_remove.py (langkah 7)" | tee -a "$LOG"
python3 patches/aospa_fcm_remove.py >> "$LOG" 2>&1 || patch_error "aospa_fcm_remove.py FAILED - see $LOG"
# Langkah 8 (build #19): sembunyikan vendor/qcom/build dari Kati/Soong.
# File vendor/qcom/build/tasks/kernel_definitions.mk ikut ter-include Kati
# dan mendefinisikan ulang target dtb.img (bentrok dengan
# build/make/core/Makefile:1049) karena guard-nya hanya
# TARGET_PREBUILT_KERNEL — kosong buat lynx (kernel prebuilt di boot.img,
# TARGET_NO_KERNEL=true). .find-ignore memangkas direktori dari pemindaian
# find yang menghasilkan daftar subdir-makefiles Kati (pola yang sama
# dipakai raj-tirtha untuk tree QCOM lain). Keenam file tasks di sana
# semuanya khusus QCOM, tidak dibutuhkan lynx.
if [ -d vendor/qcom/build ]; then
  touch vendor/qcom/build/.find-ignore
  echo "hid vendor/qcom/build (.find-ignore)" | tee -a "$LOG"
fi
# Langkah 9 (analisa pencegahan 11 Nov 2026): sembunyikan 7 direktori QCOM
# yang terverifikasi kode mati buat lynx. Verifikasi: tidak ada referensi
# dari file produk lynx (device-lynx.mk/gs201/lynx-vendor.mk/aospa-target.mk);
# satu-satunya penyebutan adalah dari device/qcom/common (qti-telephony.mk)
# yang TIDAK ter-include buat lynx (components.mk digerbang
# is-board-platform-in-list(QCOM_BOARD_PLATFORMS) — gs201 bukan QCOM),
# plus file platform AOSPA buat HP QCOM lain (waipio/kalama/lahaina/kona/
# msmnile) yang tidak dipakai lynx; dibuktikan juga dari variabel produk
# hasil build (librmnetctl = 0, ipacm tidak ada di soong variables).
# .find-ignore hanya memangkas pemindaian find (Soong/Kati); inherit-product
# eksplisit tetap bisa membaca file di dalamnya bila suatu hari dibutuhkan.
# Daftar ini SAMA dengan yang dipakai raj-tirtha (panther/cheetah) — tapi
# di sini terverifikasi per direktori ke tree lynx, bukan disalin buta.
# JANGAN sembunyikan: hardware/qcom/wlan (PRODUCT_PACKAGES device-lynx.mk),
# device/qcom/common (di-inherit aospa-target.mk), vendor/qcom/sdclang
# (di-inherit aospa-target.mk), vendor/qcom/opensource/core-utils*
# (utils.mk di-include + vendor_bootjars.mk aktif buat lynx: tcmiface),
# vendor/qcom/common (sudah di-prune dari Soong, #12), vendor/qcom/build
# (sudah disembunyikan langkah 8).
for d in vendor/qcom/opensource/data-ipa-cfg-mgr \
         vendor/qcom/opensource/data-ipa-cfg-mgr-legacy \
         vendor/qcom/opensource/dataservices \
         vendor/qcom/opensource/recovery-ext \
         vendor/qcom/opensource/thermal-hal \
         vendor/qcom/opensource/libvmmem \
         hardware/qcom/bootctrl; do
  [ -d "$d" ] && touch "$d/.find-ignore"
done
echo "hid 7 dir QCOM mati (.find-ignore)" | tee -a "$LOG"
# Langkah 10 (build #20 gagal 11 Nov 22:34, error dtb.img yang SAMA dgn #19):
# .find-ignore langkah 8 TIDAK mempan buat file build/tasks/*.mk — file
# itu dikumpulkan Kati lewat jalur lain (configuration.list /
# subdir_makefiles) yang tidak menghormati .find-ignore; buktinya
# vendor_prop_context_restriction.mk dari dir yang sama tetap di-include
# Kati, dan kernel_definitions.mk ikut dievaluasi (warning baris 142/253).
# Perbaikan: guard di LEVEL FILE — lewati seluruh isi file bila
# TARGET_NO_KERNEL=true (lynx: gs201/BoardConfig-common.mk:56). Buat
# perangkat QCOM perilaku tidak berubah. Skrip idempotent.
python3 patches/qcom_kernel_definitions_guard.py . | tee -a "$LOG"
# Langkah 11 (build #21 gagal 12 Nov 02:19, "unknown target otapackage"):
# repo Lineage android_device_google_lynx-kernels HANYA berisi 8 file
# config — .ko/boot.img/dtbo TIDAK PERNAH ada di git (.gitignore
# mengabaikan *.img/*.ko). Tanpa boot.img, BOARD_PREBUILT_BOOTIMAGE
# kosong → INSTALLED_BOOTIMAGE_TARGET kosong → build_ota_package=false
# (build/make/core/Makefile:5916-5929) → target otapackage tidak ada.
# Kernel prebuilt yang dipakai di sini dibangun dari source 3 Nov 2026
# (Bazel 529/529, GKI android14-6.1-2026-03_r24, 6.1.162) dan TERBUKTI
# jalan di Infinity-X 4.2; salinannya ada di tree Infinity-X di server
# yang sama. Bila sumber tidak ada, JANGAN diam-diam lanjut: cetak
# peringatan keras (build akan gagal lagi di otapackage) — bangun kernel
# dari source via manifest Lineage android_kernel_google_gs-6.1_manifest
# + build_lynx.sh, lalu salin hasilnya ke device/google/lynx-kernels/6.1/.
if [ ! -f device/google/lynx-kernels/6.1/boot.img ]; then
  if [ -f /root/infinityx/device/google/lynx-kernels/6.1/boot.img ]; then
    cp -a /root/infinityx/device/google/lynx-kernels/6.1/. device/google/lynx-kernels/6.1/
    echo "kernel prebuilt disalin dari tree Infinity-X (113M)" | tee -a "$LOG"
  else
    echo "PERINGATAN: kernel prebuilt tidak ada (boot.img hilang) dan tree Infinity-X tidak ditemukan — build akan gagal 'unknown target otapackage'. Bangun kernel dari source (manifest android_kernel_google_gs-6.1_manifest, build_lynx.sh) lalu salin ke device/google/lynx-kernels/6.1/." | tee -a "$LOG"
  fi
fi
# Langkah 12 (build #22 gagal 12 Nov 09:37, ninja "symbols/.../dump_modem
# missing"): graft rust_prebuilt_binary langkah 3 tidak lengkap —
# build/soong/rust/rust.go AOSPA tidak punya case
# *prebuiltBinaryDecorator di getSymbolInfo() (dan cek di IsPrebuilt()),
# padahal Lineage punya keduanya. Akibatnya Soong tidak membuat rule
# symbols buat dump_modem/gpuflag, sementara rule install Kati memakai
# file symbols itu sebagai order-only dep. Modul cc_prebuilt_binary
# dengan strip:none yang sama (gs_watchdogd, dump_modemlog) PUNYA rule
# symbols — jadi ini spesifik rust_prebuilt_binary, bukan strip:none.
# Skrip idempotent; bandingkan dengan build/soong/rust/rust.go tree
# Lineage (Infinity-X).
echo "Applying soong_rust_prebuilt_binary_symbols.py (langkah 12)" | tee -a "$LOG"
python3 patches/soong_rust_prebuilt_binary_symbols.py >> "$LOG" 2>&1 || patch_error "soong_rust_prebuilt_binary_symbols.py FAILED - see $LOG"
# Langkah 13 (15 Nov 2026, build direct-ninja gagal sepolicy 04:10 WIB):
# repo hardware/google/pixel-sepolicy (142 file .te) TIDAK ADA di tree AOSPA
# (manifest tidak sync repo ini) padahal BoardConfig-common.mk:266-268
# merujuk subdirnya (googlebattery/input/powerstats). Akibatnya checkpolicy
# AOSPA (strict; Lineage mentolerir) gagal beruntun di recovery_sepolicy.cil:
# macro pixel_bugreport tak terdefinisi, type domain dump_* tak dideklarasi,
# atribut touch_property_type & pixel_battery_* tak dideklarasi, ~24 type
# (sysfs_*, hal_wifi_ext, pixelstats_vendor, vendor_sysfs_*, debugfs_mgm,
# sysfs_soc) tak dideklarasi. Perbaikan: deklarasikan semuanya di
# device/google/gs201/sepolicy/vendor/domain.te (sudah ada di manifest ninja,
# diproses tepat sebelum dump_aoc.te) — file .te BARU tidak bisa dipakai
# karena tidak ada di manifest ninja yang sudah digenerate. Skrip idempotent.
echo "Applying sepolicy_pixel_declarations.py (langkah 13)" | tee -a "$LOG"
python3 patches/sepolicy_pixel_declarations.py >> "$LOG" 2>&1 || patch_error "sepolicy_pixel_declarations.py FAILED - see $LOG"
# Langkah 14 (15 Nov 2026, build direct-ninja gagal 17:36 WIB di
# plat_pub_versioned.cil, 53% [68862/128925]): version_policy gagal
# "typetransition unsupported statement in attributee policy (line 6024)" —
# baris itu (typetransition ssr_detector_app tmpfs file appdomain_tmpfs)
# dari ekspansi macro app_domain(ssr_detector_app) di public policy.
# Akar masalah: external/selinux/libsepol/cil/src/android.c AOSPA punya blok
# extra di __extract_attributees_helper yang menolak CIL_NAMETYPETRANSITION /
# CIL_TYPE_RULE sebagai error fatal. Lineage TIDAK punya blok itu (kedua node
# jatuh ke default = di-skip, lalu ditangani cil_attrib_nametypetransition) —
# makanya Infinity-X berhasil dengan pub_policy.cil yang sama persis (4
# typetransition). Menghapus blok itu menyamakan AOSPA dengan Lineage.
# Skrip idempotent. Catatan: version_policy adalah host tool yang di-build
# ninja dari source ini, jadi restart direct-ninja akan me-rebuild tool-nya
# lalu mengulang langkah plat_pub_versioned.cil.
echo "Applying libsepol_nametypetransition.py (langkah 14)" | tee -a "$LOG"
python3 patches/libsepol_nametypetransition.py >> "$LOG" 2>&1 || patch_error "libsepol_nametypetransition.py FAILED - see $LOG"
# Langkah 15 (15 Nov 2026, build direct-ninja gagal 20:45 WIB di
# precompiled_sepolicy): secilc gagal "Problems processing genfscon rules"
# / "Failed to compile cildb: -1". Penyebab: DUA genfscon untuk path yang
# SAMA dengan type BERBEDA — plat (system/sepolicy/compat/
# plat_sepolicy_genfs_202604.cil) memetakan /class/powercap dan
# /devices/virtual/powercap ke sysfs_powercap, sementara vendor gs201
# (genfs_contexts:29,384) memetakan keduanya ke sysfs_thermal.
# __cil_post_process_context_rules (libsepol cil_post.c) menolak itu.
# Di tree Lineage (Infinity-X, yang berhasil) file plat compat ini TIDAK
# punya kedua rule powercap itu, jadi hanya rule vendor yang berlaku.
# genfs_contexts gs201 byte-identik antara AOSPA dan Lineage. Perbaikan:
# hapus kedua baris powercap dari file plat compat AOSPA. Type
# sysfs_powercap tetap dideklarasikan (tidak dihapus). Skrip idempotent.
echo "Applying sepolicy_powercap_genfscon.py (langkah 15)" | tee -a "$LOG"
python3 patches/sepolicy_powercap_genfscon.py >> "$LOG" 2>&1 || patch_error "sepolicy_powercap_genfscon.py FAILED - see $LOG"
# Langkah 16 (15 Nov 2026, build direct-ninja gagal 23:19 WIB di
# file_contexts.device.sorted.tmp): checkfc gagal "type
# power_stats_device is not defined" — file_contexts gs201:84 memetakan
# /dev/bbd_pwrstat ke power_stats_device, tapi type itu hanya
# dideklarasikan di hardware/google/pixel-sepolicy (powerstats/device.te)
# yang TIDAK ADA di tree AOSPA. Deklarasikan di domain.te seperti
# langkah 13. Scan 298 type unik file_contexts vs 2962 type policy
# membuktikan ini satu-satunya type yang hilang. Skrip idempotent.
echo "Applying sepolicy_power_stats_device.py (langkah 16)" | tee -a "$LOG"
python3 patches/sepolicy_power_stats_device.py >> "$LOG" 2>&1 || patch_error "sepolicy_power_stats_device.py FAILED - see $LOG"
# Langkah 17 (16 Nov 2026, build direct-ninja run 0715 gagal 23:18 WIB di
# target_files packaging, [32329/32329] — add_img_to_target_files.py
# CheckAbOtaImages: "AssertionError: Failed to find abl.img"): AB_OTA_PARTITIONS
# memuat abl + 8 image radio lain, tapi tidak satu pun tersalin ke
# out/target/product/lynx/ karena vendor/google/lynx/Android.mk memanggil
# $(call add-radio-file-sha1-checked,...) — fungsi yang TIDAK DIDEFINISIKAN
# di mana pun di tree AOSPA (definitions.mk hanya punya add-radio-file dan
# add-radio-file-checked; vendor/aospa/build/core/ hanya berisi mkdir.mk).
# Di Lineage/Infinity-X fungsi ini ada di vendor/infinity/build/core/utils.mk
# (di-include definitions.mk vendor). Kati diam-diam menghasilkan string
# kosong untuk $(call) fungsi tak terdefinisi, jadi INSTALLED_RADIOIMAGE_TARGET
# kosong dan recipe target_files tidak menyalin apa pun ke RADIO/.
# Perbaikan: tambahkan definisi itu (verbatim dari Lineage) ke
# build/make/core/definitions.mk setelah add-radio-file-checked-internal.
# Kesembilan sha1 radio TERVERIFIKASI cocok dengan Android.mk. Skrip idempotent.
# CATATAN: setelah patch ini manifest ninja HARUS digenerate ulang dengan
# ckati langsung (bukan rom-build.sh/mka, bukan Soong) agar edge radio muncul;
# baru restart direct-ninja.
echo "Applying add_radio_file_sha1_checked.py (langkah 17)" | tee -a "$LOG"
python3 patches/add_radio_file_sha1_checked.py >> "$LOG" 2>&1 || patch_error "add_radio_file_sha1_checked.py FAILED - see $LOG"
# Langkah 18 (17 Nov 2026, run 1648 gagal 08:05 WIB di otapackage
# [32737/32737] — check_target_files_vintf.py CheckVintfIfTrebleEnabled:
# "RuntimeError: VINTF compatibility check failed"): dua instance di device
# manifest tidak ada di framework compatibility matrix —
# vendor.lineage.touch.IGloveMode/default (@1) dan
# vendor.qti.hardware.wifi.supplicant.ISupplicantVendor/default (@1).
# Kedua HAL itu dideklarasikan di device manifest sebagai AIDL v1 (fragment
# hardware/google/pixel/touch/vendor.lineage.touch-service.pixel.xml dan
# external/wpa_supplicant_8/.../android.hardware.wifi.supplicant.xml).
# Perbaikan 08:10 WIB menambahkan keduanya ke
# device/google/lynx/vintf/device_framework_matrix_product.xml TAPI sebagai
# <hal format="hidl"> 1.0 — itu TIDAK BISA lolos: libvintf
# HalManifest::checkUnusedHals memanggil mat.matchInstance(format, ...) dan
# CompatibilityMatrix::matchInstance menyaring lewat forEachInstanceOfVersion
# (format adalah kriteria match); instance AIDL hanya cocok dengan entri
# matrix AIDL. Monitor menghentikan run 0110 (ninja PID 3041020, [2204/39605])
# agar tidak membuang ~8 jam rebuild menuju kegagalan VINTF yang sama.
# Skrip ini mengubah kedua blok HIDL 1.0 menjadi AIDL v1. Edit isi file saja
# cukup (input langsung edge assemble_vintf product matrix di ninja).
# TERBUKTI sebelum restart: check_target_files_vintf terhadap target-files
# tiruan (symlink ke out/ + matrix AIDL) mengembalikan 'compatible';
# kontrol dengan matrix lama (tanpa kedua HAL) gagal (exit 1).
# Skrip idempotent.
echo "Applying vintf_aidl_product_matrix.py (langkah 18)" | tee -a "$LOG"
python3 patches/vintf_aidl_product_matrix.py >> "$LOG" 2>&1 || patch_error "vintf_aidl_product_matrix.py FAILED - see $LOG"
echo "Penguin setup complete - see $LOG" | tee -a "$LOG"
