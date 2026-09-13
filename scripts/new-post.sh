#!/usr/bin/env sh
# Create a new dated draft post: content/posts/YYYY-MM-DD-<slug>.md
set -eu

title="$1"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//')
file="content/posts/$(date +%F)-${slug}.md"

if [ -z "$slug" ]; then
  echo "usage: just new-post \"My Post Title\"" >&2
  exit 1
fi
if [ -e "$file" ]; then
  echo "already exists: $file" >&2
  exit 1
fi

cat >"$file" <<EOF
---
template: blog-page.html
title: "$title"
date: $(date -u +%FT%TZ)
draft: true
---

EOF

echo "Created $file (draft). Edit it, then run: just serve"
