#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 path/to/App.ipa"
  exit 2
fi

ipa_path="$1"

if [ ! -f "$ipa_path" ]; then
  echo "error: IPA not found: ${ipa_path}"
  exit 1
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/manen-ipa-audio.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

unzip -q "$ipa_path" -d "$tmp_dir"
app_dir=$(find "$tmp_dir/Payload" -maxdepth 1 -type d -name "*.app" | head -n 1)

if [ -z "$app_dir" ]; then
  echo "error: No .app bundle found inside IPA: ${ipa_path}"
  exit 1
fi

audio_files="
focus_loop.m4a
relax_loop.m4a
sleep_loop.m4a
productivity_cue.m4a
"

for filename in $audio_files; do
  file_path="${app_dir}/${filename}"

  if [ ! -f "$file_path" ]; then
    echo "error: Missing audio asset in IPA: ${filename}"
    exit 1
  fi

  byte_count=$(wc -c < "$file_path" | tr -d ' ')

  if [ "$byte_count" -lt 1000 ]; then
    echo "error: Audio asset in IPA is too small: ${filename}"
    exit 1
  fi

  if head -c 64 "$file_path" | LC_ALL=C grep -q "version https://git-lfs.github.com/spec/v1"; then
    echo "error: IPA contains a Git LFS pointer instead of real audio: ${filename}"
    exit 1
  fi
done

echo "Verified IPA audio assets."
