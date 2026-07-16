#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_NAME="Lumen-TV-shell-and-remote-navigation.patch"
PATCH_FILE="$ROOT/build/patches/$PATCH_NAME"
UPSTREAM_COMMIT_FILE="$ROOT/build/UPSTREAM_COMMIT"

fail() {
  echo "Lumen validation failed: $*" >&2
  exit 1
}

[[ -f "$PATCH_FILE" ]] || fail "missing $PATCH_FILE"
[[ -f "$UPSTREAM_COMMIT_FILE" ]] || fail "missing $UPSTREAM_COMMIT_FILE"

upstream_commit="$(tr -d '[:space:]' < "$UPSTREAM_COMMIT_FILE")"
[[ "$upstream_commit" =~ ^[0-9a-f]{40}$ ]] \
  || fail "build/UPSTREAM_COMMIT is not a full Git commit SHA"

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

grep -Fq 'android_keystore_name = getenv("KEYSTORE_ALIAS")' \
  "$ROOT/build/cromite.gn_args" || fail "release keystore alias must come from the build environment"

if [[ -f "$ROOT/.github/workflows/lumen-build-arm64.yml" ]]; then
  grep -Fq "github.ref == 'refs/heads/release'" \
    "$ROOT/.github/workflows/lumen-build-arm64.yml" || fail "ARM64 builds must be restricted to release"
  grep -Fq -- '--network none' \
    "$ROOT/.github/workflows/lumen-build-arm64.yml" || fail "ARM64 compiler container must be offline"
fi

git apply --stat "$PATCH_FILE" >/dev/null \
  || fail "Lumen patch is not syntactically valid"

echo "Lumen TV configuration is valid for Chromium $release."
