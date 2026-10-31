# MOSS – My Own Splash Screen

**by sofikuw**

Change the Samsung boot splash, charging screen, download-mode screen and
other pre-boot images by writing your own `up_param.bin` to the `up_param`
partition.

MOSS works as a **Magisk / KernelSU / APatch module** and as a **standalone
flashable ZIP** for TWRP-based custom recoveries.

---

## Compatibility

| Install method | Supported |
|---|---|
| Magisk app / KernelSU / APatch manager | Yes |
| TWRP, OrangeFox, Pitch Black Recovery, SHRP (TWRP-based) | Yes |
| Other recoveries that run `META-INF/com/google/android/update-binary` | Usually |
| LineageOS Recovery / AOSP Recovery | No third-party ZIPs — signed OTAs only |
| Stock Samsung recovery | No |
| Samsung Exynos devices with an `up_param` partition | Yes |
| Samsung Snapdragon devices | Not supported (see below) |

A **TWRP-based recovery** can flash this ZIP even if the phone is not rooted.
In that case the splash is written once and the restore backup is saved to
internal storage, an SD card, or `/data/adb/` when available. Persistence
across firmware updates requires a root manager
(Magisk, KernelSU or APatch) so the boot scripts can run.

> **LineageOS Recovery cannot flash arbitrary ZIPs.** It verifies the package
> signature and only accepts LineageOS-signed OTA packages. This is a recovery
> design limitation, not a MOSS bug. Use a TWRP-based recovery, the root
> manager app, or the Termux `dd` method instead.

---

## Qualcomm (Snapdragon) devices

**This module is intended for Samsung Exynos devices only.**

On many Snapdragon Samsung devices the `up_param` partition exists but is
protected or validated by the bootloader. A write can be rejected, or it can
appear to succeed and be ignored on the next boot.

Reported affected models include US/Canadian Snapdragon variants such as
`SM-...U`, `SM-...W`, `SM-...T` and some `SM-...V` models, plus Snapdragon
A-series devices.

If your device reports a Samsung Exynos SoC, you are in the supported group.

---

## Table of contents

1. [What is up_param?](#what-is-up_param)
2. [First devices with up_param](#first-devices-with-up_param)
3. [Get your up_param.bin](#get-your-up_parambin)
   - [Method A — Copy it from your device](#method-a--copy-it-from-your-device-easiest)
   - [Method B — Download from LineageOS](#method-b--download-from-lineageos)
   - [Method C — Download from SamFW](#method-c--download-from-samfw)
4. [Extract & edit the images](#extract--edit-the-images)
5. [Repack into up_param.bin](#repack-into-up_parambin)
6. [Flash methods](#flash-methods)
   - [Method 1 — Flash the ZIP in recovery](#method-1--flash-the-zip-in-recovery)
   - [Method 2 — Install from a root manager](#method-2--install-from-a-root-manager)
   - [Method 3 — Termux dd (one-shot)](#method-3--termux-dd-one-shot)
7. [How MOSS protects the partition](#how-moss-protects-the-partition)
8. [Image reference](#image-reference)
9. [Troubleshooting](#troubleshooting)
10. [Restore the original splash](#restore-the-original-splash)
11. [Credits](#credits)
12. [License](#license)

---

## What is up_param?

`up_param` is a small dedicated partition on Samsung Exynos devices. It stores
the pre-boot splash/logo images shown by the bootloader **before Android
starts**. These images live outside the Android filesystem and must be written
directly to the raw block device.

The partition contains an **uncompressed tar archive** holding the splash JPEG
images. The archive is usually named `up_param.bin` when extracted from Samsung
firmware.

MOSS backs up the original partition, writes your custom archive, and (when a
root manager is installed) restores the custom splash if the partition is
overwritten later.

---

## First devices with up_param

The tar-of-JPEGs `up_param` format was introduced with the **Samsung Galaxy S6
(SM-G920F / SM-G920T)** in **April 2015**.

Many Exynos Samsung devices from the S6 onward use the same format, including
S7, S8, S9, S10, S20, S21, S22, S23, S24, Note 5 through Note 20, and various
A-series and M-series models. Availability and format can vary by model and
firmware, so always keep a backup.

---

## Get your up_param.bin

### Method A — Copy it from your device (easiest)

This gives you the exact `up_param` for your device with no guesswork.

**In Termux** (install from [F-Droid](https://f-droid.org/packages/com.termux/),
not the Play Store):

```bash
su
dd if=/dev/block/by-name/up_param of=/sdcard/up_param.bin bs=4096
```

If that path does not exist, find the real one:

```bash
su
ls -la /dev/block/by-name/ | grep -i up_param
```

Then use the path it shows, for example:

```bash
dd if=/dev/block/bootdevice/by-name/up_param of=/sdcard/up_param.bin bs=4096
```

**If you get "Permission denied":**

```bash
su
setenforce 0
dd if=/dev/block/by-name/up_param of=/sdcard/up_param.bin bs=4096
setenforce 1
```

Or write to internal storage if `/sdcard` is blocked:

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

Verify it worked. You should see the JPEG filenames:

```bash
tar -tf /sdcard/up_param.bin
```

---

### Method B — Download from LineageOS

Use this if you do not want to download a 5 GB+ AP file.

1. Go to **[wiki.lineageos.org/devices/](https://wiki.lineageos.org/devices/)**.
2. Enter your model number (for example `SM-G991B`). You can find it in
   *Settings → About phone → Model number*.
3. Open the guide for your device → **Update to a newer vendor firmware** →
   choose your model number.
4. Download the file. It is much smaller than a full firmware package.
5. The file contains `up_param.bin`.

---

### Method C — Download from SamFW

1. Go to **[samfw.com](https://samfw.com)** (free, no account needed).
2. Enter your model number (for example `SM-G991B`).
3. Select your region/CSC (for example `DBT`, `BTU`, `INS`, `XFA`, `SER`).
4. Download the **AP** file only — it ends in `AP_*.tar.md5`.
5. `up_param.bin` is inside the AP file. It is **not** in BL, CP or CSC.

**Extract with ZArchiver:**

1. Long-press the AP `.tar.md5` → **Open as archive**.
2. Find `up_param.bin` → long-press → **Extract to...** → choose
   `/sdcard/up_param/`.

**Extract with MiXplorer:**

1. Long-press the AP file → **Open as** → **Archive**.
2. Find `up_param.bin` → long-press → **Copy** → paste into your folder.

---

## Extract & edit the images

**ZArchiver:** long-press `up_param.bin` → **Open as archive** → extract all
files to a folder such as `/sdcard/my_splash/`.

**MiXplorer:** long-press → **Open as** → **Archive** → select all → copy →
paste into a folder.

**Termux:**

```bash
mkdir -p /sdcard/my_splash
tar -xf /sdcard/up_param.bin -C /sdcard/my_splash
ls /sdcard/my_splash
```

Now edit whichever images you want. The most important is **`logo.jpg`** — the
main power-on splash.

**Image rules:**

- Use **JPEG** (`.jpg`). Not PNG or WEBP.
- Keep the **exact original filename**.
- Match your device's screen resolution. Check the originals in a gallery app;
  common sizes are 1080×2340 and 1080×2400.
- Do not put the images in subfolders inside the tar. They must be at the root
  of the archive.
- Use standard/baseline JPEG, not progressive JPEG.

Recommended editors: **Snapseed**, **Adobe Lightroom Mobile**, **PixelLab**.

---

## Repack into up_param.bin

You can use the included helper, which writes a proper uncompressed tar and
verifies it:

```bash
sh tools/pack_up_param.sh /sdcard/my_splash /sdcard/up_param_new.bin
```

### ZArchiver

1. Open ZArchiver → navigate to `/sdcard/my_splash/`.
2. Select all JPEG files.
3. Tap **compress**.
4. Set format to **TAR** (no compression).
5. Name it `up_param` → OK.
6. Long-press `up_param.tar` → **Rename** → `up_param.bin`.

### MiXplorer

1. Navigate to `/sdcard/my_splash/` → select all JPEGs.
2. **⋮ menu → Compress / Pack** → format **TAR** → name `up_param`.
3. Rename `up_param.tar` → `up_param.bin`.

### Termux (most reliable)

```bash
cd /sdcard/my_splash
tar -cf /sdcard/up_param_new.bin *.jpg
tar -tf /sdcard/up_param_new.bin
```

---

## Flash methods

### Method 1 — Flash the ZIP in recovery

This is the recommended method when the device is not rooted or when the
manager app reports a write failure.

1. Open the MOSS ZIP with ZArchiver or MiXplorer.
2. Navigate to `up_param/` inside the ZIP.
3. Add your file as `up_param/up_param.bin`.
4. Save the ZIP.
5. Boot into a **TWRP-based recovery** (TWRP, OrangeFox, PBRP, SHRP).
6. If your `/data` is encrypted, decrypt it first so the module can be updated.
7. **Install → select the ZIP → swipe to flash**.
8. Reboot.

What the installer does:

- Detects the `up_param` block device.
- Takes a mandatory backup and aborts if the backup is invalid.
- Validates the payload as an uncompressed tar archive.
- Writes and reads back the partition to verify it.
- Restores the original automatically if the write fails.
- Installs the boot-time persistence module when a root manager is present.
- Saves a restore copy to `/sdcard/MOSS/` when that storage is writable.

If no root manager is detected, MOSS runs in **standalone recovery mode**: the
splash is written once, and `/sdcard/MOSS/restore.sh` can restore the original
when internal storage or an SD card is mounted. Reflash after a firmware
update, because no boot script is installed.

> If a previous MOSS module is already installed and `/data` is encrypted, the
> recovery cannot update the module. Boot Android once and install the ZIP from
> the manager app instead, or decrypt `/data` in recovery.

---

### Method 2 — Install from a root manager

1. Add `up_param/up_param.bin` to the ZIP as described above.
2. Open **Magisk**, **KernelSU**, or **APatch**.
3. Go to **Modules → Install from storage**.
4. Select the ZIP and reboot.

The module stores the custom payload at
`/data/adb/modules/my_own_splash_screen/up_param/up_param.bin` and re-applies it
at boot **only when the partition content differs**, avoiding unnecessary
writes.

KernelSU and APatch do not need ZygiskNext for this module.

---

### Method 3 — Termux dd (one-shot)

No module needed. This does not persist across firmware updates.

```bash
su
dd if=/sdcard/up_param.bin of=/dev/block/by-name/up_param bs=4096
sync
reboot
```

If the path does not exist, use the path found by
`ls /dev/block/by-name/ | grep -i up_param`.

---

## How MOSS protects the partition

- **Backup first:** the original partition is dumped before anything is written.
  If the backup cannot be created or validated, the install aborts. On
  reinstall, a valid backup from any known location is reused instead of
  capturing the current partition again.
- **Payload validation:** the new file must be a readable tar archive, and it
  must not be larger than the partition.
- **Read-back verification:** after writing, MOSS reads the partition back and
  compares it with the payload.
- **Automatic rollback:** if the write or verification fails, MOSS tries to write
  the backup back immediately.
- **No needless writes:** at boot, the module compares the partition with the
  custom payload and skips the write when they already match.
- **Safe uninstall:** `uninstall.sh` restores the original splash only when the
  partition still contains the module's custom payload.

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

**Splash did not change after reboot**

- Flash from a TWRP-based recovery instead of the manager app.
- Check that `up_param.bin` is a valid tar: `tar -tf up_param.bin`.
- Make sure the ZIP contains `up_param/up_param.bin`.

**"up_param partition not found"**

```bash
adb shell su -c "ls /dev/block/by-name/ | grep -i up_param"
```

Your device may use a different path or may not have the partition.

**"Permission denied" on dd**

- Grant root to Termux in the manager app.
- Try `setenforce 0` before the dd command.
- Write the dump to `/data/local/tmp/` instead of `/sdcard/`.
- Use `adb root` from a PC as a fallback.

**"Write failed" during install**

- Let MOSS restore the backup, then flash the ZIP from a TWRP-based recovery.
- Decrypt `/data` in recovery so the module can be updated.
- If you previously installed MOSS as a module, boot Android once and reinstall
  from the manager app.

**"No writable location for the mandatory backup"**

- In recovery, mount **Data** and **Internal Storage**.
- Make sure `/sdcard` is accessible.

**Image looks garbled**

- Save as standard JPEG (not progressive).
- Match your device's resolution.
- Keep the original filename and do not use subfolders in the tar.

**Does this trip Knox?**

Writing `up_param` through root does not usually trip Knox. Unlocking the
bootloader can trip Knox independently. Check your model's warranty rules.

**LineageOS Recovery says the ZIP signature is invalid**

LineageOS Recovery only installs its own signed OTA packages. Use a
TWRP-based recovery, the root manager app, or the Termux dd method.

---

## Restore the original splash

The original is backed up during installation. Possible locations:

- `/data/adb/samsung_splash_backup/up_param_original.bin`
- `/sdcard/MOSS/up_param_original.bin`
- `/sdcard/MOSS/backup/up_param_original.bin`
- `/external_sd/MOSS/...`, `/sdcard1/MOSS/...`, or `/usb-otg/MOSS/...`
- `/tmp/MOSS/backup/up_param_original.bin` (temporary)

**Restore with the included script:**

```bash
su
sh /data/adb/modules/my_own_splash_screen/tools/restore_up_param.sh
reboot
```

If you used standalone recovery mode, the script is copied to
`/sdcard/MOSS/restore.sh`:

```bash
su
sh /sdcard/MOSS/restore.sh
reboot
```

You can also pass a backup path explicitly:

```bash
sh /sdcard/MOSS/restore.sh /sdcard/MOSS/up_param_original.bin
```

If no persistent storage was mounted during installation, the backup is in
`/tmp/MOSS/backup` only until reboot. In that case, extract
`tools/restore_up_param.sh` from the ZIP and keep your own copy of the original
partition dump.

**Or restore manually:**

```bash
su
dd if=/sdcard/MOSS/up_param_original.bin \
   of=/dev/block/by-name/up_param bs=4096
sync
reboot
```

**Uninstalling the module:** removes boot-time re-application and restores the
original splash if the partition still contains the module's custom payload.
A factory reset also removes the module and the `/data` backup, so keep the
`/sdcard/MOSS/` copy if you may need it later.

---

## Credits

- Inspired by the **Oh My Font** Magisk module approach
- `up_param` format first introduced on the Samsung Galaxy S6 (April 2015)
- Module by **sofikuw**

---

## License

GPL-3.0. See [LICENSE](LICENSE).

---

*Disclaimer: Not responsible for any damage. Always keep a backup. Exynos only.
Flash at your own risk.*
