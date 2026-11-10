# patches/

Patch yang dijalankan `penguin-setup.sh` setelah `repo sync`.
Jalankan dari source root; kedua skrip aman diulang (idempotent —
mereka memeriksa marker sebelum mem-patch).

## Asal

Salinan verbatim dari [raj-tirtha/local_manifests](https://github.com/raj-tirtha/local_manifests)
(`patches/`, branch `penguin-17`, dibaca 10 Nov 2026) buat Pixel 7 /
7 Pro. Isi file tidak diubah; Tensor G2 di `lynx` sama dengan di
`panther` / `cheetah`, jadi patch-nya berlaku apa adanya.

## Isi

- `qti_a2dp_offload.py` (27 baris) — Bluetooth A2DP: stack CLO
  fallback ke perintah HCI offload khusus Qualcomm saat controller
  tidak mendukung offload v2; controller Broadcom Pixel menolaknya
  (status 12) sehingga tidak ada audio. Patch ini memaksa jalur
  offload AOSP di `packages/modules/Bluetooth/system/bta/av/bta_av_aact.cc`
  (kondisi QTI diubah jadi `false && (...)`, 2 kemunculan).
- `qti_noretry.py` (40 baris) — menghentikan retry tanpa henti atas
  lookup layanan khusus QTI yang tidak ada: `ActiveServices` mengingat
  kegagalan lookup servicetracker HAL, dan `BoostFramework` hanya
  mencoba memuat `com.qualcomm.qti.Performance` satu kali per proses.

Alasan patch-patch ini ada: framework AOSPA/PenguinOS berorientasi
Qualcomm, sementara Tensor tidak punya QTI HAL.

## Yang sengaja tidak disalin

`penguin-setup.sh` asli raj-tirtha juga memanggil
`patches/viridian/patch.py` dan
`patches/viridian_brightness_boost/patch.py`, tapi kedua file itu
tidak ada di repo dia yang terlihat di GitHub — jadi tidak disalin ke
sini, dan langkah viridian dihilangkan dari `penguin-setup.sh` versi
repo ini. Bila sumber file viridian itu ditemukan, tambahkan kembali
dengan mencatat asalnya di sini.

Jangan menambah patch tanpa mencatat asal + alasan di file ini.
