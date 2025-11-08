echo "=========================================="
echo "Starting Talos Linux Installation"
echo "=========================================="
echo ""

echo "[1/5] Downloading Talos schematic configuration..."
echo "  Source: http://$PACKER_HTTP_IP:$PACKER_HTTP_PORT/schematic.yaml"
curl -v -L http://$PACKER_HTTP_IP:$PACKER_HTTP_PORT/schematic.yaml -o schematic.yaml
SCHEMATIC_SIZE=$(stat -f%z schematic.yaml 2>/dev/null || stat -c%s schematic.yaml 2>/dev/null)
echo "  ✓ Schematic downloaded successfully ($(numfmt --to=iec-i --suffix=B $SCHEMATIC_SIZE 2>/dev/null || echo $SCHEMATIC_SIZE bytes))"
echo ""

echo "[2/5] Generating custom Talos schematic..."
echo "  Uploading schematic to factory.talos.dev..."
export SCHEMATIC=$(curl -L -X POST --data-binary @schematic.yaml https://factory.talos.dev/schematics | grep -o '\"id\":\"[^\"]*' | grep -o '[^\"]*$')
if [ -z "$SCHEMATIC" ]; then
  echo "  ✗ ERROR: Failed to generate schematic ID"
  exit 1
fi
echo "  ✓ Schematic generated successfully"
echo "  Schematic ID: $SCHEMATIC"
echo ""

echo "[3/5] Building Talos image URL..."
TALOS_URL=https://factory.talos.dev/image/$SCHEMATIC/v$OS_VERSION/nocloud-amd64.raw.xz
echo "  OS Version: $OS_VERSION"
echo "  Image Format: nocloud-amd64.raw.xz"
echo "  Download URL: $TALOS_URL"
echo ""

echo "[4/5] Downloading Talos image (this may take a few minutes)..."
echo "  Downloading from factory.talos.dev..."
curl -L $TALOS_URL -o /tmp/talos.raw.xz
if [ ! -f /tmp/talos.raw.xz ]; then
  echo "  ✗ ERROR: Failed to download Talos image"
  exit 1
fi
TALOS_SIZE=$(stat -f%z /tmp/talos.raw.xz 2>/dev/null || stat -c%s /tmp/talos.raw.xz 2>/dev/null)
echo "  ✓ Image downloaded successfully ($(numfmt --to=iec-i --suffix=B $TALOS_SIZE 2>/dev/null || echo $TALOS_SIZE bytes))"
echo ""

echo "[5/5] Writing Talos image to disk..."
echo "  Decompressing and writing to /dev/sda..."
echo "  This is the final step and may take several minutes..."
xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync
if [ $? -eq 0 ]; then
  echo "  ✓ Image written successfully"
  echo "  Syncing filesystem..."
  sync
  echo "  ✓ Filesystem synced"
else
  echo "  ✗ ERROR: Failed to write image to disk"
  exit 1
fi
echo ""

echo "=========================================="
echo "✓ Talos Linux installation completed!"
echo "=========================================="