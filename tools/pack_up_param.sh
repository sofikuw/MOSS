#!/system/bin/sh
# Packs JPEG images into an uncompressed tar archive accepted as up_param.bin.

usage() {
  echo ""
  echo "Usage: sh pack_up_param.sh <image_folder> <output.bin>"
  echo ""
  echo "  <image_folder>  Directory containing the JPEG images"
  echo "  <output.bin>    Where to write the new up_param.bin"
  echo ""
  echo "Valid image names:"
  echo "  logo.jpg, android_logo.jpg, lpm.jpg, setting_logo.jpg,"
  echo "  device_lock.jpg, device_unlock.jpg, download.jpg,"
  echo "  download_error.jpg, secure_error.jpg, warning.jpg,"
  echo "  warning_svb.jpg, letter.jpg, SUD_0.jpg ... SUD_10.jpg"
  echo ""
  exit 1
}

SRC_DIR="${1:-}"
OUT_FILE="${2:-}"
[ -n "$SRC_DIR" ] && [ -n "$OUT_FILE" ] || usage
[ -d "$SRC_DIR" ] || { echo "Error: '$SRC_DIR' is not a directory."; usage; }

COUNT=0
for f in "$SRC_DIR"/*.jpg; do
  [ -f "$f" ] && COUNT=$((COUNT + 1))
done
if [ "$COUNT" -eq 0 ]; then
  echo "Error: no .jpg files found in $SRC_DIR"
  exit 1
fi

OUT_DIR=$(dirname "$OUT_FILE")
mkdir -p "$OUT_DIR" || { echo "Error: cannot create $OUT_DIR"; exit 1; }
OUT_FILE="$(cd "$OUT_DIR" && pwd)/$(basename "$OUT_FILE")"
OUT_DIR=$(dirname "$OUT_FILE")
TMP_OUT="$OUT_DIR/.moss_pack.$$"
rm -f "$TMP_OUT"
trap 'rm -f "$TMP_OUT"' 0 1 2 15

echo "Packing $COUNT image(s) from $SRC_DIR ..."
if command -v tar >/dev/null 2>&1; then
  (cd "$SRC_DIR" && tar -cf "$TMP_OUT" -- *.jpg)
elif command -v busybox >/dev/null 2>&1; then
  (cd "$SRC_DIR" && busybox tar -cf "$TMP_OUT" -- *.jpg)
else
  echo "Error: tar is not available."
  exit 1
fi

if [ ! -s "$TMP_OUT" ]; then
  echo "Failed to create $OUT_FILE"
  exit 1
fi
mv -f "$TMP_OUT" "$OUT_FILE" || { echo "Failed to move output into place."; exit 1; }

if command -v tar >/dev/null 2>&1; then
  if ! tar -tf "$OUT_FILE" >/dev/null 2>&1; then
    rm -f "$OUT_FILE"
    echo "Error: created archive could not be verified."
    exit 1
  fi
elif command -v busybox >/dev/null 2>&1; then
  if ! busybox tar -tf "$OUT_FILE" >/dev/null 2>&1; then
    rm -f "$OUT_FILE"
    echo "Error: created archive could not be verified."
    exit 1
  fi
fi

SIZE=$(wc -c < "$OUT_FILE" 2>/dev/null | tr -d ' \n')
echo "Created $OUT_FILE ($SIZE bytes)"
echo ""
echo "Contents:"
if command -v tar >/dev/null 2>&1; then
  tar -tf "$OUT_FILE"
else
  busybox tar -tf "$OUT_FILE"
fi
echo ""
echo "Flash with:"
echo "  dd if=\"$OUT_FILE\" of=/dev/block/by-name/up_param bs=4096"
echo "  Or place it at up_param/up_param.bin inside the MOSS ZIP."
