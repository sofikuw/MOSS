#!/system/bin/sh
# Safety net for devices where up_param is not ready at post-fs-data time.

MODDIR="${0%/*}"
[ -d "$MODDIR" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/tools/common.sh" 2>/dev/null || exit 0

CUSTOM_BIN="$MODDIR/up_param/up_param.bin"
DEV_FILE="$MODDIR/up_param/device_path.txt"
FLAG="$MODDIR/.applied_this_boot"

[ -f "$FLAG" ] && exit 0
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

blockdev --setrw "$UP_PARAM_DEV" >/dev/null 2>&1 || true
TRIES=0
while [ ! -w "$UP_PARAM_DEV" ] && [ "$TRIES" -lt 10 ]; do
  sleep 1
  TRIES=$((TRIES + 1))
done
[ -w "$UP_PARAM_DEV" ] || exit 0

if command -v cmp >/dev/null 2>&1; then
  if moss_compare_prefix "$UP_PARAM_DEV" "$CUSTOM_BIN"; then
    touch "$FLAG" 2>/dev/null
    exit 0
  fi
fi

if moss_write_verified "$CUSTOM_BIN" "$UP_PARAM_DEV"; then
  touch "$FLAG" 2>/dev/null
fi
