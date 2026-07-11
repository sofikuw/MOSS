# My Own Splash Screen – Magisk Module

**by sofikuw**

Change the Samsung boot splash screen, charging screen, download mode screen,
and more — by flashing your own `up_param.bin` directly to the `up_param`
partition. Works on **Stock ROM** and **Custom ROMs** (LineageOS, crDroid,
AOSP-based, etc.) with both **Exynos** and **Snapdragon** Samsung devices.

---

## Table of Contents

1. [What is up_param?](#what-is-up_param)
2. [First device that used up_param](#first-device-with-up_param)
3. [Download up_param.bin from SamFW](#download-up_parambin-from-samfw)
4. [Extract up_param.bin on Android (free)](#extract-up_parambin-on-android-free)
5. [Edit & repack up_param.bin](#edit--repack-up_parambin)
6. [Flash methods](#flash-methods)
   - [Method 1 — Magisk module (this module)](#method-1--magisk-module-recommended)
   - [Method 2 — Termux / ADB shell (dd)](#method-2--termux--adb-shell-dd)
7. [Image reference](#image-reference)
8. [Troubleshooting](#troubleshooting)
9. [Restore original splash](#restore-original-splash)

---

## What is up_param?

`up_param` is a small dedicated partition on Samsung devices (around 8–16 MB).
It stores the pre-boot splash/logo images that the bootloader shows **before
Android even starts**. These images cannot be changed by a normal system app —
they live outside the Android filesystem entirely and must be written directly
to the raw block device.

The partition contains a **GNU tar archive** (no compression) holding all the
splash JPEG images. The module backs up the original, then writes your custom
`up_param.bin` to the partition and reapplies it on every boot for persistence.

---

## First device with up_param

The `up_param` partition with the tar-of-JPEGs format was introduced with the
**Samsung Galaxy S6 (SM-G920F / SM-G920T)** released in **April 2015**.

Every Samsung flagship and mid-range device from the S6 onward uses the same
format: S7, S8, S9, S10, S20, S21, S22, S23, S24, Note 5 through Note 20,
A-series (A50 and later), M-series, and more.

> **Note:** On very early devices (pre-S6), Samsung used a raw bitmap or a
> different partition layout. If the module says "up_param partition not found",
> your device pre-dates this system.

---

## Download up_param.bin from SamFW

> **Which file?** The `up_param.bin` lives inside the **AP (Application
> Processor)** file — sometimes called the **PDA** file. It is **NOT** inside
> BL (Bootloader), CP (Modem/Baseband), or CSC files.

### Steps

1. **Go to [samfw.com](https://samfw.com)**
   (free, no account required for most regions — just wait out the timer).

2. **Enter your model number**, e.g. `SM-G991B`, `SM-A546E`, `SM-S918B`.
   Find yours at *Settings → About phone → Model number*.

3. **Select your region/CSC** from the dropdown (match your SIM region —
   e.g. `XFA` = Australia, `DBT` = Germany, `BTU` = UK, `XAA` = USA,
   `INS` = India, `SER` = Philippines).

4. **Click Download** on the latest firmware.

5. **The firmware ZIP contains 4–5 files:**
   ```
   AP_SM-XXXXX_XXXXX_XXXXX.tar.md5   ← ✅ Contains up_param.bin — download this
   BL_SM-XXXXX_XXXXX.tar.md5          ✗ Bootloader — skip
   CP_SM-XXXXX_XXXXX.tar.md5          ✗ Modem — skip
   CSC_OMC_SM-XXXXX_XXXXX.tar.md5     ✗ CSC — skip
   HOME_CSC_OMC_SM-XXXXX_XXXXX.tar.md5 ✗ CSC — skip
   ```

6. **You only need to download the AP file.** It is large (3–5 GB).

7. The AP file is a `.tar.md5` archive. Inside it is `up_param.bin`.

---

## Extract up_param.bin on Android (free)

You need to pull `up_param.bin` out of the AP `.tar.md5` — all on your phone,
no PC needed.

### ZArchiver

**ZArchiver** is a free app available on
[Google Play](https://play.google.com/store/apps/details?id=ru.zdevs.zarchiver).

1. Download the AP file to your phone (e.g. `/sdcard/Download/`).
2. Open ZArchiver → navigate to your Downloads folder.
3. **Long-press** the AP `.tar.md5` file → tap **"Open as archive"**.
4. Wait for the file list to load (the AP file is large — be patient).
5. Find **`up_param.bin`** in the list (you can scroll or search).
6. Long-press it → **"Extract to..."** → pick a folder, e.g. `/sdcard/up_param/`.
7. You now have your `up_param.bin`.

---

## Edit & repack up_param.bin

`up_param.bin` is a **plain GNU tar archive** of JPEG files with no compression.
You can extract it, replace the images, and repack it.

### Step 1 — Extract the images

**ZArchiver:** Long-press `up_param.bin` → "Open as archive" → extract all to
a folder (e.g. `/sdcard/my_splash/`).

**Termux:**
```bash
mkdir -p /sdcard/my_splash
tar -xf /sdcard/up_param.bin -C /sdcard/my_splash
ls /sdcard/my_splash
```

---

### Step 2 — Replace the images

Edit whichever images you want with any photo editor
(**Snapseed**, **Adobe Lightroom Mobile**, **PixelLab**, etc.).

**Rules:**
- Save as **JPEG** (`.jpg`). Not PNG, not WEBP.
- Keep the **exact original filename** (`logo.jpg`, `android_logo.jpg`, etc.).
- The image dimensions should match your device's screen resolution
  (check the originals with a gallery app — usually 1080×2400 or similar).

The most important file is **`logo.jpg`** — this is the main power-on splash.

---

### Step 3 — Repack into up_param.bin

#### ZArchiver

1. Navigate to `/sdcard/my_splash/`.
2. **Select all** JPEG files (long-press first, then tick the rest).
3. Tap the **archive/compress** button.
4. Set format to **TAR** (no compression — scroll the format list to find it).
5. Name it `up_param_new`.
6. Tap **OK**. ZArchiver creates `up_param_new.tar`.
7. **Long-press** `up_param_new.tar` → **Rename** → change to `up_param_new.bin`.
   (Tap OK on the extension warning.)

#### Termux (most reliable)

```bash
cd /sdcard/my_splash
tar -cf /sdcard/up_param_new.bin *.jpg

# Verify it
tar -tf /sdcard/up_param_new.bin
```

---

## Flash methods

You have four ways to flash your custom `up_param.bin`. Pick whichever suits you.

---

### Method 1 — Magisk module (recommended)

This module flashes your `up_param.bin` at install time and reapplies it on
every boot for persistence (survives OTAs, factory resets, etc.).

**How to use this module:**

1. **Place your `up_param.bin`** inside the module zip at:
   ```
   my_own_splash_screen/
   └── up_param/
       └── up_param.bin   ← your file goes here
   ```
   Open the module zip with ZArchiver, navigate to `up_param/`,
   and paste your `up_param.bin` there. Save the zip.

2. Open **Magisk app** → **Modules** → **Install from storage**.

3. Select the module zip.

4. The installer will:
   - Validate your `up_param.bin` is a real tar archive
   - Back up the original splash (mandatory — aborts if backup fails)
   - Check your file fits in the partition
   - Write your custom splash with `dd`
   - Set up auto-reapply on every boot

5. **Reboot** — your custom splash appears immediately.

**Flash via TWRP (if Magisk app fails):**

Boot TWRP → Install → Install Zip → select the module → swipe to flash.
TWRP has broader block device write permissions and often works when
in-system flashing does not.

**Requirements:**
- Magisk v24+, Apatch (or KernelSU with ZygiskNext)
- Android 9 or later
- Samsung device with up_param partition (Galaxy S6 and later)
- Root access granted to the Magisk installer

---

### Method 2 — Termux / ADB shell (dd)

The fastest one-shot method. No module, no app — just raw `dd`.
Does **not** persist across OTAs (run again after any firmware update).

**In Termux (requires root):**

```bash
# Install Termux from F-Droid (NOT the Play Store version — it's outdated)
# https://f-droid.org/packages/com.termux/

# Put up_param.bin to internal storage, not in any folder
# Grant root to Termux, then:
su
dd if=/sdcard/up_param.bin of=/dev/block/by-name/up_param bs=4096
```

If `/dev/block/by-name/up_param` doesn't work, try:
```bash
dd if=/sdcard/up_param.bin of=/dev/block/bootdevice/by-name/up_param bs=4096
```

Find the real path with:
```bash
ls -la /dev/block/by-name/ | grep -i up_param
```

**Via ADB (from PC):**

```bash
adb push up_param.bin /sdcard/
adb shell
su
dd if=/sdcard/up_param.bin of=/dev/block/by-name/up_param bs=4096
```

Reboot after the `dd` command completes.

---

## Image reference

| Filename | What it shows |
|---|---|
| `logo.jpg` | **Main boot splash** — shown when powering on |
| `android_logo.jpg` | "Powered by Android" logo at first boot / factory reset |
| `lpm.jpg` | Charging screen background (Low Power Mode) |
| `setting_logo.jpg` | Shown in recovery and settings menus |
| `device_lock.jpg` | Knox: device is Knox-locked (orange state) |
| `device_unlock.jpg` | Knox: device Knox-unlocked |
| `download.jpg` | Download / Odin mode background |
| `download_error.jpg` | Download mode error screen |
| `secure_error.jpg` | Secure boot failure screen |
| `warning.jpg` | "Custom binary blocked" / root warning |
| `warning_svb.jpg` | Secure Boot Verification warning |
| `letter.jpg` | Letter / notification image |
| `SUD_0.jpg` … `SUD_10.jpg` | Shutdown animation frames (0 = first, 10 = last) |

---

## Troubleshooting

**Q: The splash didn't change after reboot.**
A: Try Method 2 (Termux `dd`) to confirm your `up_param.bin` is valid.
   If that works, reflash the module from TWRP instead of the Magisk app.

**Q: Installer says "up_param partition NOT found".**
A: Your device might use a different path. Check with:
   ```bash
   adb shell su -c "ls -la /dev/block/by-name/ | grep -i up"
   ```
   If no result, your device may not use up_param at all.

**Q: "up_param.bin is not a valid tar archive".**
A: You may have named the wrong file, or the repack step failed. Verify with:
   ```bash
   tar -tf /sdcard/up_param.bin
   # Should list: logo.jpg, android_logo.jpg, etc.
   ```

**Q: The image looks garbled / wrong colors.**
A: Make sure your JPEG is saved as standard JPEG (not progressive JPEG).
   In Snapseed: Export → Save → JPEG. In Lightroom: Share → Export as JPEG.

**Q: Will this survive OTA updates?**
A: The module re-applies the splash on every boot via `post-fs-data.sh` and
   `service.sh`. However, some OTAs rewrite the up_param partition directly —
   reflash the module after any major firmware update to be safe.

**Q: Does this trip Knox?**
A: **No.** Writing to `up_param` does **not** trip Knox. Knox eFuse is blown
   only by unlocking the bootloader — not by writing to up_param.

**Q: KernelSU support?**
A: Yes — install via KernelSU's module manager. The scripts use standard shell
   and `dd`, which work under KernelSU with ZygiskNext.

---

## Restore original splash

### Method 1 — Uninstall the module + restore script

```bash
# In Termux (as root) or ADB shell:
su
sh /data/adb/modules/my_own_splash_screen/tools/restore_up_param.sh
reboot
```

This writes the original backup back to the partition.

### Method 2 — Manual dd

```bash
su
dd if=/data/adb/samsung_splash_backup/up_param_original.bin \
   of=/dev/block/by-name/up_param bs=4096
reboot
```

---

## Credits

- Approach inspired by **Oh My Font** Magisk module.
- Module by **sofikuw**.
