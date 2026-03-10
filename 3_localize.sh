#!/bin/bash
perl -0777 -i -pe 's/href="https:\/\/truyenxxx\.net\/amp\.html"/href="amp.html"/mg' truyenxxx.net/index.html

# find . -type f -name "*.html" -mindepth 2 -maxdepth 2 -exec dos2unix {} \; -exec perl -0777 -i -pe 's/href="https:\/\/truyenxxx\.net\/((?!amp\.html)[^"]+\/)?"/href="$1index.html"/mg' {} \;
# find . -type f -name "*.html" -mindepth 3 -maxdepth 3 -exec dos2unix {} \; -exec perl -0777 -i -pe 's/href="https:\/\/truyenxxx\.net\/((?!amp\.html)[^"]+\/)?"/href="..\/$1index.html"/mg' {} \;
# find . -type f -name "*.html" -mindepth 4 -maxdepth 4 -exec dos2unix {} \; -exec perl -0777 -i -pe 's/href="https:\/\/truyenxxx\.net\/((?!amp\.html)[^"]+\/)?"/href="..\/..\/$1index.html"/mg' {} \;
# find . -type f -name "*.html" -mindepth 5 -maxdepth 5 -exec dos2unix {} \; -exec perl -0777 -i -pe 's/href="https:\/\/truyenxxx\.net\/((?!amp\.html)[^"]+\/)?"/href="..\/..\/..\/$1index.html"/mg' {} \;
# find . -type f -name "*.html" -mindepth 6 -maxdepth 6 -exec dos2unix {} \; -exec perl -0777 -i -pe 's/href="https:\/\/truyenxxx\.net\/((?!amp\.html)[^"]+\/)?"/href="..\/..\/..\/..\/$1index.html"/mg' {} \;

set -euo pipefail
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
git config core.quotepath false

# REQUIREMENTS:
#   brew install gawk
#   macOS xargs (supports -0)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 1️⃣ Collect staged, unstaged, and untracked files
{
  git diff --name-only --cached
  git diff --name-only
  git ls-files -o --exclude-standard
} \
| sort -u \
| awk -F'/' 'NF >= 2 && /\.html$/ { print NF "\t" $0 }' \
| sort -n \
| awk -F'\t' '
    {
      depth = $1
      file  = $2
      print file >> ("'"$tmpdir"'/depth_" depth ".list")
    }
'

# 2️⃣ Batch-process per depth
for f in "$tmpdir"/depth_*.list; do
  [ -s "$f" ] || continue   # skip if file does not exist or is empty

  depth="${f##*/depth_}"
  depth="${depth%.list}"

  file_count=$(wc -l < "$f" | tr -d ' ')

  if [ "$file_count" -eq 0 ]; then
    echo "Skipping depth=$depth (0 files)"
    continue
  fi

  up=""
  for ((i=0;i<depth-2;i++)); do up+="../"; done

  echo "Processing depth=$depth (${file_count} file(s), ../ x $((depth-2)))"

  # xargs -n 100 dos2unix < "$f"
  xargs -n 100 \
    perl -0777 -i -pe \
    "s#href=\"https://truyenxxx\.net/((?!amp\.html)[^\"]+/)?\"#href=\"${up}\$1index.html\"#mg" \
    < "$f"
done

cd truyenxxx.net && git status .
