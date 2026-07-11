#!/system/bin/sh
# =============================================================================
#  Samsung Splash Changer – post-fs-data.sh
#  Runs early in boot (post-fs-data stage, before Zygote).
#  Re-applies the custom splash so it persists across OTAs / factory resets.
# =============================================================================

MODDIR="${0%/*}"
CUSTOM_BIN="/data/adb/samsung_splash_backup/up_param_custom.bin"
DEV_PATH_FILE="$MODDIR/up_param/device_path.txt"
APPLIED_FLAG="/data/adb/samsung_splash_backup/.applied_this_boot"

# Remove stale per-boot flag from a previous boot
rm -f "$APPLIED_FLAG"

# No custom payload yet — module installed but no images provided
[ -f "$CUSTOM_BIN" ] && [ -s "$CUSTOM_BIN" ] || exit 0

# Read saved device path
UP_PARAM_DEV=""
if [ -f "$DEV_PATH_FILE" ]; then
  UP_PARAM_DEV=$(tr -d '[:space:]' < "$DEV_PATH_FILE")
fi

# Fallback detection if saved path is missing or stale
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

# Apply the custom splash
if dd if="$CUSTOM_BIN" of="$UP_PARAM_DEV" bs=4096 2>/dev/null; then
  # Set flag so service.sh knows post-fs-data already handled this boot
  touch "$APPLIED_FLAG"
fi
