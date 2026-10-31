#!/system/bin/sh
# MOSS install logic. Sourced by update-binary after extraction.

if [ -z "${MODPATH:-}" ]; then
  MODPATH=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
fi

if [ -f "$MODPATH/tools/common.sh" ]; then
  . "$MODPATH/tools/common.sh"
fi

command -v ui_print >/dev/null 2>&1 || ui_print() { printf '%s\n' "$1"; }
command -v set_perm >/dev/null 2>&1 || set_perm() {
  chown "$2:$3" "$1" 2>/dev/null
  chmod "$4" "$1" 2>/dev/null
}
command -v set_perm_recursive >/dev/null 2>&1 || set_perm_recursive() {
  chown -R "$2:$3" "$1" 2>/dev/null
  find "$1" -type d -exec chmod "$4" {} \; 2>/dev/null
  find "$1" -type f -exec chmod "$5" {} \; 2>/dev/null
}

_abort() {
  ui_print ""
  ui_print "! $1"
  ui_print ""
  exit 1
}

_pick_backup_dir() {
  local d
  if moss_is_mounted /data; then
    d="/data/adb/samsung_splash_backup"
    if mkdir -p "$d" 2>/dev/null && [ -w "$d" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  fi
  for d in \
      /sdcard/MOSS/backup \
      /external_sd/MOSS/backup \
      /sdcard1/MOSS/backup \
      /usb-otg/MOSS/backup \
      /data/media/0/MOSS/backup; do
    if moss_is_mounted "$(dirname "$(dirname "$d")")" && \
       mkdir -p "$d" 2>/dev/null && [ -w "$d" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  d="/tmp/MOSS/backup"
  if mkdir -p "$d" 2>/dev/null && [ -w "$d" ]; then
    printf '%s\n' "$d"
    return 0
  fi
  return 1
}

IS_MODULE=0
[ "${MOSS_TEMP:-0}" != "1" ] && IS_MODULE=1

ui_print ""
ui_print "======================================="
ui_print "  MOSS - My Own Splash Screen"
ui_print "  by sofikuw"
ui_print "======================================="
ui_print ""

NEW_BIN="$MODPATH/up_param/up_param.bin"
[ -f "$NEW_BIN" ] || NEW_BIN="$MODPATH/up_param.bin"
if [ ! -f "$NEW_BIN" ] || [ ! -s "$NEW_BIN" ]; then
  _abort "up_param.bin not found. Put it at up_param/up_param.bin inside the ZIP and reflash."
fi

if ! moss_is_tar "$NEW_BIN"; then
  _abort "up_param.bin is not a valid tar archive. Repack it as an uncompressed TAR (see README)."
fi

NEW_SIZE=$(wc -c < "$NEW_BIN" 2>/dev/null | tr -d ' \n')
[ -n "$NEW_SIZE" ] && [ "$NEW_SIZE" -gt 0 ] 2>/dev/null || _abort "Cannot read up_param.bin size."
ui_print "- Payload: $NEW_SIZE bytes"

UP_PARAM_DEV=$(moss_find_up_param)
if [ -z "$UP_PARAM_DEV" ] || [ ! -b "$UP_PARAM_DEV" ]; then
  _abort "up_param partition not found. This module is for Samsung Exynos devices with an up_param partition."
fi
ui_print "- Partition: $UP_PARAM_DEV"

PART_SIZE=$(moss_part_size "$UP_PARAM_DEV")
ui_print "- Partition size: ${PART_SIZE:-0} bytes"
if [ "${PART_SIZE:-0}" -gt 0 ] 2>/dev/null && [ "$NEW_SIZE" -gt "$PART_SIZE" ] 2>/dev/null; then
  _abort "up_param.bin ($NEW_SIZE bytes) is larger than the partition ($PART_SIZE bytes)."
fi

BACKUP_DIR=$(_pick_backup_dir)
[ -n "$BACKUP_DIR" ] || _abort "No writable location for the mandatory backup. Mount /data, internal storage, or an SD card and retry."
case "$BACKUP_DIR" in
  /tmp/*) ui_print "! Warning: no persistent storage is mounted; the backup is temporary." ;;
esac

_find_original_backup() {
  local f sz
  for f in \
      "$BACKUP_DIR/up_param_original.bin" \
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
    [ -f "$f" ] && [ -s "$f" ] || continue
    moss_is_tar "$f" || continue
    if [ "${PART_SIZE:-0}" -gt 0 ] 2>/dev/null; then
      sz=$(wc -c < "$f" 2>/dev/null | tr -d ' \n')
      [ "$sz" = "$PART_SIZE" ] || continue
    fi
    printf '%s\n' "$f"
    return 0
  done
  return 1
}

_part_matches_known_custom() {
  local f
  for f in \
      "$BACKUP_DIR/up_param_custom.bin" \
      /data/adb/samsung_splash_backup/up_param_custom.bin \
      /sdcard/MOSS/up_param_custom.bin \
      /sdcard/MOSS/backup/up_param_custom.bin \
      /external_sd/MOSS/up_param_custom.bin \
      /external_sd/MOSS/backup/up_param_custom.bin \
      /sdcard1/MOSS/up_param_custom.bin \
      /sdcard1/MOSS/backup/up_param_custom.bin \
      /usb-otg/MOSS/up_param_custom.bin \
      /usb-otg/MOSS/backup/up_param_custom.bin \
      /data/media/0/MOSS/up_param_custom.bin \
      /data/media/0/MOSS/backup/up_param_custom.bin \
      /tmp/MOSS/backup/up_param_custom.bin; do
    [ -f "$f" ] || continue
    moss_compare_prefix "$UP_PARAM_DEV" "$f" && return 0
  done
  return 1
}

BACKUP_FILE="$BACKUP_DIR/up_param_original.bin"
BACKUP_OK=0
EXISTING_BACKUP=$(_find_original_backup) || EXISTING_BACKUP=""
if [ -n "$EXISTING_BACKUP" ]; then
  BACKUP_OK=1
  if [ "$EXISTING_BACKUP" != "$BACKUP_FILE" ]; then
    if cp -f "$EXISTING_BACKUP" "$BACKUP_FILE" 2>/dev/null; then
      chmod 0600 "$BACKUP_FILE" 2>/dev/null
    else
      BACKUP_DIR=$(dirname "$EXISTING_BACKUP")
      BACKUP_FILE="$EXISTING_BACKUP"
    fi
  fi
  ui_print "- Using existing backup: $EXISTING_BACKUP"
fi

SKIP_WRITE=0
if [ "$BACKUP_OK" -eq 0 ]; then
  PART_EQ_NEW=0
  moss_compare_prefix "$UP_PARAM_DEV" "$NEW_BIN" && PART_EQ_NEW=1
  PART_EQ_KNOWN_CUSTOM=0
  [ "$PART_EQ_NEW" -eq 0 ] && _part_matches_known_custom && PART_EQ_KNOWN_CUSTOM=1

  if [ "$PART_EQ_NEW" -eq 1 ]; then
    SKIP_WRITE=1
    ui_print "! The partition already contains this splash, but no valid original backup was found."
    ui_print "! Skipping the write. Keep a stock firmware copy for restoration."
  elif [ "$PART_EQ_KNOWN_CUSTOM" -eq 1 ]; then
    _abort "The partition already contains a custom splash, but no valid original backup was found. Restore the original or supply a backup."
  else
    rm -f "$BACKUP_FILE"
    ui_print "- Backing up original up_param ..."
    if ! dd if="$UP_PARAM_DEV" of="$BACKUP_FILE" bs=4096 conv=fsync 2>/dev/null; then
      dd if="$UP_PARAM_DEV" of="$BACKUP_FILE" bs=4096 2>/dev/null
    fi
    sync
    if [ ! -s "$BACKUP_FILE" ]; then
      rm -f "$BACKUP_FILE"
      _abort "Backup failed. Refusing to write without a valid backup."
    fi
    BACKUP_SIZE=$(wc -c < "$BACKUP_FILE" 2>/dev/null | tr -d ' \n')
    if [ "${PART_SIZE:-0}" -gt 0 ] 2>/dev/null && [ "$BACKUP_SIZE" != "$PART_SIZE" ]; then
      rm -f "$BACKUP_FILE"
      _abort "Backup is incomplete ($BACKUP_SIZE of $PART_SIZE bytes). Refusing to write."
    fi
    if ! moss_is_tar "$BACKUP_FILE"; then
      rm -f "$BACKUP_FILE"
      _abort "Backup is not a valid tar archive. The partition may be empty or corrupted."
    fi
    chmod 0600 "$BACKUP_FILE" 2>/dev/null
    ui_print "  Backup saved: $BACKUP_FILE"
  fi
fi

cp -f "$NEW_BIN" "$BACKUP_DIR/up_param_custom.bin" 2>/dev/null
chmod 0600 "$BACKUP_DIR/up_param_custom.bin" 2>/dev/null

if [ "$SKIP_WRITE" -eq 1 ]; then
  ui_print "- Splash already applied; skipping write."
elif ! moss_write_verified "$NEW_BIN" "$UP_PARAM_DEV"; then
  ui_print "! Write or verification failed. Restoring the backup ..."
  if moss_write_verified "$BACKUP_FILE" "$UP_PARAM_DEV"; then
    if [ "$IS_MODULE" -eq 1 ]; then
      ui_print "! Original splash restored. The module will retry on next boot."
      ui_print "! If it still fails, flash this ZIP from TWRP."
    else
      _abort "Write failed. Original splash restored. Try a TWRP-based recovery."
    fi
  else
    _abort "Write failed and automatic restore failed. Restore $BACKUP_FILE manually or flash stock firmware."
  fi
else
  ui_print "  Splash written and verified."
fi

mkdir -p "$MODPATH/up_param" 2>/dev/null
printf '%s\n' "$UP_PARAM_DEV" > "$MODPATH/up_param/device_path.txt"
printf '%s\n' "$BACKUP_DIR" > "$MODPATH/up_param/backup_dir.txt"

if [ "$IS_MODULE" -eq 1 ]; then
  set_perm_recursive "$MODPATH" root root 0755 0644
  set_perm_recursive "$MODPATH/tools" root root 0755 0755
  set_perm "$MODPATH/service.sh" root root 0755
  set_perm "$MODPATH/post-fs-data.sh" root root 0755
  [ -f "$MODPATH/uninstall.sh" ] && set_perm "$MODPATH/uninstall.sh" root root 0755
  [ -f "$MODPATH/tools/restore_up_param.sh" ] && set_perm "$MODPATH/tools/restore_up_param.sh" root root 0755
  [ -f "$MODPATH/tools/pack_up_param.sh" ] && set_perm "$MODPATH/tools/pack_up_param.sh" root root 0755
  [ -f "$MODPATH/up_param/up_param.bin" ] && set_perm "$MODPATH/up_param/up_param.bin" root root 0644
fi

USER_DIR=""
case "$BACKUP_DIR" in
  /data/adb/*|/tmp/*) ;;
  */backup) USER_DIR=$(dirname "$BACKUP_DIR") ;;
  *) USER_DIR="$BACKUP_DIR" ;;
esac
if [ -n "$USER_DIR" ] && [ -w "$USER_DIR" ] && [ -f "$MODPATH/tools/restore_up_param.sh" ]; then
  cp -f "$MODPATH/tools/restore_up_param.sh" "$USER_DIR/restore.sh" 2>/dev/null
  ui_print "- Restore script: $USER_DIR/restore.sh"
fi

if moss_is_mounted /sdcard && mkdir -p /sdcard/MOSS 2>/dev/null && [ -w /sdcard/MOSS ]; then
  cp -f "$BACKUP_FILE" /sdcard/MOSS/up_param_original.bin 2>/dev/null
  cp -f "$NEW_BIN" /sdcard/MOSS/up_param_custom.bin 2>/dev/null
  [ -f "$MODPATH/tools/restore_up_param.sh" ] && \
    cp -f "$MODPATH/tools/restore_up_param.sh" /sdcard/MOSS/restore.sh 2>/dev/null
  ui_print "- Backup copy: /sdcard/MOSS/up_param_original.bin"
fi

ui_print ""
ui_print "======================================="
if [ "$IS_MODULE" -eq 1 ]; then
  ui_print "  Done. Reboot to see the new splash."
  ui_print "  Module re-applies it when the partition differs."
else
  ui_print "  Done. Splash written in standalone mode."
  if [ "${MOSS_FALLBACK:-0}" = "1" ]; then
    ui_print "  Root manager found, but the module directory was not writable."
    ui_print "  Reflash after firmware updates to re-apply the splash."
  else
    ui_print "  No root manager detected: reflash after firmware updates."
  fi
  ui_print "  Restore from: $BACKUP_DIR"
fi
ui_print "======================================="
ui_print ""
