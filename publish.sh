#!/usr/bin/env bash
# Publish a new week of the Triangle Film Brief.
#
# Run from the repo root AFTER index.html has been rewritten for the new week.
# Archives the new index, adds it to the archive list, commits, and pushes.
#
#   bash publish.sh <YYYY-MM-DD> "<week label>" "<one-line blurb>"
#
# Example:
#   bash publish.sh 2026-07-31 "Week of July 31 - August 6, 2026" \
#     "Muppet Movie + Dark Crystal retro double; Rocky Horror at the Rialto"
#
# <YYYY-MM-DD> is the Friday the week starts on, and becomes the archive filename.

set -euo pipefail

DATE="${1:?need a date, YYYY-MM-DD}"
LABEL="${2:?need a week label}"
BLURB="${3:-}"

if ! [[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "error: date must look like 2026-07-31" >&2
  exit 1
fi

cd "$(dirname "$0")"

if [[ ! -f index.html ]]; then
  echo "error: no index.html here. Rewrite it for the new week first." >&2
  exit 1
fi

mkdir -p archive

if [[ -f "archive/$DATE.html" ]]; then
  echo "note: archive/$DATE.html already exists, overwriting it"
fi

# Archive a copy. The only fixup is the "Past weeks" link: it points at
# archive/ from the site root, but must point at ./ from inside archive/.
sed 's|href="archive/"|href="./"|' index.html > "archive/$DATE.html"

# Prepend an entry to the archive list, unless this date is already listed.
DATE="$DATE" LABEL="$LABEL" BLURB="$BLURB" python3 - <<'PY'
import html, os, sys, re

date  = os.environ["DATE"]
label = html.escape(os.environ["LABEL"])
blurb = html.escape(os.environ["BLURB"])

path = "archive/index.html"
with open(path, encoding="utf-8") as f:
    doc = f.read()

marker = "<!-- ARCHIVE-LIST-TOP -->"
if marker not in doc:
    sys.exit(f"error: {path} is missing {marker}")

if f'href="{date}.html"' in doc:
    print(f"archive list already has {date}, leaving it alone")
    sys.exit(0)

entry = f'<li><a href="{date}.html">{label}</a>'
if blurb:
    entry += f'\n<div class="meta">{blurb}</div>'
entry += "</li>"

doc = doc.replace(marker, marker + "\n" + entry, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(doc)
print(f"added {date} to the archive list")
PY

git add index.html archive
if git diff --cached --quiet; then
  echo "nothing changed, not committing"
  exit 0
fi

git commit -m "Film brief: week of $DATE"
git push origin main

echo
echo "pushed. LXC 102 pulls within 10 minutes -> https://film.pilesofcr.app"
