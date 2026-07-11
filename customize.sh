#!/system/bin/sh
# =============================================================================
#  My Own Splash Screen – customize.sh
#  All installation logic lives here; sourced by update-binary.
#  Variables available: $MODPATH, $ZIPFILE, $OUTFD (set by update-binary).
# =============================================================================

# ── UI helpers ────────────────────────────────────────────────────────────────
_ui_print() { ui_print "$1" 2>/dev/null || echo "$1"; }
_abort()    {
  _ui_print ""
  _ui_print "  ✗ $1"
  _ui_print ""
  exit 1
}

_ui_print ""
_ui_print "═══════════════════════════════════════"
_ui_print "  My Own Splash Screen"
_ui_print "  by sofikuw"
_ui_print "═══════════════════════════════════════"
_ui_print ""

# ── Set correct permissions on extracted files ────────────────────────────────
set_perm_recursive "$MODPATH"          root root 0755 0644
set_perm_recursive "$MODPATH/tools"    root root 0755 0755
set_perm_recursive "$MODPATH/up_param" root root 0755 0644
set_perm            "$MODPATH/service.sh"                root root 0755
set_perm            "$MODPATH/post-fs-data.sh"           root root 0755
set_perm            "$MODPATH/tools/restore_up_param.sh" root root 0755

# ── Locate the user's up_param.bin inside the module ─────────────────────────
NEW_BIN="$MODPATH/up_param/up_param.bin"
if [ ! -f "$NEW_BIN" ] || [ ! -s "$NEW_BIN" ]; then
  _abort "up_param.bin not found in the module's up_param/ folder.
    Place your up_param.bin file at:
      up_param/up_param.bin
    inside the module zip, then reflash."
fi

# Validate it is a real tar archive
tar -tf "$NEW_BIN" >/dev/null 2>&1 || \
  _abort "up_param.bin is not a valid tar archive. Make sure you packed it correctly (see README.md)."

_ui_print "- Found up_param.bin ($(wc -c < "$NEW_BIN") bytes)"

# ── Detect up_param block device ─────────────────────────────────────────────
find_up_param_dev() {
  for path in \
      /dev/block/by-name/up_param \
      /dev/block/bootdevice/by-name/up_param; do
    [ -b "$path" ] && { echo "$path"; return 0; }
  done
  for path in /dev/block/platform/*/by-name/up_param; do
    [ -b "$path" ] && { echo "$path"; return 0; }
  done
  local devname
  devname=$(grep -i ' up_param$' /proc/partitions 2>/dev/null | awk '{print $NF}' | head -1)
  [ -n "$devname" ] && [ -b "/dev/block/$devname" ] && {
    echo "/dev/block/$devname"; return 0
  }
  return 1
}

UP_PARAM_DEV=$(find_up_param_dev)
if [ -z "$UP_PARAM_DEV" ] || [ ! -b "$UP_PARAM_DEV" ]; then
  _abort "up_param partition NOT found. This module only works on Samsung devices that use the up_param partition (Galaxy S6 and later)."
fi

_ui_print "- Found up_param at: $UP_PARAM_DEV"

# ── Partition size guard ───────────────────────────────────────────────────────
get_partition_size_bytes() {
  local dev="$1"
  local sz
  sz=$(blockdev --getsize64 "$dev" 2>/dev/null)
  [ -n "$sz" ] && [ "$sz" -gt 0 ] 2>/dev/null && { echo "$sz"; return 0; }
  local devname
  devname=$(basename "$(readlink -f "$dev" 2>/dev/null)" 2>/dev/null)
  if [ -n "$devname" ]; then
    local syssize
    syssize=$(cat "/sys/class/block/${devname}/size" 2>/dev/null)
    [ -n "$syssize" ] && echo $((syssize * 512)) && return 0
  fi
  echo 0
}

PART_SIZE=$(get_partition_size_bytes "$UP_PARAM_DEV")
NEW_SIZE=$(wc -c < "$NEW_BIN" 2>/dev/null || echo 0)
_ui_print "- Partition size : ${PART_SIZE} bytes"
_ui_print "- Payload size   : ${NEW_SIZE} bytes"

if [ "$PART_SIZE" -gt 0 ] 2>/dev/null && [ "$NEW_SIZE" -gt "$PART_SIZE" ] 2>/dev/null; then
  _abort "up_param.bin ($NEW_SIZE bytes) exceeds partition size ($PART_SIZE bytes). Use a smaller file."
fi

# ── Mandatory backup — abort on failure ───────────────────────────────────────
BACKUP_DIR="/data/adb/samsung_splash_backup"
BACKUP_FILE="$BACKUP_DIR/up_param_original.bin"
mkdir -p "$BACKUP_DIR" || _abort "Cannot create backup directory $BACKUP_DIR"

if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
  _ui_print "- Existing backup found — skipping."
else
  _ui_print "- Backing up original up_param ..."
  rm -f "$BACKUP_FILE"
  dd if="$UP_PARAM_DEV" of="$BACKUP_FILE" bs=4096 2>/dev/null
  DD_RC=$?
  if [ "$DD_RC" -ne 0 ] || [ ! -s "$BACKUP_FILE" ]; then
    rm -f "$BACKUP_FILE"
    _abort "Backup FAILED (dd exit $DD_RC). Refusing to continue — flash from TWRP recovery instead."
  fi
  tar -tf "$BACKUP_FILE" >/dev/null 2>&1 || \
    _abort "Backup is not a valid tar archive. The partition may be empty or corrupted. Cannot continue safely."
  _ui_print "  ✓ Backup saved: $BACKUP_FILE"
fi

# ── Write new up_param.bin to partition ───────────────────────────────────────
_ui_print "- Writing new splash to $UP_PARAM_DEV ..."
dd if="$NEW_BIN" of="$UP_PARAM_DEV" bs=4096 2>/dev/null
WRITE_RC=$?
if [ "$WRITE_RC" -ne 0 ]; then
  _abort "dd write failed (exit $WRITE_RC). Original splash is intact. Try flashing from TWRP recovery."
fi
_ui_print "  ✓ Splash written!"

# ── Save state for boot-time reapply ─────────────────────────────────────────
cp -f "$NEW_BIN" "$BACKUP_DIR/up_param_custom.bin"
echo "$UP_PARAM_DEV" > "$MODPATH/up_param/device_path.txt"

_ui_print ""
_ui_print "═══════════════════════════════════════"
_ui_print "  Done! Reboot to see your new splash."
_ui_print "  Backup : $BACKUP_FILE"
_ui_print "═══════════════════════════════════════"
_ui_print ""
