#!/system/bin/sh
# Restores the original up_param backup. Run as root in Android or via
# "sh restore.sh" in recovery.

BACKUP=""
_check_backup() {
  local f="$1" sz
  [ -f "$f" ] || return 1
  if command -v tar >/dev/null 2>&1 && ! tar -tf "$f" >/dev/null 2>&1; then
    return 1
  fi
  if [ "${PART_SIZE:-0}" -gt 0 ] 2>/dev/null; then
    sz=$(wc -c < "$f" 2>/dev/null | tr -d ' \n')
    [ "$sz" = "$PART_SIZE" ] || return 1
  fi
  BACKUP="$f"
  return 0
}

find_backup() {
  local f
  if [ -n "${1:-}" ]; then
    _check_backup "$1" && return 0
    _check_backup "$1/up_param_original.bin" && return 0
  fi
  for f in \
      /data/adb/samsung_splash_backup/up_param_original.bin \
      /sdcard/MOSS/up_param_original.bin \
      /sdcard/MOSS/backup/up_param_original.bin \
      /external_sd/MOSS/up_param_original.bin \
      /external_sd/MOSS/backup/up_param_original.bin \
      /sdcard1/MOSS/up_param_original.bin \
      /sdcard1/MOSS/backup/up_param_original.bin \
      /usb-otg/MOSS/up_param_original.bin \
      /usb-otg/MOSS/backup/up_param_original.bin \
      /data/media/0/MOSS/up_param_original.bin \
      /data/media/0/MOSS/backup/up_param_original.bin \
      /tmp/MOSS/backup/up_param_original.bin; do
    _check_backup "$f" && return 0
  done
  return 1
}

find_dev() {
  local p name
  if [ -n "${MOSS_UP_PARAM_DEV:-}" ]; then
    printf '%s\n' "$MOSS_UP_PARAM_DEV"
    return 0
  fi
  for p in \
      /dev/block/by-name/up_param \
      /dev/block/bootdevice/by-name/up_param \
      /dev/block/platform/*/by-name/up_param \
      /dev/block/platform/*/*/by-name/up_param \
      /dev/block/platform/*/*/*/by-name/up_param \
      /dev/block/*/by-name/up_param; do
    [ -b "$p" ] && { printf '%s\n' "$p"; return 0; }
  done
  name=$(grep -i ' up_param$' /proc/partitions 2>/dev/null | awk '{print $NF}' | head -n 1)
  [ -n "$name" ] && [ -b "/dev/block/$name" ] && { printf '%s\n' "/dev/block/$name"; return 0; }
  return 1
}

UP_PARAM_DEV=$(find_dev) || {
  echo "up_param partition not found."
  exit 1
}

PART_SIZE=$(blockdev --getsize64 "$UP_PARAM_DEV" 2>/dev/null)
if [ -z "$PART_SIZE" ] || [ "${PART_SIZE:-0}" -le 0 ] 2>/dev/null; then
  PART_SIZE=$(blockdev --getsz "$UP_PARAM_DEV" 2>/dev/null)
  [ -n "$PART_SIZE" ] && PART_SIZE=$((PART_SIZE * 512))
fi

find_backup "$1" || {
  echo "No valid up_param_original.bin backup found."
  echo "Looked in /data/adb/samsung_splash_backup, internal storage, SD cards, and /tmp/MOSS/backup."
  exit 1
}

SIZE=$(wc -c < "$BACKUP" 2>/dev/null | tr -d ' \n')

echo "Restoring:"
echo "  Source: $BACKUP"
echo "  Target: $UP_PARAM_DEV"

blockdev --setrw "$UP_PARAM_DEV" >/dev/null 2>&1 || true
if dd if="$BACKUP" of="$UP_PARAM_DEV" bs=4096 conv=fsync 2>/dev/null || \
   dd if="$BACKUP" of="$UP_PARAM_DEV" bs=4096 2>/dev/null; then
  sync
  blockdev --flushbufs "$UP_PARAM_DEV" >/dev/null 2>&1 || true
  if command -v cmp >/dev/null 2>&1; then
    if [ -n "$SIZE" ] && cmp -n "$SIZE" "$UP_PARAM_DEV" "$BACKUP" >/dev/null 2>&1; then
      echo "Original splash restored and verified. Reboot to apply."
    elif [ -n "$SIZE" ] && dd if="$UP_PARAM_DEV" bs=4096 2>/dev/null | head -c "$SIZE" | cmp -s - "$BACKUP" 2>/dev/null; then
      echo "Original splash restored and verified. Reboot to apply."
    else
      echo "Restore finished, but read-back verification failed. Reboot and check."
    fi
  else
    echo "Original splash restored. Reboot to apply."
  fi
else
  echo "Restore failed. Try from a TWRP-based recovery."
  exit 1
fi
