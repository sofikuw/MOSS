#!/system/bin/sh
# =============================================================================
#  Samsung Splash Changer – service.sh
#  Runs post-boot (after Zygote). Safety-net reapply in case post-fs-data.sh
#  ran before the block device was ready (can happen on some custom ROMs).
# =============================================================================

MODDIR="${0%/*}"
CUSTOM_BIN="/data/adb/samsung_splash_backup/up_param_custom.bin"
DEV_PATH_FILE="$MODDIR/up_param/device_path.txt"
APPLIED_FLAG="/data/adb/samsung_splash_backup/.applied_this_boot"

# post-fs-data.sh already applied this boot → nothing to do
[ -f "$APPLIED_FLAG" ] && exit 0

# No custom payload yet
[ -f "$CUSTOM_BIN" ] && [ -s "$CUSTOM_BIN" ] || exit 0

# Read saved device path
UP_PARAM_DEV=""
if [ -f "$DEV_PATH_FILE" ]; then
  UP_PARAM_DEV=$(tr -d '[:space:]' < "$DEV_PATH_FILE")
fi

# Fallback detection
if [ -z "$UP_PARAM_DEV" ] || [ ! -b "$UP_PARAM_DEV" ]; then
  for p in /dev/block/by-name/up_param /dev/block/bootdevice/by-name/up_param; do
    [ -b "$p" ] && { UP_PARAM_DEV="$p"; break; }
  done
  if [ -z "$UP_PARAM_DEV" ]; then
    for p in /dev/block/platform/*/by-name/up_param; do
      [ -b "$p" ] && { UP_PARAM_DEV="$p"; break; }
    done
  fi
fi

[ -z "$UP_PARAM_DEV" ] && exit 0
[ -b "$UP_PARAM_DEV" ] || exit 0

# Wait for block device to become writable (up to 10 s; common on custom ROMs)
TRIES=0
while [ ! -w "$UP_PARAM_DEV" ] && [ "$TRIES" -lt 10 ]; do
  sleep 1
  TRIES=$((TRIES + 1))
done
[ -w "$UP_PARAM_DEV" ] || exit 0

# Apply the custom splash and set the boot flag
if dd if="$CUSTOM_BIN" of="$UP_PARAM_DEV" bs=4096 2>/dev/null; then
  touch "$APPLIED_FLAG"
fi
