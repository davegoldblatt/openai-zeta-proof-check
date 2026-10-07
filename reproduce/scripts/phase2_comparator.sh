#!/usr/bin/env bash
# Phase 2: the official comparator check, run as `verifier`.
set -uo pipefail
OUT=/home/verifier/work/evidence
RUN=${RUN:?set RUN}
: "${QRH_LEAN_THREADS:?set QRH_LEAN_THREADS}"
cd /home/verifier/work/openai-math/lean
test "$(id -u)" != 0
export COMPARATOR_LANDRUN=/opt/qrh-scripts/landrun-threads.sh
export COMPARATOR_LEAN4EXPORT=/usr/local/bin/lean4export
echo "[$(date -u +%FT%TZ)] run=$RUN comparator start threads=$QRH_LEAN_THREADS" | tee -a "$OUT/phase2.timeline"
# Whole-container memory record (cgroup v2), every 30 s.
( while true; do
    printf '%s current=%s peak=%s swap=%s swap_peak=%s %s\n' "$(date -u +%FT%TZ)" \
      "$(cat /sys/fs/cgroup/memory.current)" "$(cat /sys/fs/cgroup/memory.peak)" \
      "$(cat /sys/fs/cgroup/memory.swap.current)" "$(cat /sys/fs/cgroup/memory.swap.peak)" \
      "$(grep -E '^(max|oom|oom_kill) ' /sys/fs/cgroup/memory.events | tr '\n' ' ')"
    sleep 30
  done >> "$OUT/cgroup-mem.$RUN.log" 2>&1 ) &
/usr/bin/time -v -o "$OUT/comparator.$RUN.time" \
  lake env /usr/local/bin/comparator ComparatorChallenges/QuasiRiemannHypothesis.json > "$OUT/comparator.$RUN.log" 2>&1
rc=$?
echo "[$(date -u +%FT%TZ)] run=$RUN comparator exit=$rc" | tee -a "$OUT/phase2.timeline"
exit $rc
