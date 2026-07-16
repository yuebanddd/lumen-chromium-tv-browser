# Isolated ARM64 build runner

The `Build Lumen TV Browser ARM64` workflow compiles and signs the self-contained Chromium APK. It is intentionally manual and only runs when GitHub dispatches it from the `release` branch.

## Trust boundary

- The job requires all four labels: `self-hosted`, `linux`, `x64`, and `lumen-build-ephemeral`.
- Use a dedicated disposable VM or an ephemeral Actions Runner Controller runner. Do not reuse a developer workstation or a runner that handles untrusted pull requests.
- The workflow never runs on `pull_request`, and `actions/checkout` does not retain GitHub credentials.
- Image preparation has network access so Chromium build inputs can be downloaded. The final compiler container uses Docker's `none` network, receives no GitHub token, and has no host volume mounts.
- The compiler is limited by the CPU, memory, PID, and 24-hour job limits declared in the workflow.
- Only the APK and text metadata are copied out of the stopped compiler container. Containers and local Lumen images are removed even after failure.

Recommended runner capacity is at least 32 x86-64 CPU cores, 64 GiB RAM, and 300 GiB of fast SSD storage. The workflow refuses to start below 32 GiB RAM input or 200 GiB free workspace storage.

## Protected environment and secrets

Create a GitHub Environment named `lumen-build`, enable required reviewers, and add these environment secrets:

| Secret | Purpose |
| --- | --- |
| `LUMEN_KEYSTORE_BASE64` | Base64 encoding of the Android release keystore |
| `LUMEN_KEYSTORE_PASSWORD` | Keystore password |
| `LUMEN_KEY_ALIAS` | Alias of the Android signing key |
| `LUMEN_PREF_HASH_SEED_BIN` | Stable Cromite preference hash seed |

Keep the signing keystore backed up offline. Android updates must use the same application ID and signing key as the installed version.

## Build and publish

1. Open Actions and select `Build Lumen TV Browser ARM64`.
2. Choose `release`, confirm the resource limits, and run the workflow.
3. Record the successful build run ID. Its artifact is named `lumen-tv-browser-arm64` and is retained for 14 days.
4. Run `Publish Lumen TV Browser` from `release`, passing that run ID and a semantic release tag such as `v0.1.0`.

The build pulls the Chromium source base image matching `build/RELEASE`, then fetches the exact Lumen `release` commit into the source image. For stronger dependency control, pin and mirror the `uazo/chromium` base image in a registry managed by the project.
