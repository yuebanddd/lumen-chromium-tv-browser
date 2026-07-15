# Lumen TV Browser architecture

## Product boundary

Lumen is an independent Chromium browser APK. It does not embed Android `WebView`, install Chrome, or replace the operating system WebView provider. The browser process, Blink renderer, V8 JavaScript engine, network stack and codecs selected at build time are packaged as Chromium's `chrome_public_apk` target.

The initial release targets Android 10 or newer and ARM64 Android TV / Google TV devices. The application ID is `com.deeplumen.lumentvbrowser`.

## Downstream patch model

Cromite remains the upstream maintenance layer. Lumen changes are appended after the Cromite patch stack:

1. `build/RELEASE` pins the Chromium version.
2. `build/cromite_patches_list.txt` applies Cromite's patches in order.
3. `build/patches/Lumen-TV-shell-and-remote-navigation.patch` applies the Lumen TV delta last.
4. `build/cromite.gn_args` selects the Lumen package ID and Chromium media/build options.

Keeping the TV work in a final patch makes an upstream Chromium upgrade explicit: update from Cromite, run patch validation, resolve only the Lumen patch if Chromium changed the touched Android files, and rebuild.

## Branch and release model

- `master` mirrors or synchronizes Cromite upstream changes.
- `release` is the Lumen product integration and publishing branch.
- `agent/*` and other development branches must open pull requests against `release`.
- Pull requests run both lightweight configuration validation and the complete Chromium patch-application check.
- GitHub Releases can only be created by manually running the publish workflow from `release`.

The publish workflow does not compile Chromium. It promotes the `lumen-tv-browser-arm64` artifact from an already completed, isolated build run. This keeps signing and high-resource compilation separate from public PR validation.

## Current TV behavior

- `LEANBACK_LAUNCHER` makes the browser visible in Android TV launchers.
- Touchscreen is optional, so remote-only televisions remain compatible.
- The main tabbed activity uses landscape orientation.
- The vector TV banner scales cleanly on 1080p and 4K launchers.
- D-pad arrows move between native Chromium controls when Android exposes a focus target.
- Blink spatial navigation handles directional movement between focusable web-page elements.
- The soft keyboard stays hidden until a focused text field requests input.

Remote `Back`, `Enter`/D-pad center and media keys continue through Chromium and Android's normal key handling.

## 4K and media support

Chromium renders at the display surface resolution provided by Android. Lumen retains Cromite's high-end Android configuration, AV1 decoder, platform H.264/AAC and platform HEVC options. Vector UI artwork avoids fixed-resolution launcher assets.

This does not guarantee that every site will offer 4K video. Actual playback depends on the TV SoC decoder, Android codec implementation, stream profile, DRM level, HDCP path and the site's browser policy. Widevine is proprietary and is not bundled merely by compiling Chromium; DRM services therefore require separate device and licensing validation.

## Building ARM64

The intended target is Chromium's `chrome_public_apk` with `target_os="android"` and `target_cpu="arm64"`. The output is `out/arm64/apks/ChromePublic.apk`; release packaging should rename it to `LumenTVBrowser-arm64.apk`.

A full Chromium build needs a dedicated Linux builder with Docker, substantial RAM and storage, and a private Android signing keystore. The inherited Cromite workflow is coupled to upstream self-hosted infrastructure and is not enabled for Lumen branch commits in this baseline. Fork-aware containers, runner isolation, cache ownership and signing secrets must be reviewed and approved as a separate build-infrastructure change. Never commit signing material to this repository.

## Validation gates

`tools/lumen/validate.sh` checks the pinned Chromium version, package ID, patch order, TV manifest declarations, D-pad/spatial-navigation code and fork-aware container source. The lightweight GitHub Action runs this validation on every Lumen pull request.

Full confidence still requires the complete Cromite patch-application job, an ARM64 Chromium compilation and installation tests on both 1080p and 4K televisions.
