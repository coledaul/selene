#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ci_workflow="$repo_root/.github/workflows/ci.yml"
release_workflow="$repo_root/.github/workflows/release.yml"
dependabot_config="$repo_root/.github/dependabot.yml"
windows_ffmpeg_setup="$repo_root/scripts/prepare_windows_ffmpeg.ps1"

locked_sources="$(sed -n 's/^[[:space:]]*url: "\([^"]*\)"/\1/p' "$repo_root/pubspec.lock" | sort -u)"
if [ "$(printf '%s\n' "$locked_sources" | sed '/^$/d' | wc -l | tr -d ' ')" -ne 1 ]; then
  echo "pubspec.lock must use one consistent hosted package source"
  exit 1
fi

for dependency_entrypoint in "$repo_root/build.sh" "$ci_workflow" "$release_workflow"; do
  if ! grep -Fq 'flutter pub get --enforce-lockfile' "$dependency_entrypoint"; then
    echo "dependency resolution must enforce pubspec.lock: ${dependency_entrypoint#"$repo_root/"}"
    exit 1
  fi
done

for workflow in "$ci_workflow" "$release_workflow"; do
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

for workflow in "$ci_workflow" "$release_workflow"; do
  if [ ! -f "$workflow" ]; then
    echo "missing workflow: ${workflow#"$repo_root/"}"
    exit 1
  fi

  if grep -E '^[[:space:]]*uses:' "$workflow" | grep -Ev '@[0-9a-f]{40}([[:space:]]+#.*)?$' >/dev/null; then
    echo "all third-party actions must be pinned to a full commit SHA: ${workflow#"$repo_root/"}"
    exit 1
  fi
done

if ! grep -q "contents: read" "$ci_workflow" || grep -q "contents: write" "$ci_workflow"; then
  echo "ordinary CI must use read-only repository permissions"
  exit 1
fi

for required in \
  "tags:" \
  "'v*'" \
  "contents: read" \
  "contents: write" \
  "ANDROID_KEYSTORE_BASE64" \
  "ANDROID_SIGNING_CERT_SHA256" \
  "GH_REPO" \
  "verify --print-certs" \
  "SHA256SUMS.txt" \
  "--verify-tag" \
  "--draft"; do
  if ! grep -Fq -- "$required" "$release_workflow"; then
    echo "release workflow is missing required contract: $required"
    exit 1
  fi
done

if ! grep -Fq 'sdkmanager --licenses' "$release_workflow" ||
  ! grep -Fq 'ndk;29.0.14033849' "$release_workflow"; then
  echo "Android releases must accept SDK licenses and install the pinned NDK"
  exit 1
fi

if [ ! -f "$windows_ffmpeg_setup" ] ||
  ! grep -Fq 'scripts/prepare_windows_ffmpeg.ps1' "$release_workflow" ||
  ! grep -Fq 'FFMPEGKIT_LOCAL_DIR' "$windows_ffmpeg_setup" ||
  ! grep -Fq 'Expand-Archive' "$windows_ffmpeg_setup"; then
  echo "Windows releases must pre-extract FFmpegKit outside Flutter plugin symlinks"
  exit 1
fi

if grep -Eq 'PULL_TOKEN|REPO_URL|@main' "$release_workflow"; then
  echo "release workflow must not clone another repository or use floating main actions"
  exit 1
fi

if awk '/^  android:/,/^    steps:/' "$release_workflow" | grep -q 'secrets\.'; then
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
  ! grep -Fq 'interval: "weekly"' "$dependabot_config"; then
  echo "Dependabot must propose reviewed weekly updates for pinned GitHub Actions"
  exit 1
fi
