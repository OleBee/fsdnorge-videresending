#!/usr/bin/env bash
# Generate a tadnorge.no redirect tree from a checkout of OleBee/tesla-fsd-norge.
# Usage: generate-redirects.sh <source-dir> <out-dir>
set -euo pipefail

SRC="${1:?source dir}"
OUT="${2:?out dir}"
TARGET_HOST="https://tadnorge.no"

rm -rf "$OUT"
mkdir -p "$OUT"

html_public_path() {
  local rel="$1"
  case "$rel" in
    index.html) printf '%s\n' "/" ;;
    */index.html) printf '/%s/\n' "${rel%/index.html}" ;;
    *) printf '/%s\n' "$rel" ;;
  esac
}

write_redirect() {
  local dest_file="$1"
  local public_path="$2"
  local mode="${3:-path}"
  local target="${TARGET_HOST}${public_path}"
  local js_target="\"${TARGET_HOST}\" + path + location.search + location.hash"
  if [[ "$mode" == fixed ]]; then
    js_target="\"${target}\" + location.hash"
  fi
  mkdir -p "$(dirname "$dest_file")"
  cat > "$dest_file" <<EOF
<!DOCTYPE html>
<html lang="nb">
<head>
<meta charset="utf-8">
<title>Flyttet til tadnorge.no</title>
<link rel="canonical" href="${target}">
<meta http-equiv="refresh" content="0;url=${target}">
<script>
(function () {
  var path = location.pathname || "/";
  path = path.replace(/^\\/fsdnorge-videresending(?=\\/|\$)/, "") || "/";
  location.replace(${js_target});
})();
</script>
</head>
<body>
<p>Siden er flyttet til <a href="${target}">${target}</a>.</p>
</body>
</html>
EOF
}

while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  case "$rel" in
    drafts/*|scripts/*|.github/*) continue ;;
  esac
  public="$(html_public_path "$rel")"
  # Tynne redirect-sider på tadnorge.no (meta refresh til en annen sti):
  # pek canonical og videresending rett på sluttmålet, så Google slipper to hopp.
  refresh="$(grep -oiE '<meta http-equiv="refresh" content="[0-9]+; *url=[^"]+"' "$f" | head -n1 | sed -E 's/.*url=([^"]+)"/\1/' || true)"
  if [[ -n "$refresh" && "$refresh" == /* ]]; then
    write_redirect "$OUT/$rel" "$refresh" fixed
  else
    write_redirect "$OUT/$rel" "$public"
  fi
done < <(find "$SRC" -type f -name '*.html' -print0)

while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  case "$rel" in
    drafts/*|scripts/*) continue ;;
  esac
  mkdir -p "$OUT/$(dirname "$rel")"
  cp -a "$f" "$OUT/$rel"
done < <(find "$SRC" -type f -name '*.json' -print0)

cat > "$OUT/404.html" <<'EOF'
<!DOCTYPE html>
<html lang="nb">
<head>
<meta charset="utf-8">
<title>Flyttet til tadnorge.no</title>
<meta name="robots" content="noindex">
<script>
(function () {
  var path = location.pathname || "/";
  path = path.replace(/^\/fsdnorge-videresending(?=\/|$)/, "") || "/";
  location.replace("https://tadnorge.no" + path + location.search + location.hash);
})();
</script>
</head>
<body>
<p>Siden er flyttet til <a href="https://tadnorge.no/">tadnorge.no</a>.</p>
</body>
</html>
EOF

cat > "$OUT/robots.txt" <<'EOF'
User-agent: *
Allow: /

Sitemap: https://tadnorge.no/sitemap.xml
EOF

: > "$OUT/.nojekyll"

# Optional CNAME from repo root (added at cutover; absent until then)
if [[ -f CNAME ]]; then
  cp -a CNAME "$OUT/CNAME"
  echo "Included CNAME: $(tr -d '[:space:]' < "$OUT/CNAME")"
fi

echo "Generated redirects in $OUT ($(find "$OUT" -type f | wc -l) files)"
