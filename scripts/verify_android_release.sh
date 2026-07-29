#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Exactly two Android release APKs are required" >&2
  exit 1
fi

expected="$(printf '%s' "${ANDROID_SIGNING_CERT_SHA256:-}" | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')"
if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
  echo "ANDROID_SIGNING_CERT_SHA256 must contain one SHA-256 fingerprint" >&2
  exit 1
fi

android_sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [ -z "$android_sdk" ]; then
  echo "Android SDK root is not configured" >&2
  exit 1
fi

apksigner="$(find "$android_sdk/build-tools" -type f -name apksigner -print | sort -V | tail -n 1)"
if [ -z "$apksigner" ] || [ ! -x "$apksigner" ]; then
  echo "Android apksigner was not found" >&2
  exit 1
fi

for apk in "$@"; do
  if [ ! -f "$apk" ]; then
    echo "Android release APK was not found: $apk" >&2
    exit 1
  fi

  output="$("$apksigner" verify --print-certs "$apk")"
  actual="$(printf '%s\n' "$output" | sed -n 's/^.*certificate SHA-256 digest:[[:space:]]*//p' | head -n 1 | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')"
  if [ -z "$actual" ]; then
    echo "Could not read the signing certificate from $(basename "$apk")" >&2
    exit 1
  fi
  if [ "$actual" != "$expected" ]; then
    echo "Unexpected signing certificate for $(basename "$apk"): $actual" >&2
    exit 1
  fi
done
