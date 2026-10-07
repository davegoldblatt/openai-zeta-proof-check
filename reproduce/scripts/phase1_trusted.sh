#!/usr/bin/env bash
# Phase 1 (runs inside the container as `verifier`): fetch the project, resolve and
# patch dependencies, fetch the Mathlib cache, and build ONLY the trusted challenge.
# No OpenAI proof code is compiled here.
set -euo pipefail

WORK=/home/verifier/work
OUT=/home/verifier/work/evidence
COMMIT=adc7f1241b42e322a6451854ab7e4b4c146bf78a
mkdir -p "$OUT"
stamp() { date -u +%FT%TZ; }
log() { echo "[$(stamp)] $*" | tee -a "$OUT/phase1.timeline"; }

id | tee "$OUT/phase1.id"
test "$(id -u)" != 0

log "clone start"
if [ ! -d "$WORK/openai-math/.git" ]; then
  git clone --filter=blob:none --no-checkout https://github.com/openai/math.git "$WORK/openai-math"
  git -C "$WORK/openai-math" sparse-checkout set --cone lean
  git -C "$WORK/openai-math" checkout --detach "$COMMIT"
fi
test "$(git -C "$WORK/openai-math" rev-parse HEAD)" = "$COMMIT"
log "clone done: $(git -C "$WORK/openai-math" rev-parse HEAD)"

cd "$WORK/openai-math/lean"
cat lean-toolchain | tee "$OUT/lean-toolchain.txt"
which lean lake git | tee "$OUT/which.txt"
lean --version | tee -a "$OUT/which.txt"
cp lake-manifest.json "$OUT/lake-manifest.before.json"
sha256sum lakefile.lean lake-manifest.json patches/*.patch > "$OUT/inputs.sha256"

log "lake update start"
/usr/bin/time -v -o "$OUT/lake-update.time" lake update > "$OUT/lake-update.log" 2>&1
log "lake update done"
cp lake-manifest.json "$OUT/lake-manifest.after.json"
if cmp -s "$OUT/lake-manifest.before.json" "$OUT/lake-manifest.after.json"; then
  log "manifest unchanged by lake update"
else
  log "MANIFEST CHANGED by lake update"
  diff "$OUT/lake-manifest.before.json" "$OUT/lake-manifest.after.json" > "$OUT/lake-manifest.diff" || true
fi

log "cache get start"
/usr/bin/time -v -o "$OUT/cache-get.time" lake exe cache get > "$OUT/cache-get.log" 2>&1
log "cache get done"

log "trusted build start"
/usr/bin/time -v -o "$OUT/trusted-build.time" \
  lake build ComparatorChallenges.QuasiRiemannHypothesis > "$OUT/trusted-build.log" 2>&1
log "trusted build done"
