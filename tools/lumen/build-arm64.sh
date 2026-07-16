#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/home/lg/working_dir}"
SOURCE_ROOT="$WORKSPACE/chromium/src"
LUMEN_ROOT="$WORKSPACE/cromite"
OUTPUT_ROOT="$SOURCE_ROOT/out/lumen-arm64"
APK="$OUTPUT_ROOT/apks/ChromePublic.apk"

fail() {
  echo "Lumen ARM64 build failed: $*" >&2
  exit 1
}

for name in LUMEN_KEYSTORE_BASE64 KEYSTORE_PASSWORD KEYSTORE_ALIAS CROMITE_PREF_HASH_SEED_BIN; do
  [[ -n "${!name:-}" ]] || fail "missing required environment value $name"
done

[[ -d "$SOURCE_ROOT" ]] || fail "Chromium source is missing"
[[ -f "$LUMEN_ROOT/build/cromite.gn_args" ]] || fail "Lumen GN arguments are missing"

export PATH="$SOURCE_ROOT/third_party/llvm-build/Release+Asserts/bin:$WORKSPACE/depot_tools:/usr/local/go/bin:$PATH"
export HOME="$WORKSPACE"
export TARGET_ISDEBUG=false
export USE_KEYSTORE=true

printf '%s' "$LUMEN_KEYSTORE_BASE64" | base64 --decode > "$WORKSPACE/cromite.keystore"
chmod 600 "$WORKSPACE/cromite.keystore"
unset LUMEN_KEYSTORE_BASE64

keytool -list \
  -keystore "$WORKSPACE/cromite.keystore" \
  -storepass "$KEYSTORE_PASSWORD" \
  -alias "$KEYSTORE_ALIAS" >/dev/null \
  || fail "keystore password or alias is invalid"

cd "$SOURCE_ROOT"
gn gen "$OUTPUT_ROOT" --args="target_os=\"android\" target_cpu=\"arm64\" $(< "$LUMEN_ROOT/build/cromite.gn_args")"
vpython3 "$WORKSPACE/depot_tools/siso.py" ninja \
  -C "$OUTPUT_ROOT" \
  chrome_public_apk \
  --offline

[[ -s "$APK" ]] || fail "ChromePublic.apk was not produced"
unzip -tq "$APK" >/dev/null || fail "produced APK is not a valid ZIP archive"

apksigner="$(find "$SOURCE_ROOT/third_party/android_sdk/public/build-tools" \
  -type f -name apksigner -print | sort -V | tail -n 1)"
[[ -x "$apksigner" ]] || fail "Android apksigner was not found"
"$apksigner" verify --verbose --print-certs "$APK" >/dev/null \
  || fail "produced APK signature is invalid"

cp "$LUMEN_ROOT/build/RELEASE" "$OUTPUT_ROOT/RELEASE"
git -C "$LUMEN_ROOT" rev-parse HEAD > "$OUTPUT_ROOT/SOURCE_COMMIT"
sha256sum "$APK" > "$OUTPUT_ROOT/ChromePublic.apk.sha256"
