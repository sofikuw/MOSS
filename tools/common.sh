#!/system/bin/sh
# Shared helpers for MOSS. Sourced by customize.sh and the boot scripts.

moss_is_mounted() {
  local p="$1" rp mp
  [ -n "$p" ] && [ -d "$p" ] || return 1
  if command -v mountpoint >/dev/null 2>&1; then
    mountpoint -q "$p" && return 0
  fi
  grep -q "[[:space:]]$p[[:space:]]" /proc/mounts 2>/dev/null && return 0
  rp=$(readlink -f "$p" 2>/dev/null)
  if [ -n "$rp" ] && [ "$rp" != "$p" ] && grep -q "[[:space:]]$rp[[:space:]]" /proc/mounts 2>/dev/null; then
    return 0
  fi
  if command -v df >/dev/null 2>&1; then
    mp=$(df -P "$p" 2>/dev/null | awk 'NR==2 {print $6}')
    [ -n "$mp" ] && [ "$mp" != "/" ] && return 0
  fi
  return 1
}

moss_find_up_param() {
  local p name
  if [ -n "${MOSS_UP_PARAM_DEV:-}" ]; then
    printf '%s\n' "$MOSS_UP_PARAM_DEV"
    return 0
  fi
  for p in \
      /dev/block/by-name/up_param \
      /dev/block/bootdevice/by-name/up_param; do
    [ -b "$p" ] && { printf '%s\n' "$p"; return 0; }
  done
  for p in \
      /dev/block/platform/*/by-name/up_param \
      /dev/block/platform/*/*/by-name/up_param \
      /dev/block/platform/*/*/*/by-name/up_param \
      /dev/block/*/by-name/up_param; do
    [ -b "$p" ] && { printf '%s\n' "$p"; return 0; }
  done
  name=$(grep -i ' up_param$' /proc/partitions 2>/dev/null | awk '{print $NF}' | head -n 1)
  if [ -n "$name" ] && [ -b "/dev/block/$name" ]; then
    printf '%s\n' "/dev/block/$name"
    return 0
  fi
  return 1
}

moss_part_size() {
  local dev="$1" size name
  size=$(blockdev --getsize64 "$dev" 2>/dev/null)
  if [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null; then
    printf '%s\n' "$size"
    return 0
  fi
  name=$(basename "$(readlink -f "$dev" 2>/dev/null)" 2>/dev/null)
  if [ -n "$name" ]; then
    size=$(cat "/sys/class/block/$name/size" 2>/dev/null)
    if [ -n "$size" ]; then
      printf '%s\n' "$((size * 512))"
      return 0
    fi
  fi
  printf '0\n'
}

moss_is_tar() {
  local file="$1" magic
  [ -f "$file" ] && [ -s "$file" ] || return 1
  if command -v tar >/dev/null 2>&1; then
    tar -tf "$file" >/dev/null 2>&1 && return 0
  fi
  if command -v busybox >/dev/null 2>&1; then
    busybox tar -tf "$file" >/dev/null 2>&1 && return 0
  fi
  magic=$(dd if="$file" bs=1 skip=257 count=5 2>/dev/null)
  [ "$magic" = "ustar" ]
}

moss_compare_prefix() {
  local dev="$1" file="$2" size blocks
  [ -r "$dev" ] && [ -r "$file" ] || return 1
  size=$(wc -c < "$file" 2>/dev/null | tr -d ' \n')
  [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null || return 1
  command -v cmp >/dev/null 2>&1 || return 1
  cmp -n "$size" "$dev" "$file" >/dev/null 2>&1 && return 0
  blocks=$(( (size + 4095) / 4096 ))
  dd if="$dev" bs=4096 count="$blocks" 2>/dev/null | head -c "$size" | cmp -s - "$file" 2>/dev/null
}

moss_write_verified() {
  local src="$1" dev="$2" size part_size
  [ -f "$src" ] && [ -e "$dev" ] || return 1
  size=$(wc -c < "$src" 2>/dev/null | tr -d ' \n')
  [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null || return 1
  part_size=$(moss_part_size "$dev")
  if [ -n "$part_size" ] && [ "$part_size" -gt 0 ] 2>/dev/null && [ "$size" -gt "$part_size" ] 2>/dev/null; then
    return 1
  fi
  blockdev --setrw "$dev" >/dev/null 2>&1 || true
  if ! dd if="$src" of="$dev" bs=4096 conv=fsync 2>/dev/null; then
    dd if="$src" of="$dev" bs=4096 2>/dev/null || return 1
  fi
  sync
  blockdev --flushbufs "$dev" >/dev/null 2>&1 || true
  if command -v cmp >/dev/null 2>&1; then
    moss_compare_prefix "$dev" "$src" || return 1
  fi
  return 0
}
