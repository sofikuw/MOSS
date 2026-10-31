#!/system/bin/sh
# Re-applies the custom splash early in boot when the partition differs.

MODDIR="${0%/*}"
[ -d "$MODDIR" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/tools/common.sh" 2>/dev/null || exit 0

CUSTOM_BIN="$MODDIR/up_param/up_param.bin"
DEV_FILE="$MODDIR/up_param/device_path.txt"
FLAG="$MODDIR/.applied_this_boot"

rm -f "$FLAG"

[ -f "$CUSTOM_BIN" ] && [ -s "$CUSTOM_BIN" ] || exit 0
moss_is_tar "$CUSTOM_BIN" || exit 0

UP_PARAM_DEV=""
if [ -f "$DEV_FILE" ]; then
  UP_PARAM_DEV=$(tr -d '[:space:]' < "$DEV_FILE")
fi
if [ -z "$UP_PARAM_DEV" ] || [ ! -b "$UP_PARAM_DEV" ]; then
  UP_PARAM_DEV=$(moss_find_up_param) || exit 0
fi
[ -n "$UP_PARAM_DEV" ] && [ -b "$UP_PARAM_DEV" ] || exit 0

if command -v cmp >/dev/null 2>&1; then
  if moss_compare_prefix "$UP_PARAM_DEV" "$CUSTOM_BIN"; then
    touch "$FLAG" 2>/dev/null
    exit 0
  fi
fi

if moss_write_verified "$CUSTOM_BIN" "$UP_PARAM_DEV"; then
  touch "$FLAG" 2>/dev/null
fi
