#!/bin/sh
set -eu

project_root="${SRCROOT:-$(pwd)}"

audio_files="
Fordybelse/Resources/Audio/focus_loop.m4a
Fordybelse/Resources/Audio/relax_loop.m4a
Fordybelse/Resources/Audio/sleep_loop.m4a
Fordybelse/Resources/Sounds/productivity_cue.m4a
"

for relative_path in $audio_files; do
  file_path="${project_root}/${relative_path}"

  if [ ! -f "$file_path" ]; then
    echo "error: Missing bundled audio asset: ${relative_path}"
    exit 1
  fi

  byte_count=$(wc -c < "$file_path" | tr -d ' ')

  if [ "$byte_count" -lt 1000 ]; then
    echo "error: Audio asset is too small and is probably a Git LFS pointer: ${relative_path}"
    echo "error: Run: git lfs pull"
    exit 1
  fi

  if head -c 64 "$file_path" | LC_ALL=C grep -q "version https://git-lfs.github.com/spec/v1"; then
    echo "error: Audio asset is a Git LFS pointer instead of real audio: ${relative_path}"
    echo "error: Run: git lfs pull"
    exit 1
  fi
done

echo "Verified bundled audio assets."
