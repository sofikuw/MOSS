#!/system/bin/sh
# =============================================================================
#  pack_up_param.sh  –  Standalone packer (run on Android via Termux / ADB)
#
#  Usage:
#    sh pack_up_param.sh <folder_with_jpgs> <output.bin>
#
#  Example:
#    sh pack_up_param.sh /sdcard/my_splash /sdcard/up_param_new.bin
#
#  The output file is a valid GNU tar archive ready to be flashed to the
#  up_param partition or bundled into this Magisk module.
# =============================================================================

SRC_DIR="$1"
OUT_FILE="$2"

usage() {
  echo ""
  echo "Usage: sh pack_up_param.sh <image_folder> <output.bin>"
  echo ""
  echo "  <image_folder>  Directory containing your JPEG images"
  echo "  <output.bin>    Where to write the new up_param.bin"
  echo ""
  echo "Valid image names:"
  echo "  logo.jpg, android_logo.jpg, lpm.jpg, setting_logo.jpg,"
  echo "  device_lock.jpg, device_unlock.jpg, download.jpg,"
  echo "  download_error.jpg, secure_error.jpg, warning.jpg,"
  echo "  warning_svb.jpg, letter.jpg, SUD_0.jpg … SUD_10.jpg"
  echo ""
  exit 1
}

[ -z "$SRC_DIR" ] || [ -z "$OUT_FILE" ] && usage
[ -d "$SRC_DIR" ] || { echo "Error: '$SRC_DIR' is not a directory."; usage; }

# Count JPEG files
COUNT=$(ls "$SRC_DIR"/*.jpg 2>/dev/null | wc -l)
[ "$COUNT" -eq 0 ] && { echo "Error: No .jpg files found in $SRC_DIR"; exit 1; }

echo "Packing $COUNT image(s) from $SRC_DIR ..."
(cd "$SRC_DIR" && tar -cf "$OUT_FILE" *.jpg 2>/dev/null)

if [ $? -eq 0 ] && [ -s "$OUT_FILE" ]; then
  SIZE=$(ls -lh "$OUT_FILE" | awk '{print $5}')
  echo "✓ Created $OUT_FILE ($SIZE)"
  echo ""
  echo "Contents:"
  tar -tf "$OUT_FILE"
  echo ""
  echo "Flash with:"
  echo "  dd if=\"$OUT_FILE\" of=/dev/block/by-name/up_param bs=4096"
else
  echo "✗ Failed to create $OUT_FILE"
  exit 1
fi
