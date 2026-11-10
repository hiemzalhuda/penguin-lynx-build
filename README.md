# penguin-lynx-build

Porting **Project PenguinOS** (Android 17, branch `celerity`) ke **Pixel 7a (`lynx`)** —
unofficial, bukan build resmi PenguinOS.

Repo ini adalah lapisan adaptasi, meniru pola `infinity-lynx-build`:
semua yang spesifik buat `lynx` ada di sini, tree upstream tetap
di-sync dari sumber aslinya tiap rebuild. Tidak ada kunci signing,
tidak ada blob proprietary, dan tidak ada file ZIP di repo ini.

## Status

- **Repo dibuat:** 10 Nov 2026, publik, `hiemzalhuda/penguin-lynx-build`
- **Target:** Pixel 7a (`lynx`), Tensor G2 (`gs201`), Android 17
- **Basis:** PenguinOS `celerity` (fork AOSPA / Paranoid Android)
- **Build pertama:** belum jalan. Tree `/root/penguin` di server
  `rom-build-max` sudah dihapus 6 Nov 2026 atas perintah user, jadi
  build PenguinOS harus sync ulang dari nol bila dilanjutkan.

## Kenapa ini porting, bukan build resmi

Upstream PenguinOS tidak menyediakan apa pun buat Pixel: daftar
produk resminya hanya Xiaomi/OnePlus/Nothing/Sony (`sky`, `marble`,
`peridot`, …), dan di SourceForge resminya tidak ada folder
`panther`, `cheetah`, atau `lynx`. Referensi porting Pixel yang
terbukti boot adalah [raj-tirtha](https://github.com/raj-tirtha)
buat Pixel 7 / 7 Pro (`panther` / `cheetah`) — repo ini mengadaptasi
pola dia ke `lynx`, dengan kredit di bawah.

## Isi repo

| File | Fungsi |
| --- | --- |
| `lynx.xml` | Local manifest: device tree, gs201, kernel prebuilt, dan vendor blob `lynx` (semua di-pin ke `lineage-24.0`, karena di bawah manifest PenguinOS repo-repo itu tidak punya branch `celerity`) |
| `aospa_lynx.mk` | Product makefile baru `aospa_lynx`, pola `aospa_sky.mk` + `infinity_lynx.mk`. Setelah sync, salin ke `vendor/aospa/products/lynx/aospa_lynx.mk` dan daftarkan di `vendor/aospa/products/AndroidProducts.mk`, lalu lunch `aospa_lynx-userdebug` |
| `penguin-setup.sh` | Setup pasca-sync buat `lynx`, diadaptasi dari `penguin-setup.sh` raj-tirtha (jalankan patch QTI di `patches/`). Salin file ini + folder `patches/` ke source root, lalu jalankan dari sana. Catatan: dua langkah viridian di skrip asli sengaja TIDAK disertakan, karena file-nya tidak ada di repo raj-tirtha — lihat komentar di dalam skrip. |
| `patches/` | Patch Python QTI (audio Bluetooth) + catatan asalnya |
| `scripts/setup-penguin-lowram.sh` | Setup mesin build low-RAM (Ubuntu 22.04, swap 32 GB, ccache 30 GB) |
| `scripts/build-penguin-lynx-lowram.sh` | Perintah build low-RAM pertama: vanilla, `userdebug`, `-j2` |
| `docs/01-porting-notes.md` | Catatan porting: apa yang diambil dari raj-tirtha, apa yang beda di `lynx` |

## Cara build (ringkas)

```text
repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs
cp lynx.xml .repo/local_manifests/lynx.xml
repo sync --current-branch --no-tags -j4
cp penguin-setup.sh <source-root>/
cp -r patches <source-root>/
cd <source-root> && ./penguin-setup.sh
cp aospa_lynx.mk vendor/aospa/products/lynx/aospa_lynx.mk
# daftarkan di vendor/aospa/products/AndroidProducts.mk
./rom-build.sh lynx -j2 -t userdebug -l
```

Detail lengkap (termasuk jebakan low-RAM, OOM, dan gerbang sebelum
flash) ada di `docs/01-porting-notes.md` dan `scripts/`.

Aturan build yang berlaku di sini, sama seperti Infinity-X:

- Build pertama vanilla dulu (`-l`), `userdebug`, `-j2` — memisahkan
  kegagalan porting dari konflik GMS. GMS (`-g`) baru setelah vanilla
  terbukti boot.
- Bila OOM, ulang `-j1`, tanpa `make clean`, tanpa hapus tree.
- Signing pertama pakai testkeys. Kunci privat hanya bila build ini
  diputuskan layak jadi daily driver, dengan gerbang yang sama seperti
  Infinity-X: sertifikat OTA kunci privat, release-keys, fingerprint
  stock, tanpa marker lineage, plus backup data + stock factory image
  siap sebelum flash apa pun.
- Jangan push GitHub tanpa perintah eksplisit user.

## Kredit

- [Project-PenguinOS](https://github.com/Project-PenguinOS) — PenguinOS,
  fork AOSPA / Paranoid Android (Apache-2.0)
- [raj-tirtha](https://github.com/raj-tirtha) — pola porting Pixel
  (`local_manifests`, `cheetah.xml`, `penguin-setup.sh`, patch QTI)
  buat `panther` / `cheetah`, yang diadaptasi ke `lynx` di sini
- LineageOS — device tree `lynx` + `gs201`, kernel prebuilt
- TheMuppets — vendor blob `lynx`
- YAAP / Syd kernel — referensi kernel prebuilt Pixel 7 series

## Lisensi

Kode PenguinOS / AOSPA memakai Apache License 2.0. File adaptasi di
repo ini mengikuti lisensi yang sama. Aset branding PenguinOS memakai
CC BY-NC 4.0 (lihat README manifest upstream).
