# My Own Splash Screen – Magisk Module

**by sofikuw**

Change the Samsung boot splash screen, charging screen, download mode screen,
and more — by flashing your own `up_param.bin` directly to the `up_param`
partition. Works on **Stock ROM** and **Custom ROMs** (LineageOS, crDroid,
AOSP-based, etc.) on **Exynos** Samsung devices.

---

## ⚠️ Qualcomm (Snapdragon) Devices — Read This First

**This module does NOT work on Qualcomm Snapdragon Samsung devices.**

On Snapdragon Samsung devices, the bootloader is locked down by Qualcomm's
Secure Boot implementation and does not allow writing to the `up_param`
partition from Android, even with root. The `dd` command will either return
"Permission denied" or appear to succeed but the splash will not change on
reboot — Qualcomm's bootloader validates and ignores any modified partition.

**Affected devices include:**
- Galaxy S21 / S22 / S23 / S24 (Snapdragon variants — SM-G/S **U**, **W**, **T**, **V** suffix)
- Galaxy A-series with Snapdragon (e.g. A53 5G SM-A536U)
- Any Samsung sold in the **USA or Canada** (almost always Snapdragon)

**Exynos variants (Europe, Latin America, Asia — non-USA) work fine.**

Check your SoC If it says Samsung Exynos → you're good to go.

---

## Table of Contents

1. [What is up_param?](#what-is-up_param)
2. [First device that used up_param](#first-device-with-up_param)
3. [Get your up_param.bin](#get-your-up_parambin)
   - [Method A — Copy directly from your device (easiest)](#method-a--copy-directly-from-your-device-easiest)
   - [Method B — Download from Linageos](#method-b--download-from-lineageos)
   - [Method C — Download from SamFW](#method-c--download-from-samfw)
4. [Extract & edit the images](#extract--edit-the-images)
5. [Repack into up_param.bin](#repack-into-up_parambin)
6. [Flash methods](#flash-methods)
   - [Method 1 — Magisk module (this module)](#method-1--magisk-module-recommended)
   - [Method 2 — Termux dd (one-shot)](#method-2--termux-dd-one-shot)
7. [Image reference](#image-reference)
8. [Troubleshooting](#troubleshooting)
9. [Restore original splash](#restore-original-splash)

---

## What is up_param?

`up_param` is a small dedicated partition on Samsung devices (around 8–16 MB).
It stores the pre-boot splash/logo images that the bootloader shows **before
Android even starts**. These images live entirely outside the Android
filesystem and must be written directly to the raw block device.

The partition contains a **GNU tar archive** (no compression) holding all the
splash JPEG images. This module backs up the original, writes your custom
`up_param.bin`, and reapplies it on every boot for persistence.

---

## First device with up_param

The `up_param` partition with the tar-of-JPEGs format was introduced with the
**Samsung Galaxy S6 (SM-G920F / SM-G920T)** released in **April 2015**.

All Samsung flagship and mid-range Exynos devices from the S6 onward use the
same format: S7, S8, S9, S10, S20, S21, S22, S23, S24, Note 5 through
Note 20, A-series (A50 and later), M-series, and more — **on Exynos only**.

---

## Get your up_param.bin

### Method A — Copy directly from your device (easiest)

No PC, Read it straight off your own
device's partition with root. This gives you the exact up_param for your
device with zero guesswork.

**In Termux (install from [F-Droid](https://f-droid.org/packages/com.termux/) — NOT Play Store):**

```bash
su
dd if=/dev/block/by-name/up_param of=/sdcard/up_param.bin bs=4096
```

If that path doesn't exist, find the real one first:
```bash
su
ls -la /dev/block/by-name/ | grep -i up_param
```
Then use whatever path it shows, for example:
```bash
dd if=/dev/block/bootdevice/by-name/up_param of=/sdcard/up_param.bin bs=4096
```

**If you get "Permission denied":**
```bash
# Make sure Termux is granted root, then:
su
setenforce 0
dd if=/dev/block/by-name/up_param of=/sdcard/up_param.bin bs=4096
setenforce 1
```

Or write to internal storage if /sdcard is blocked:
```bash
su
dd if=/dev/block/by-name/up_param of=/data/local/tmp/up_param.bin bs=4096
exit
cp /data/local/tmp/up_param.bin /sdcard/up_param.bin
```

**Via ADB from a PC:**
```bash
adb root
adb shell dd if=/dev/block/by-name/up_param of=/sdcard/up_param.bin bs=4096
adb pull /sdcard/up_param.bin
```

Verify it worked — you should see the list of JPEG filenames:
```bash
tar -tf /sdcard/up_param.bin
```

---

### Method B — Download from Lineageos

Use this if you don't want download a 5GB+ AP file.

1. Go to **[wiki.lineageos.org/devices/](https://wiki.lineageos.org/devices/)** .
2. Enter your model number (e.g. `SM-G991B`). Find it at
   *Settings → About phone → Model number*.
3. Go to guides → Update to a newer vendor firmware → Choose your model number.
4. Download the File.
   It is small (60–120MB).
5. The file contains `up_param.bin` inside it.

---

### Method C — Download from SamFW

Use this if you don't have root yet, or want a clean stock up_param from a
specific firmware version.

> **Which file?** The `up_param.bin` lives inside the **AP (Application
> Processor)** file. It is **NOT** inside BL, CP, or CSC.

1. Go to **[samfw.com](https://samfw.com)** (free, no account needed).
2. Enter your model number (e.g. `SM-G991B`). Find it at
   *Settings → About phone → Model number*.
3. Select your region/CSC (e.g. `DBT` = Germany, `BTU` = UK, `INS` = India,
   `XFA` = Australia, `SER` = Philippines).
4. Download the **AP file** only — it ends in `AP_*.tar.md5`.
   It is large (3–5 GB).
5. The AP file contains `up_param.bin` inside it.

**Extract up_param.bin from the AP file (ZArchiver):**
1. Long-press the AP `.tar.md5` → **"Open as archive"**.
2. Find `up_param.bin` → long-press → **"Extract to..."**
   → pick a folder like `/sdcard/up_param/`.

**Extract with MiXplorer:**
1. Long-press the AP file → **"Open as"** → **"Archive"**.
2. Find `up_param.bin` → long-press → **"Copy"** → paste to your folder.

---

## Extract & edit the images

Once you have `up_param.bin`, extract the images from it:

**ZArchiver:** Long-press `up_param.bin` → "Open as archive" → extract all
to a folder (e.g. `/sdcard/my_splash/`).

**MiXplorer:** Long-press → "Open as" → "Archive" → select all → copy → paste.

**Termux:**
```bash
mkdir -p /sdcard/my_splash
tar -xf /sdcard/up_param.bin -C /sdcard/my_splash
ls /sdcard/my_splash
```

Now edit whichever images you want. The most important is **`logo.jpg`** —
the main power-on splash.

**Image rules:**
- Must be **JPEG** format (`.jpg`). Not PNG, not WEBP.
- Keep the **exact original filename**.
- Match your device's screen resolution (check originals in a gallery app —
  usually 1080×2340, 1080×2400, or similar).

Recommended free editors: **Snapseed**, **Adobe Lightroom Mobile**,
**PixelLab**.

---

## Repack into up_param.bin

#### ZArchiver

1. Open ZArchiver → navigate to `/sdcard/my_splash/`.
2. Select all JPEG files (long-press first, then tick the rest).
3. Tap the **compress** button.
4. Set format to **TAR** (no compression — scroll the format list).
5. Name it `up_param` → tap OK.
6. Long-press `up_param.tar` → **Rename** → change to `up_param.bin`.

#### MiXplorer

1. Navigate to `/sdcard/my_splash/` → select all JPEGs.
2. **⋮ menu → Compress / Pack** → format: **TAR** → name: `up_param`.
3. Rename `up_param.tar` → `up_param.bin`.

#### Termux (most reliable)

```bash
cd /sdcard/my_splash
tar -cf /sdcard/up_param_new.bin *.jpg

# Verify
tar -tf /sdcard/up_param_new.bin
```

---

## Flash methods

### Method 1 — Magisk module (recommended)

Flashes at install time and reapplies on every boot — persists through OTAs.

1. Open the module zip with ZArchiver or MiXplorer.
2. Navigate to `up_param/` inside the zip.
3. Paste your `up_param.bin` there (replacing any existing file).
4. Save the zip.
5. **Magisk app** → Modules → Install from storage → select the zip → reboot.

**Or flash via TWRP** (recommended if Magisk app gives "dd write failed"):
Boot TWRP → Install → Install Zip → select the zip → swipe to flash → reboot.

The module automatically:
- Detects your up_param partition
- Takes a mandatory backup (aborts if backup fails — safe by design)
- Validates your bin before writing
- Reapplies on every boot via `post-fs-data.sh` and `service.sh`

---

### Method 2 — Termux dd (one-shot)

No module needed. Does not persist through OTAs — re-run after firmware updates.

```bash
su
dd if=/sdcard/up_param.bin of=/dev/block/by-name/up_param bs=4096
```

Reboot after the command completes.

---

## Image reference

| Filename | What it shows |
|---|---|
| `logo.jpg` | **Main boot splash** — shown when powering on |
| `android_logo.jpg` | "Powered by Android" at first boot / factory reset |
| `lpm.jpg` | Charging screen background (Low Power Mode) |
| `setting_logo.jpg` | Recovery / settings menu logo |
| `device_lock.jpg` | Knox: device is Knox-locked |
| `device_unlock.jpg` | Knox: device is Knox-unlocked |
| `download.jpg` | Download / Odin mode background |
| `download_error.jpg` | Download mode error screen |
| `secure_error.jpg` | Secure boot failure screen |
| `warning.jpg` | Custom binary / root warning |
| `warning_svb.jpg` | Secure Boot Verification warning |
| `letter.jpg` | Letter / notification image |
| `SUD_0.jpg` … `SUD_10.jpg` | Shutdown animation frames |

---

## Troubleshooting

**Splash didn't change after reboot**
→ Flash from TWRP instead of Magisk app.

**"up_param partition NOT found"**
→ Run: `adb shell su -c "ls /dev/block/by-name/ | grep -i up"`
→ Your device may use a different path or pre-date the S6.

**"Permission denied" on dd**
→ Grant Termux root in Magisk app → Superuser.
→ Try `setenforce 0` before the dd command.
→ Write to `/data/local/tmp/` instead of `/sdcard/`.
→ Use `adb root` from a PC as a fallback.

**"dd write failed" during module install**
→ Flash from TWRP recovery instead.

**Image looks garbled**
→ Save as standard JPEG (not progressive). Match your screen resolution.

**Does this trip Knox?**
→ No. Writing to `up_param` does NOT trip Knox. Knox eFuse is only blown by
unlocking the bootloader.

**KernelSU support?**
→ Yes — install via KernelSU's module manager with ZygiskNext.

---

## Restore original splash

Your original is automatically backed up during installation to:
`/data/adb/samsung_splash_backup/up_param_original.bin`

**Restore with the included script:**
```bash
su
sh /data/adb/modules/my_own_splash_screen/tools/restore_up_param.sh
reboot
```

**Or manually:**
```bash
su
dd if=/data/adb/samsung_splash_backup/up_param_original.bin \
   of=/dev/block/by-name/up_param bs=4096
reboot
```

**Or uninstall the module** (stops reapply but does not restore the partition):
Magisk app → Modules → trash icon next to *My Own Splash Screen* → reboot.

---

## Credits

- Inspired by the **Oh My Font** Magisk module approach
- `up_param` format first introduced on Samsung Galaxy S6 (April 2015)
- Module by **sofikuw**

---

*⚠️ Disclaimer: Not responsible for any damage. Always backup first. Exynos only — does not work on Qualcomm Snapdragon Samsung devices. Flash at your own risk.*
