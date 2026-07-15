#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=/home/lg/working_dir
export PATH="$WORKSPACE/chromium/src/third_party/llvm-build/Release+Asserts/bin:$WORKSPACE/depot_tools:/usr/local/go/bin:$PATH"

mkdir -p "$CIPD_CACHE_DIR" "$VPYTHON_VIRTUALENV_ROOT"

cd "$WORKSPACE/chromium/src"
vpython3 -vpython-spec .vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec ../../depot_tools/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec third_party/angle/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec third_party/catapult/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec third_party/webrtc/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec v8/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec v8/tools/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install
vpython3 -vpython-spec tools/flags/.vpython3 -vpython-root "$VPYTHON_VIRTUALENV_ROOT" -vpython-tool install

cd "$WORKSPACE/chromium/src/third_party/devtools-frontend/src"
vpython3 scripts/deps/sync_rollup_libs.py

cd "$WORKSPACE/chromium/src"
python3 tools/update_pgo_profiles.py \
  --target=android-desktop-arm64 \
  update \
  --gs-url-base=chromium-optimization-profiles/pgo_profiles
python3 v8/tools/builtins-pgo/download_profiles.py \
  download \
  --depot-tools third_party/depot_tools \
  --check-v8-revision
python3 tools/download_optimization_profile.py \
  --newest_state=chrome/android/profiles/newest.txt \
  --local_state=chrome/android/profiles/local.txt \
  --output_name=chrome/android/profiles/afdo.prof \
  --gs_url_base=chromeos-prebuilt/afdo-job/llvm
python3 tools/download_optimization_profile.py \
  --newest_state=chrome/android/profiles/arm.newest.txt \
  --local_state=chrome/android/profiles/arm.local.txt \
  --output_name=chrome/android/profiles/arm.afdo.prof \
  --gs_url_base=chromeos-prebuilt/afdo-job/llvm

echo ../../../../../usr/bin > "$WORKSPACE/depot_tools/python3_bin_reldir.txt"
