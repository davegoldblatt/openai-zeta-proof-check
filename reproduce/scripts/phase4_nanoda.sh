#!/usr/bin/env bash
# Phase 4: comparator again, against the verifier-written challenge, with the nanoda kernel
# enabled in addition to Lean's built-in kernel. Run as `verifier`.
set -uo pipefail
OUT=/home/verifier/work/evidence
RUN=run3-nanoda
cd /home/verifier/work/openai-math/lean
test "$(id -u)" != 0
install -m 0644 /opt/qrh-verifier/VerifierQuasiRiemannHypothesis.lean ComparatorChallenges/VerifierQuasiRiemannHypothesis.lean
install -m 0644 /opt/qrh-verifier/verifier-qrh-nanoda.json verifier-qrh-nanoda.json
sha256sum ComparatorChallenges/VerifierQuasiRiemannHypothesis.lean verifier-qrh-nanoda.json /usr/local/bin/nanoda_bin | tee "$OUT/verifier-inputs.sha256"
export COMPARATOR_LANDRUN=/opt/qrh-scripts/landrun-threads.sh
export COMPARATOR_LEAN4EXPORT=/usr/local/bin/lean4export
export COMPARATOR_NANODA=/usr/local/bin/nanoda_bin
export QRH_LEAN_THREADS=4
echo "[$(date -u +%FT%TZ)] run=$RUN comparator start threads=$QRH_LEAN_THREADS" | tee -a "$OUT/phase4.timeline"
( while true; do
    printf '%s current=%s peak=%s swap=%s swap_peak=%s %s\n' "$(date -u +%FT%TZ)" \
      "$(cat /sys/fs/cgroup/memory.current)" "$(cat /sys/fs/cgroup/memory.peak)" \
      "$(cat /sys/fs/cgroup/memory.swap.current)" "$(cat /sys/fs/cgroup/memory.swap.peak)" \
      "$(grep -E '^(max|oom|oom_kill) ' /sys/fs/cgroup/memory.events | tr '\n' ' ')"
    sleep 30
  done >> "$OUT/cgroup-mem.$RUN.log" 2>&1 ) &
/usr/bin/time -v -o "$OUT/comparator.$RUN.time" \
  lake env /usr/local/bin/comparator verifier-qrh-nanoda.json > "$OUT/comparator.$RUN.log" 2>&1
rc=$?
echo "[$(date -u +%FT%TZ)] run=$RUN comparator exit=$rc" | tee -a "$OUT/phase4.timeline"
exit $rc
