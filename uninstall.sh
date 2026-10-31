#!/system/bin/sh
# Restores the original splash on module removal when the partition still
# contains the module's custom payload.

MODDIR="${0%/*}"
[ -d "$MODDIR" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/tools/common.sh" 2>/dev/null || exit 0

CUSTOM_BIN="$MODDIR/up_param/up_param.bin"
DEV_FILE="$MODDIR/up_param/device_path.txt"
BACKUP_DIR=""
[ -f "$MODDIR/up_param/backup_dir.txt" ] && BACKUP_DIR=$(tr -d '[:space:]' < "$MODDIR/up_param/backup_dir.txt")
[ -n "$BACKUP_DIR" ] || BACKUP_DIR="/data/adb/samsung_splash_backup"
ORIG_BIN="$BACKUP_DIR/up_param_original.bin"

rm -f "$MODDIR/.applied_this_boot" 2>/dev/null

[ -f "$CUSTOM_BIN" ] && [ -s "$CUSTOM_BIN" ] || exit 0
moss_is_tar "$CUSTOM_BIN" || exit 0
command -v cmp >/dev/null 2>&1 || exit 0

UP_PARAM_DEV=""
[ -f "$DEV_FILE" ] && UP_PARAM_DEV=$(tr -d '[:space:]' < "$DEV_FILE")
if [ -z "$UP_PARAM_DEV" ] || [ ! -b "$UP_PARAM_DEV" ]; then
  UP_PARAM_DEV=$(moss_find_up_param) || exit 0
fi
[ -n "$UP_PARAM_DEV" ] && [ -b "$UP_PARAM_DEV" ] || exit 0

_part_size=$(moss_part_size "$UP_PARAM_DEV")
_check_orig() {
  local f="$1" sz
  [ -f "$f" ] && [ -s "$f" ] || return 1
  moss_is_tar "$f" || return 1
  if [ "${_part_size:-0}" -gt 0 ] 2>/dev/null; then
    sz=$(wc -c < "$f" 2>/dev/null | tr -d ' \n')
    [ "$sz" = "$_part_size" ] || return 1
  fi
  return 0
}

_orig_ok=0
_check_orig "$ORIG_BIN" && _orig_ok=1
if [ "$_orig_ok" -eq 0 ]; then
  for ORIG_BIN in \
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
    if _check_orig "$ORIG_BIN"; then
      _orig_ok=1
      break
    fi
  done
fi
[ "$_orig_ok" -eq 1 ] || exit 0

moss_compare_prefix "$UP_PARAM_DEV" "$CUSTOM_BIN" || exit 0
mv -f "$CUSTOM_BIN" "$CUSTOM_BIN.removed" 2>/dev/null
moss_write_verified "$ORIG_BIN" "$UP_PARAM_DEV"
