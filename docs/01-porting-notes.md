# Catatan porting PenguinOS ke lynx

## Yang sudah terbukti (4 Nov 2026)

- PenguinOS = fork AOSPA, Android 17, branch `celerity`.
  `repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs`,
  `repo sync --current-branch --no-tags -j4`, build `./rom-build.sh DEVICE`.
- Vendor tree PenguinOS masih bernama `vendor/aospa`
  (`Project-PenguinOS/android_vendor_aospa`, branch `celerity`).
  Produk resmi contoh: `vendor/aospa/products/sky/aospa_sky.mk`,
  lunch `aospa_sky-userdebug`.
- Daftar produk resmi TIDAK memuat `lynx`, `panther`, atau `cheetah`.
- Paket device `lynx` yang terbukti di build Infinity-X (dipakai ulang,
  tanpa diubah versinya):
  - `LineageOS/android_device_google_lynx`, `lineage-24.0`
  - `LineageOS/android_device_google_gs201`, `lineage-24.0`
  - `LineageOS/android_device_google_lynx-kernels`, `lineage-24.0`
    (kernel prebuilt; build kernel dari source belakangan)
  - `TheMuppets/proprietary_vendor_google_lynx`, `lineage-24.0`
    (mirror GitHub TheMuppets; mirror GitLab sudah usang, jangan pakai)
  - Keempatnya WAJIB di-pin eksplisit di `lynx.xml`.
- Build PenguinOS di server `rom-build-max` sempat dimulai 4 Nov 2026
  (setup selesai, sync jalan, tree 113 GB), lalu dihentikan 6 Nov 2026
  atas perintah user, dan tree `/root/penguin` (279 GB) dihapus pada
  hari yang sama. Jadi build berikutnya sync ulang dari nol.

## Yang diambil dari raj-tirtha (panther/cheetah, diverifikasi 10 Nov 2026)

Profil: https://github.com/raj-tirtha — 7 repo publik, bukan anggota
org Project-PenguinOS, bukan maintainer resmi. Build-nya unofficial.

- `local_manifests` (satu-satunya repo bukan fork): `cheetah.xml`
  (manifest lokal buat `cheetah` DAN `panther`), `penguin-setup.sh`,
  `patches/qti_a2dp_offload.py`, `patches/qti_noretry.py`.
- `android_device_google_pantah`: fork LineageOS, cabang `penguin-17`,
  17 commit di depan `lineage-24.0`; ada `aospa_panther.mk`,
  `aospa_cheetah.mk`, dan overlay Settings yang menampilkan nama
  maintainer + nomor build asli di About phone.
- `android_device_google_gs201`: fork LineageOS, cabang `penguin-17`.
- `proprietary_vendor_google_panther`: fork TheMuppets, cabang
  `penguin-17`; commit "Drop modules unsupported by Penguin OS build".
- `device_google_pantah-kernel`: fork YAAP, kernel prebuilt Syd
  (Image.lz4, boot.img, dtbo.img, ratusan `.ko`).
- `hardware_interfaces`: fork `penguinos-shadedark/hardware_interfaces`,
  cabang perbaikan audio Bluetooth.
- Isi `cheetah.xml` dia (dibaca verbatim 10 Nov 2026): device tree
  fork dia sendiri (`raj-tirtha/android_device_google_pantah`,
  `penguin-17`), kernel source fork dia
  (`raj-tirtha/android_kernel_google_gs201`, `penguin-17-syd`),
  kernel prebuilt dia (`raj-tirtha/android_device_google_pantah-kernels`),
  google-modules AOSP `android-17.0.0_r2` (battery, thermal, memory,
  gpu, display, power, aoc, video, edgetpu, wlan, bluetooth, bts, usf,
  touch, soc, staging, uwb, bluetooth-broadcom, hdm, lwis), vendor
  TheMuppets `cheetah` + `panther` + `vendor/google` (`lineage-24.0`),
  dan ViPER4AndroidFX TeamWin (commit `ef9f1d7b…`). TIDAK ada di
  manifest itu: penggantian `tinycompress` / `wpa_supplicant` /
  `hardware_interfaces`, `beans.xml`, atau penyembunyian repo Qualcomm
  — klaim itu sempat muncul di riset awal dan sudah dikoreksi setelah
  file aslinya dibaca.
- `penguin-setup.sh` dia (30 baris, verbatim): hanya menjalankan patch
  Python dari folder `patches/` di source root. Dua langkah viridian
  (`patches/viridian/patch.py`, `patches/viridian_brightness_boost/patch.py`)
  ADA di skripnya tapi file-nya TIDAK ADA di repo dia yang terlihat di
  GitHub (folder `patches/` hanya berisi kedua file QTI) — jadi skrip
  aslinya akan gagal di langkah viridian. Versi di repo ini sengaja
  menghilangkan kedua langkah itu, dengan catatan di dalam skrip.
- `aospa_panther.mk` dia (52 baris): inherit `aosp_panther.mk`,
  `aospa-target.mk`, `ViPER4AndroidFX/config.mk`, vendor
  `panther-vendor.mk`; `TARGET_PREBUILT_KERNEL :=
  device/google/pantah-kernels/6.1/Image.lz4`; overlay Settings
  `overlay-penguin` via `PRODUCT_PACKAGE_OVERLAYS`.
- Verifikasi repo `lynx` (10 Nov 2026): `LineageOS/android_device_google_lynx`,
  `TheMuppets/proprietary_vendor_google_lynx`, dan
  `LineageOS/android_device_google_lynx-kernels` semuanya ada dengan
  cabang `lineage-24.0`. `yaap/device_google_lynx-kernel` TIDAK ada
  (404). `penguinos-shadedark/hardware_interfaces` ada tapi hanya punya
  cabang `celerity`, tidak ada `lineage-24.0` — jadi tidak dipakai di
  `lynx.xml` ini.

## Perbaikan 10 Nov 2026 (sebelum sync pertama)

Analisa pre-build + verifikasi ulang via `git ls-remote` / GitHub API /
SSH menemukan 3 celah di `lynx.xml` — semuanya diperbaiki, bukan
cuma dicatat:

- **Hapus `TheMuppets/proprietary_vendor_google`** — branch
  `lineage-24.0` tidak ada (tertinggi `lineage-19.1`). Baris ini akan
  menggagalkan `repo sync`. `vendor/google/lynx` sudah tercakup repo
  TheMuppets khusus lynx.
- **Hapus 21 entri `google-modules/aosp/*` @ `android-17.0.0_r2`** —
  repo tidak ada di `android.googlesource.com` (404). Tidak dibutuhkan:
  tree Infinity-X di server tidak punya `kernel/google-modules` sama
  sekali dan build 4.2 tetap jalan + boot (kernel prebuilt).
- **Hapus `TeamWin/android_external_v4afx`** — repo 404 di GitHub API.
  Inherit `config.mk`-nya juga dihapus dari `aospa_lynx.mk`. V4A cuma
  efek audio, bukan kebutuhan boot.
- **Skrip ikut dibenahi dari pelajaran Infinity-X:** build script kini
  export `JAVA_TOOL_OPTIONS="-Xmx5120m ..."` (heap JVM default ~1,9 GiB
  bikin KSP SystemUI mati OOM di 4.2), `LC_ALL=C`, `OUT_DIR=out`;
  setup script pakai identitas git user yang benar (bukan placeholder)
  dan `ccache -M 40G` (jangan turunkan — dipakai bersama Infinity-X).
- **Disk server naik 800 GB → 1 TB** (1024 GB) pada 10 Nov 2026 atas
  perintah user; sisa kosong 421 GB. Tree PenguinOS (~240–290 GB) kini
  muat berdampingan dengan Infinity-X tanpa hapus `out/`.
- **Catatan builder:** `rom-build.sh` tidak ada di repo manifest, tapi
  muncul otomatis setelah sync lewat linkfile `vendor/aospa/build.sh`
  → `rom-build.sh`. Skrip itu memakai `m` (bukan direct ninja), jadi
  tiap run lewat Soong/Kati lagi — belum ada jalur restart direct
  ninja buat PenguinOS.

## Perbaikan saat build pertama (11 Nov 2026)

- **Build #1 gagal di lunch** — bukan soal release (lunch AOSPA
  default ke `cp2a` untuk format 2 segmen; itu release yang sama
  dipakai build Infinity-X 4.2 yang sukses). Akar masalah:
  `device/google/gs201/common.mk:122` butuh
  `hardware/google/pixel/rebalance_interrupts/rebalance_interrupts.mk`
  yang tidak ada di manifest PenguinOS/AOSP. Perbaikan: tambah
  `LineageOS/android_hardware_google_pixel` (`lineage-24.0`, sudah
  diverifikasi ada) ke `lynx.xml`, lalu `repo sync` ulang.
  Error `release_config.mk:158 "No release config set"` yang muncul
  sesudahnya HANYA efek lanjutan (lunch gagal → TARGET_RELEASE tidak
  ter-export) — jangan kejar itu.
- **Build #2 gagal di lunch** — `device/google/lynx/lynx/BoardConfig.mk:39`
  butuh `$(VENDOR_PATH)/BoardConfigVendor.mk` dan
  `$(DEVICE_PATH)/sepolicy/*`, tapi `VENDOR_PATH`/`DEVICE_PATH`/
  `DEVICE_CODENAME` hanya didefinisikan di `lineage_lynx.mk`,
  bukan di `aosp_lynx.mk` yang kita inherit. Perbaikan: definisikan
  ketiganya di `aospa_lynx.mk` (sebelum inherit, meniru
  `lineage_lynx.mk`). Error `release_config.mk:158` yang muncul
  sesudahnya lagi-lagi cuma efek lanjutan lunch yang gagal.
- **Build #3 gagal di Soong bootstrap** — vendor blob TheMuppets
  memakai tipe modul `rust_prebuilt_binary` (`dump_modem`, `gpuflag`
  di `vendor/google/lynx/Android.bp`), tapi Soong AOSPA
  (android-17.0.0_r1) tidak mengenal tipe itu. Perbaikan:
  `patches/soong_rust_prebuilt_binary.py` mengganti
  `build/soong/rust/prebuilt.go` dengan salinan byte-identik dari
  file LineageOS di tree Infinity-X 4.2 (362 baris); dijalankan
  `penguin-setup.sh` sebagai langkah ketiga. Wajib diulang tiap
  habis `repo sync`.
- **Build #4 gagal di Soong bootstrap** — `vendor/google/lynx/Android.bp`
  butuh `soong_namespace` `hardware/qcom/wlan/wcn6740`, tapi manifest
  AOSPA menyertakan `AOSPA/android_hardware_qcom_wlan` yang tidak punya
  subdir itu (isinya buat HP QCOM). Perbaikan: di `lynx.xml`,
  `remove-project` AOSPA lalu ganti dengan
  `LineageOS/android_hardware_qcom_wlan` (`lineage-24.0`) — tree yang
  sama dipakai build Infinity-X lynx. Checkout lama wajib dihapus dulu
  (`rm -rf hardware/qcom/wlan`) sebelum `repo sync` ulang; tanpa
  remove-project, repo sync error "duplicate path". Scan semua import
  `soong_namespace` di vendor/device/hardware menunjukkan hanya inilah
  yang hilang.
- **Build #5 gagal di Soong bootstrap** — `libgpuflag_aconfig_rust`
  adalah `rust_prebuilt_dylib` vendor, tapi Soong AOSP menolak modul
  rust prebuilt di image non-system. Perbaikan:
  `patches/soong_rust_prebuilt_image.py` mengganti
  `build/soong/rust/image.go` dengan salinan LineageOS dari tree
  Infinity-X 4.2 (cek itu dihapus, 8 baris lebih pendek); dijalankan
  `penguin-setup.sh` sebagai langkah keempat. Wajib diulang tiap
  habis `repo sync`.
- **Build #6 gagal di Soong ("analyzing Android.bp")** —
  `GoogleParts` (`device/google/gs201/parts/Android.bp`) butuh modul
  `org.lineageos.settings.resources`, tapi manifest AOSPA menyertakan
  `AOSPA/android_packages_resources_devicesettings` yang mendefinisikan
  modul itu sebagai `co.aospa.resources` (tidak dipakai siapa pun di
  tree). Perbaikan: di `lynx.xml`, `remove-project` AOSPA lalu ganti
  dengan `LineageOS/android_packages_resources_devicesettings`
  (`lineage-24.0`); checkout lama dihapus dulu sebelum `repo sync`
  ulang — pola yang sama seperti wlan di build #4.
- **Build #7 gagal di Soong** — `librmnetctl`
  (`vendor/qcom/opensource/dataservices/rmnetctl`) butuh modul
  `qti_kernel_headers` yang hanya didefinisikan di
  `hardware/qcom-caf/common`. Perbaikan: tambah
  `LineageOS/android_hardware_qcom-caf_common` (`lineage-24.0`) ke
  `lynx.xml`, lalu `repo sync` ulang. Hanya repo `common` yang
  ditambah, bukan seluruh tree qcom-caf — tidak ada file di tree yang
  mereferensi path `hardware/qcom-caf/` secara langsung.
- **Build #8 gagal di Soong (7 detik)** — repo caf di atas ternyata
  mendefinisikan ~90 modul `rfs_*` symlink + mountpoint yang SUDAH
  ada di `device/qcom/common/Android.bp` (AOSPA) → 96x "module already
  defined". Scan membuktikan satu-satunya modul caf yang dipakai tree
  adalah `qti_kernel_headers`. Perbaikan: repo caf DIHAPUS dari
  `lynx.xml`, diganti shim lokal
  `tree-files/hardware/qcom-caf/common/Android.bp` (hanya modul itu,
  disalin verbatim dari file LineageOS) yang disalin ke tree oleh
  build script. Build script kini juga menyalin `aospa_lynx.mk`,
  mendaftarkannya di `AndroidProducts.mk` (idempotent), dan menjalankan
  `penguin-setup.sh` — jadi rebuild dari sync bersih cukup satu
  perintah, dengan verifikasi marker supaya salinan basi ketahuan.
- **Build #10 gagal di Soong (1:22)** — `libcdfw_remote_api`
  (`vendor/qcom/common/vendor/gps-legacy`) butuh `libgps.utils` yang
  hanya ada sebagai prebuilt di `vendor/google/lynx/Android.bp` (blob
  Google) — namespace gps-legacy tidak meng-import namespace itu.
  Perbaikan: `patches/qcom_gps_legacy_namespace.py` menambah
  `"vendor/google/lynx"` ke imports namespace gps-legacy; dijalankan
  `penguin-setup.sh` sebagai langkah kelima. Wajib diulang tiap habis
  `repo sync`. Stack gps-legacy sendiri adalah dead code buat lynx
  (tidak ada di produk), Soong hanya butuh dependensinya resolve.
- **Perubahan lokal di tree (tidak di repo, hilang bila sync dari nol):**
  `device/google/lynx/AndroidProducts.mk` ditambah baris
  `$(LOCAL_DIR)/aospa_lynx.mk` supaya `lunch aospa_lynx-userdebug`
  menemukan produk; `aospa_lynx.mk` disalin ke
  `device/google/lynx/`; `penguin-setup.sh` + `patches/` disalin ke
  root tree dan dijalankan (ketiga patch QTI terverifikasi masuk:
  `bta_av_aact.cc`, `ActiveServices.java`, `BoostFramework.java`).
  Catatan: patch QTI kedua menyasar
  `frameworks/base/core/java/android/util/BoostFramework.java`,
  BUKAN `services/core/.../am/` seperti dugaan awal. Sejak 11 Nov,
  ketiga langkah ini + shim `hardware/qcom-caf/common/Android.bp`
  dilakukan OTOMATIS oleh `scripts/build-penguin-lynx-lowram.sh`
  (dengan verifikasi marker) — jadi rebuild cukup jalankan script
  itu, tapi clone repo di server (`/root/penguin-lynx-build`) harus
  disamakan dulu dengan repo lokal bila ada commit baru yang belum
  ter-push.

## Yang beda di lynx

- Tidak ada repo `lynx` di akun raj-tirtha sama sekali. Tree bersama
  dia bernama `pantah` (Pixel 7 + 7 Pro); `lynx` butuh tree sendiri.
- Pendekatan repo ini (sama seperti 4 Nov): JANGAN fork device tree
  dulu. Pakai LineageOS stock `lineage-24.0` + product file
  `aospa_lynx.mk` yang ditaruh di `vendor/aospa/products/lynx/`.
  Fork device tree baru dibuat bila Soong / build menuntut perubahan
  di dalam tree (misalnya nama maintainer, overlay, atau flag).
- Kernel: pakai dulu LineageOS `lynx-kernels` prebuilt (sudah terbukti
  di Infinity-X). Kernel prebuilt Syd ala raj-tirtha baru dipertimbangkan
  bila ada masalah spesifik (misalnya GPU fault) — dan itu pun harus
  diverifikasi sumber + commit-nya, bukan asal salin.
- Vendor: TheMuppets `lynx`, `lineage-24.0`. Periksa setelah sync apakah
  ada modul yang harus di-drop seperti yang raj-tirtha lakukan di
  `panther` ("Drop modules unsupported by Penguin OS build").
- `aospa_lynx.mk` memakai `vendor/google/lynx/lynx-vendor.mk` mengikuti
  pola Infinity-X. Bila `device-lynx.mk` sudah menarik vendor yang sama
  dan Soong protes duplikat, hapus salah satu inherit-nya dan catat
  alasannya di sini.
- `PRODUCT_MODULE_BUILD_FROM_SOURCE := true` dibawa dari Infinity-X
  (memperbaiki failure `*.google.contributions.prebuilt` di build #2);
  buang hanya bila tree PenguinOS build bersih tanpa itu, dengan alasan
  terdokumentasi.

## Resep build

- Mesin: `rom-build-max`, 4 CPU / 8 GB RAM, disk 1 TB (1024 GB, naik dari 800 GB pada 10 Nov 2026), Ubuntu 22.04 LTS.
- Swap 32 GB + ccache ~30 GB, sama seperti bilalz / Infinity-X.
- Sync: `repo sync --current-branch --no-tags -j4`.
- Build pertama: vanilla (`-l`), `userdebug`, `-j2`.
- Bila OOM: `-j1`, tanpa `make clean`, tanpa hapus tree.
- Jangan jalankan dua build bersamaan di server yang sama.

## Gerbang sebelum flash (bila jadi daily driver)

Sama seperti Infinity-X: sertifikat OTA kunci privat, release-keys,
fingerprint stock, tanpa marker lineage, ZIP lengkap + DTB, backup data
+ stock factory image siap sebelum flash. Play Integrity dicek terpisah.
