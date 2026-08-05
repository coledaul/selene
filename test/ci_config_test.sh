#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ci_workflow="$repo_root/.github/workflows/ci.yml"
release_workflow="$repo_root/.github/workflows/release.yml"
release_assets_workflow="$repo_root/.github/workflows/release-assets.yml"
rolling_workflow="$repo_root/.github/workflows/rolling.yml"
dependabot_config="$repo_root/.github/dependabot.yml"
windows_ffmpeg_setup="$repo_root/scripts/prepare_windows_ffmpeg.ps1"
android_release_verifier="$repo_root/scripts/verify_android_release.sh"

locked_sources="$(sed -n 's/^[[:space:]]*url: "\([^"]*\)"/\1/p' "$repo_root/pubspec.lock" | sort -u)"
if [ "$(printf '%s\n' "$locked_sources" | sed '/^$/d' | wc -l | tr -d ' ')" -ne 1 ]; then
  echo "pubspec.lock must use one consistent hosted package source"
  exit 1
fi

for dependency_entrypoint in "$repo_root/build.sh" "$ci_workflow" "$release_assets_workflow"; do
  if ! grep -Fq 'flutter pub get --enforce-lockfile' "$dependency_entrypoint"; then
    echo "dependency resolution must enforce pubspec.lock: ${dependency_entrypoint#"$repo_root/"}"
    exit 1
  fi
done

if ! grep -Fq 'PUB_HOSTED_URL="$pub_hosted_url" flutter pub get --enforce-lockfile' "$repo_root/build.sh"; then
  echo "build.sh must resolve against the hosted source recorded in pubspec.lock"
  exit 1
fi

for workflow in "$ci_workflow" "$release_assets_workflow" "$rolling_workflow"; do
  if ! grep -Fq "PUB_HOSTED_URL: $locked_sources" "$workflow"; then
    echo "workflow package source must match pubspec.lock: ${workflow#"$repo_root/"}"
    exit 1
  fi
done

if ! grep -q "enable-swift-package-manager: true" "$repo_root/pubspec.yaml"; then
  echo "pubspec.yaml must enable Swift Package Manager for Flutter 3.44 Apple builds"
  exit 1
fi

for platform in ios macos; do
  if ! grep -q "FlutterGeneratedPluginSwiftPackage" "$repo_root/$platform/Runner.xcodeproj/project.pbxproj" ||
    ! grep -q "Run Prepare Flutter Framework Script" "$repo_root/$platform/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"; then
    echo "$platform must commit Flutter's Swift Package Manager integration"
    exit 1
  fi
done

if ! grep -q "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS" "$repo_root/windows/CMakeLists.txt"; then
  echo "windows/CMakeLists.txt must suppress MSVC experimental coroutine deprecation errors"
  exit 1
fi

if ! awk '/--apple-only\)/,/shift/' "$repo_root/build.sh" | grep -q "PARALLEL_BUILD=false"; then
  echo "build.sh must run Apple builds sequentially to avoid CocoaPods/header generation races"
  exit 1
fi

if grep -q "FLUTTER_TARGET_PLATFORM=darwin" "$repo_root/build.sh" ||
  ! grep -q "lipo -archs" "$repo_root/build.sh" ||
  ! grep -q "macos-universal.dmg" "$repo_root/build.sh"; then
  echo "macOS builds must publish one lipo-verified universal DMG"
  exit 1
fi

if ! awk '/^copy_artifacts\(\)/,/^}/' "$repo_root/build.sh" |
  grep -Fq 'if [ "$BUILD_ANDROID" = true ] && [ "$BUILD_ANDROID_ARMV7" = true ]; then'; then
  echo "non-Android builds must not require an Android ARMv7 artifact"
  exit 1
fi

for workflow in "$ci_workflow" "$release_workflow" "$release_assets_workflow" "$rolling_workflow"; do
  if [ ! -f "$workflow" ]; then
    echo "missing workflow: ${workflow#"$repo_root/"}"
    exit 1
  fi

  if grep -E '^[[:space:]]*uses:' "$workflow" |
    grep -Ev 'uses:[[:space:]]+\./\.github/workflows/(ci|release-assets)\.yml$' |
    grep -Ev '@[0-9a-f]{40}([[:space:]]+#.*)?$' >/dev/null; then
    echo "all third-party actions must be pinned to a full commit SHA: ${workflow#"$repo_root/"}"
    exit 1
  fi
done

for artifact_action in upload-artifact download-artifact; do
  action_pin_count="$(
    grep -hE "uses: actions/$artifact_action@[0-9a-f]{40}" \
      "$ci_workflow" "$release_workflow" "$release_assets_workflow" "$rolling_workflow" |
      sed -E "s/.*actions\/$artifact_action@([0-9a-f]{40}).*/\1/" |
      sort -u |
      wc -l |
      tr -d '[:space:]'
  )"
  if [ "$action_pin_count" -ne 1 ]; then
    echo "CI and Release must use one consistent actions/$artifact_action version"
    exit 1
  fi
done

if ! grep -Fq 'artifact-roundtrip:' "$ci_workflow" ||
  ! grep -Fq 'actions/upload-artifact@' "$ci_workflow" ||
  ! grep -Fq 'actions/download-artifact@' "$ci_workflow" ||
  ! grep -Fq 'if-no-files-found: error' "$ci_workflow" ||
  ! grep -Fq 'cmp --silent' "$ci_workflow"; then
  echo "ordinary CI must verify an uploaded artifact can be downloaded unchanged"
  exit 1
fi

if ! grep -q "contents: read" "$ci_workflow" || grep -q "contents: write" "$ci_workflow"; then
  echo "ordinary CI must use read-only repository permissions"
  exit 1
fi

if ! grep -Fq 'workflow_call:' "$ci_workflow"; then
  echo "ordinary CI must be reusable as the release quality gate"
  exit 1
fi

release_ci_job="$(awk '/^  ci:/,/^  build:/' "$release_workflow")"
if ! grep -Fq 'uses: ./.github/workflows/ci.yml' <<<"$release_ci_job"; then
  echo "release workflow must reuse ordinary CI before building release assets"
  exit 1
fi

release_build_job="$(awk '/^  build:/,/^  publish:/' "$release_workflow")"
if ! grep -Fq -- '- validate' <<<"$release_build_job" ||
  ! grep -Fq -- '- ci' <<<"$release_build_job" ||
  ! grep -Fq 'uses: ./.github/workflows/release-assets.yml' <<<"$release_build_job" ||
  ! grep -Fq 'retention_days: 7' <<<"$release_build_job"; then
  echo "formal releases must call the shared build after tag validation and CI"
  exit 1
fi

for required in \
  "tags:" \
  "'v*'" \
  "contents: read" \
  "contents: write" \
  "GH_REPO" \
  "SHA256SUMS.txt" \
  "--verify-tag" \
  "--draft"; do
  if ! grep -Fq -- "$required" "$release_workflow"; then
    echo "release workflow is missing required contract: $required"
    exit 1
  fi
done

if [ ! -f "$android_release_verifier" ] ||
  ! grep -Fq 'scripts/verify_android_release.sh' "$release_assets_workflow" ||
  ! grep -Fq 'verify --print-certs' "$android_release_verifier" ||
  ! grep -Fq 'Could not read the signing certificate' "$android_release_verifier"; then
  echo "Android releases must verify exactly two APK signing certificates"
  exit 1
fi

if ! grep -Fq -- '--licenses' "$release_assets_workflow" ||
  ! grep -Fq 'ndk;29.0.14033849' "$release_assets_workflow" ||
  ! grep -Fq 'find "${ANDROID_SDK_ROOT:-$ANDROID_HOME}/cmdline-tools"' "$release_assets_workflow"; then
  echo "Android releases must accept SDK licenses and install the pinned NDK"
  exit 1
fi

android_job="$(awk '/^  android:/,/^  windows:/' "$release_assets_workflow")"
if ! grep -Fq 'cache: gradle' <<<"$android_job" ||
  ! grep -Fq 'for retry_delay in 0 30 90; do' <<<"$android_job" ||
  ! grep -Fq 'build_status="${PIPESTATUS[0]}"' <<<"$android_job" ||
  ! grep -Fq 'Received status code (429|5[0-9]{2})' <<<"$android_job" ||
  ! grep -Fq 'if ! grep -Eqi "$transient_pattern" "$log_file"; then' <<<"$android_job"; then
  echo "Android releases must cache Gradle dependencies and retry only transient download failures"
  exit 1
fi

if [ ! -f "$windows_ffmpeg_setup" ] ||
  ! grep -Fq 'scripts/prepare_windows_ffmpeg.ps1' "$release_assets_workflow" ||
  ! grep -Fq 'FFMPEGKIT_LOCAL_DIR' "$windows_ffmpeg_setup" ||
  ! grep -Fq 'Expand-Archive' "$windows_ffmpeg_setup"; then
  echo "Windows releases must pre-extract FFmpegKit outside Flutter plugin symlinks"
  exit 1
fi

if grep -Eq 'PULL_TOKEN|REPO_URL|@main' "$release_workflow" "$release_assets_workflow" "$rolling_workflow"; then
  echo "release workflow must not clone another repository or use floating main actions"
  exit 1
fi

macos_job="$(awk '/^  macos:/,0' "$release_assets_workflow")"
if ! grep -Fq 'runs-on: macos-15' <<<"$macos_job" ||
  ! grep -Fq './build.sh --macos-only' <<<"$macos_job" ||
  ! grep -Fq 'name: release-macos' <<<"$macos_job" ||
  ! grep -Fq 'path: dist/selene-*-macos-universal.dmg' <<<"$macos_job" ||
  ! grep -Fq 'if-no-files-found: error' <<<"$macos_job"; then
  echo "release workflow must build and upload one macOS universal DMG"
  exit 1
fi

publish_job="$(awk '/^  publish:/,0' "$release_workflow")"
if ! grep -Fq -- '- build' <<<"$publish_job" ||
  ! grep -Fq '"selene-$APP_VERSION-macos-universal.dmg"' <<<"$publish_job" ||
  ! grep -Fq 'if [ "$asset_count" -ne 5 ]; then' <<<"$publish_job" ||
  ! grep -Fq 'expected 5' <<<"$publish_job"; then
  echo "published releases must contain the macOS DMG and five verified assets"
  exit 1
fi

if awk '/^  android:/,/^    steps:/' "$release_assets_workflow" | grep -q 'secrets\.'; then
  echo "Android signing secrets must be scoped to the exact shell steps that consume them"
  exit 1
fi

if ! grep -q "GradleException" "$repo_root/android/app/build.gradle.kts" ||
  ! grep -q "SELENE_ANDROID_KEYSTORE_PATH" "$repo_root/android/app/build.gradle.kts"; then
  echo "Android CI release builds must fail when explicit signing configuration is missing"
  exit 1
fi

if [ ! -f "$dependabot_config" ] ||
  ! grep -Fq 'package-ecosystem: "github-actions"' "$dependabot_config" ||
  ! grep -Fq 'interval: "weekly"' "$dependabot_config" ||
  ! grep -Fq 'groups:' "$dependabot_config" ||
  ! grep -Fq 'github-actions:' "$dependabot_config" ||
  ! grep -Fq -- '- "*"' "$dependabot_config"; then
  echo "Dependabot must group reviewed weekly updates for pinned GitHub Actions"
  exit 1
fi
