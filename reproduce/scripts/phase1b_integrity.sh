#!/usr/bin/env bash
# Phase 1b (inside the container as `verifier`, after phase 1, BEFORE any proof code is
# compiled): check that the trusted side is genuine, and capture the challenge export.
set -uo pipefail

OUT=/home/verifier/work/evidence
cd /home/verifier/work/openai-math/lean
PKG=.lake/packages

echo "== package checkouts vs manifest (HEAD, origin, dirty files)"
python3 -I - lake-manifest.json "$PKG" <<'EOF' | tee "$OUT/packages-state.txt"
import json, subprocess, sys
man, pkgdir = sys.argv[1], sys.argv[2]
def git(d, *a):
    r = subprocess.run(["git", "-C", d, *a], capture_output=True, text=True)
    return r.stdout.strip()
for p in json.load(open(man))["packages"]:
    d = f"{pkgdir}/{p['name'].strip('«»')}"
    head = git(d, "rev-parse", "HEAD")
    origin = git(d, "remote", "get-url", "origin")
    dirty = git(d, "status", "--porcelain", "--untracked-files=no")
    ndirty = len(dirty.splitlines()) if dirty else 0
    ok = head == p["rev"]
    print(f"{p['name']:30} head_ok={ok} dirty_tracked_files={ndirty:<5} origin={origin}")
EOF

echo "== Mathlib and its own dependencies must be pristine"
for d in mathlib batteries aesop Qq proofwidgets importGraph LeanSearchClient plausible Cli; do
  st=$(git -C "$PKG/$d" status --porcelain --untracked-files=all -- . ':(exclude).lake' 2>&1)
  echo "$d: HEAD=$(git -C "$PKG/$d" rev-parse HEAD) tag=$(git -C "$PKG/$d" describe --tags --exact-match 2>/dev/null || echo -) status=[${st:-clean}]"
done | tee "$OUT/mathlib-pristine.txt"

echo "== which packages ship executable lakefile.lean configs"
for d in "$PKG"/*/; do
  n=$(basename "$d")
  if [ -f "$d/lakefile.lean" ]; then
    hits=$(grep -n -E "run_cmd|run_elab|initialize|IO\.Process|IO\.FS\.(write|remove|createDir|rename)|post_update|extern|moreLeanArgs|moreServerArgs|plugins|loadDynlib|precompileModules|weakLeanArgs" "$d/lakefile.lean" | tr '\n' ' ')
    echo "$n: lakefile.lean :: ${hits:-no code-execution hooks found}"
  fi
done | tee "$OUT/lakefiles.txt"

echo "== modules named Mathlib.* (or other Mathlib-dependency roots) provided outside their home package"
ROOTS="Mathlib Batteries Aesop Qq ProofWidgets ImportGraph LeanSearchClient Plausible Cli"
{
  for d in "$PKG"/*/; do
    n=$(basename "$d")
    case "$n" in mathlib|batteries|aesop|Qq|proofwidgets|importGraph|LeanSearchClient|plausible|Cli) continue;; esac
    for root in $ROOTS; do
      if [ -e "$d/$root.lean" ] || [ -d "$d/$root" ]; then echo "SHADOW RISK: $n provides $root"; fi
    done
  done
  for root in $ROOTS; do
    if [ -e "$root.lean" ] || [ -d "$root" ]; then echo "SHADOW RISK: root package provides $root"; fi
  done
} > "$OUT/shadowing.txt"
findings=$(grep -c '^SHADOW RISK' "$OUT/shadowing.txt")
if [ "$findings" -eq 0 ]; then
  # Write an explicit line so the evidence file is never empty.
  echo "NO FINDINGS: no package outside Mathlib's own dependency set, and not the root package, provides a module root named $(echo "$ROOTS" | sed 's/ /, /g')" >> "$OUT/shadowing.txt"
fi
cat "$OUT/shadowing.txt"
echo "shadowing check done ($findings findings)"

echo "== challenge import closure as built"
lake env printenv LEAN_PATH | tr ':' '\n' | tee "$OUT/lean-path.txt"
