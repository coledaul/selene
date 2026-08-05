#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ci_workflow="$repo_root/.github/workflows/ci.yml"
release_workflow="$repo_root/.github/workflows/release.yml"
build_workflow="$repo_root/.github/workflows/release-assets.yml"
rolling_workflow="$repo_root/.github/workflows/rolling.yml"
pending_version_extractor="$repo_root/scripts/extract_pending_version.sh"

for workflow in "$build_workflow" "$rolling_workflow"; do
  if [ ! -f "$workflow" ]; then
    echo "missing workflow: ${workflow#"$repo_root/"}"
    exit 1
  fi
done

for required in \
  'workflow_run:' \
  'workflows: [CI]' \
  'types: [completed]' \
  'branches: [main]' \
  "github.event.workflow_run.conclusion == 'success'" \
  "github.event.workflow_run.event == 'push'" \
  "github.event.workflow_run.head_branch == 'main'" \
  'github.event.workflow_run.head_sha' \
  "github.event_name == 'workflow_run' && github.event.workflow_run.head_sha || github.sha" \
  'workflow_dispatch:' \
  'group: rolling' \
  'cancel-in-progress: true' \
  'refs/remotes/origin/main' \
  'git merge-base --is-ancestor' \
  'v[0-9]+\.[0-9]+\.[0-9]+' \
  '正式发布提交，跳过 Rolling' \
  'uses: ./.github/workflows/ci.yml' \
  'uses: ./.github/workflows/release-assets.yml' \
  'retention_days: 1' \
  'source_sha: ${{ needs.prepare.outputs.source_sha }}' \
  'version: ${{ needs.prepare.outputs.build_version }}' \
  'ROLLING_VERSION: ${{ needs.prepare.outputs.rolling_version }}' \
  'bash scripts/extract_pending_version.sh CHANGELOG.md' \
  'bash scripts/extract_release_notes.sh "$rolling_version" CHANGELOG.md' \
  'if [ "$notes_status" -eq 2 ]; then' \
  '待发布版本暂无内容，跳过 Rolling' \
  'ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}' \
  'ANDROID_STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}' \
  'ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}' \
  'ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}' \
  'selene-$ROLLING_VERSION-rolling-$SHORT_SHA-armv8.apk' \
  'selene-$ROLLING_VERSION-rolling-$SHORT_SHA-armv7a.apk' \
  'selene-$ROLLING_VERSION-rolling-$SHORT_SHA-windows-x64.zip' \
  'selene-$ROLLING_VERSION-rolling-$SHORT_SHA-macos-universal.dmg' \
  'SHA256SUMS.txt' \
  '--draft' \
  '--prerelease' \
  '--latest=false' \
  '--title "Selene $ROLLING_VERSION Rolling"' \
  'if [ "$asset_count" -ne 5 ]; then'; do
  if ! grep -Fq -- "$required" "$rolling_workflow"; then
    echo "Rolling workflow is missing required contract: $required"
    exit 1
  fi
done

if [ ! -f "$pending_version_extractor" ]; then
  echo "Rolling workflow must use a tested pending changelog version extractor"
  exit 1
fi

if grep -Fq 'GITHUB_SHA' "$rolling_workflow"; then
  echo "Rolling workflow must not use its workflow_run GITHUB_SHA as the source commit"
  exit 1
fi

if ! grep -Fq "github.event_name == 'workflow_dispatch'" "$rolling_workflow" ||
  ! grep -Fq "github.ref == 'refs/heads/main'" "$rolling_workflow"; then
  echo "manual Rolling runs must execute CI and only accept the current main branch"
  exit 1
fi

for required in \
  'workflow_call:' \
  'source_sha:' \
  'version:' \
  'retention_days:' \
  'android_signing_cert_sha256:' \
  'ANDROID_KEYSTORE_BASE64:' \
  'ANDROID_STORE_PASSWORD:' \
  'ANDROID_KEY_ALIAS:' \
  'ANDROID_KEY_PASSWORD:' \
  'ref: ${{ inputs.source_sha }}' \
  'retention-days: ${{ inputs.retention_days }}' \
  'ANDROID_SIGNING_CERT_SHA256: ${{ inputs.android_signing_cert_sha256 }}' \
  'keytool -list -v' \
  'ndk;29.0.14033849' \
  './build.sh --android-only' \
  './build.sh --macos-only' \
  'macos-universal.dmg' \
  'name: release-android' \
  'name: release-windows' \
  'name: release-macos'; do
  if ! grep -Fq -- "$required" "$build_workflow"; then
    echo "reusable release build is missing required contract: $required"
    exit 1
  fi
done

for caller in "$release_workflow" "$rolling_workflow"; do
  if ! grep -Fq 'uses: ./.github/workflows/release-assets.yml' "$caller"; then
    echo "formal and Rolling releases must share the reusable build workflow: ${caller#"$repo_root/"}"
    exit 1
  fi
  if grep -Fq 'secrets: inherit' "$caller"; then
    echo "release callers must pass signing secrets individually: ${caller#"$repo_root/"}"
    exit 1
  fi
done

if ! grep -Fq 'source_sha: ${{ needs.validate.outputs.source_sha }}' "$release_workflow" ||
  ! grep -Fq 'retention_days: 7' "$release_workflow"; then
  echo "formal releases must build the validated tag commit and retain artifacts for seven days"
  exit 1
fi

for required in \
  'pending_version="$(bash scripts/extract_pending_version.sh CHANGELOG.md)"' \
  '^## \[$version\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$'; do
  if ! grep -Fq -- "$required" "$release_workflow"; then
    echo "formal releases must validate the pending section and dated release section: $required"
    exit 1
  fi
done

cleanup_job="$(awk '/^  cleanup-rolling:/,0' "$release_workflow")"
for required in \
  'needs: publish' \
  'contents: write' \
  'git merge-base --is-ancestor "$rolling_commit" "$release_commit"' \
  'gh release delete rolling' \
  ':refs/tags/rolling' \
  'Rolling 不存在，无需清理' \
  'Rolling 指向正式版本之后的提交，保留'; do
  if ! grep -Fq -- "$required" <<<"$cleanup_job"; then
    echo "formal release cleanup is missing required contract: $required"
    exit 1
  fi
done

rolling_publish_job="$(awk '/^  publish:/,0' "$rolling_workflow")"
for mutation_job in "$rolling_publish_job" "$cleanup_job"; do
  if ! grep -Fq 'group: rolling-release-mutation' <<<"$mutation_job" ||
    ! grep -Fq 'cancel-in-progress: false' <<<"$mutation_job"; then
    echo "Rolling publish and formal cleanup must share a non-canceling mutation concurrency group"
    exit 1
  fi
done

if ! grep -Fq 'bash test/rolling_release_config_test.sh' "$ci_workflow"; then
  echo "ordinary CI must run the Rolling release workflow contract test"
  exit 1
fi

if ! grep -Fq 'bash test/extract_pending_version_test.sh' "$ci_workflow"; then
  echo "ordinary CI must test pending changelog version extraction"
  exit 1
fi
