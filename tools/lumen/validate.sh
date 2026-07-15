#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_NAME="Lumen-TV-shell-and-remote-navigation.patch"
PATCH_FILE="$ROOT/build/patches/$PATCH_NAME"

fail() {
  echo "Lumen validation failed: $*" >&2
  exit 1
}

[[ -f "$PATCH_FILE" ]] || fail "missing $PATCH_FILE"

release="$(tr -d '[:space:]' < "$ROOT/build/RELEASE")"
[[ "$release" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail "build/RELEASE is not a Chromium version"

patch_count="$(grep -Fxc "$PATCH_NAME" "$ROOT/build/cromite_patches_list.txt")"
[[ "$patch_count" == "1" ]] || fail "Lumen patch must appear exactly once in the patch list"

last_patch="$(grep -Ev '^[[:space:]]*(#|$)' "$ROOT/build/cromite_patches_list.txt" | tail -n 1)"
[[ "$last_patch" == "$PATCH_NAME" ]] || fail "Lumen patch must be the final downstream patch"

grep -Fq 'chrome_public_manifest_package = "com.deeplumen.lumentvbrowser"' \
  "$ROOT/build/cromite.gn_args" || fail "unexpected Android package ID"

grep -Fq 'android.intent.category.LEANBACK_LAUNCHER' "$PATCH_FILE" \
  || fail "Leanback launcher declaration is missing"
grep -Fq 'android.software.leanback' "$PATCH_FILE" \
  || fail "Leanback feature declaration is missing"
grep -Fq 'android:banner="@drawable/lumen_tv_banner"' "$PATCH_FILE" \
  || fail "TV banner is missing"
grep -Fq 'appendSwitch("enable-spatial-navigation")' "$PATCH_FILE" \
  || fail "Blink spatial navigation is missing"
grep -Fq 'KEYCODE_DPAD_UP' "$PATCH_FILE" \
  || fail "D-pad focus routing is missing"

git apply --stat "$PATCH_FILE" >/dev/null \
  || fail "Lumen patch is not syntactically valid"

echo "Lumen TV configuration is valid for Chromium $release."
