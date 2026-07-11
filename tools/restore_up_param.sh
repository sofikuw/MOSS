#!/system/bin/sh
# =============================================================================
#  restore_up_param.sh  –  Restore original up_param from backup
#
#  Run this via ADB shell or Termux (as root) if you want to revert.
#  The backup is created automatically during module installation.
# =============================================================================

BACKUP="/data/adb/samsung_splash_backup/up_param_original.bin"

[ -f "$BACKUP" ] || {
  echo "✗ No backup found at $BACKUP"
  echo "  The module may not have been installed yet, or the backup was deleted."
  exit 1
}

# Detect partition
UP_PARAM_DEV=""
for p in \
    /dev/block/by-name/up_param \
    /dev/block/bootdevice/by-name/up_param; do
  [ -e "$p" ] && { UP_PARAM_DEV="$p"; break; }
done

for p in /dev/block/platform/*/by-name/up_param; do
  [ -e "$p" ] && { UP_PARAM_DEV="$p"; break; }
done

[ -z "$UP_PARAM_DEV" ] && {
  echo "✗ up_param partition not found."
  exit 1
}

echo "Restoring original up_param from backup..."
echo "  Source : $BACKUP"
echo "  Target : $UP_PARAM_DEV"
echo ""
dd if="$BACKUP" of="$UP_PARAM_DEV" bs=4096 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Original splash restored. Reboot to apply."
else
  echo "✗ Restore failed. Try from TWRP recovery."
fi
