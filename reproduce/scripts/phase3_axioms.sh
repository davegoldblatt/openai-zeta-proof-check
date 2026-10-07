#!/usr/bin/env bash
# Phase 3 (only after comparator has finished): the statement check against Mathlib's
# _root_.riemannZeta and the exact axiom list, in a scratch file importing only the solution.
set -uo pipefail
OUT=/home/verifier/work/evidence
SCRATCH=/home/verifier/work/scratch
mkdir -p "$SCRATCH"
cat > "$SCRATCH/AxiomCheck.lean" <<'EOF'
import OAI.NumberTheory.DirichletL.Nonvanishing

example {s : ℂ} (hs : (7 / 8 : ℝ) < s.re) : _root_.riemannZeta s ≠ 0 :=
  OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re hs

#print axioms OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re
EOF
cp "$SCRATCH/AxiomCheck.lean" "$OUT/AxiomCheck.lean"
cd /home/verifier/work/openai-math/lean
echo "[$(date -u +%FT%TZ)] axiom check start" | tee -a "$OUT/phase3.timeline"
/usr/bin/time -v -o "$OUT/axioms.time" lake env lean "$SCRATCH/AxiomCheck.lean" > "$OUT/axioms.log" 2>&1
rc=$?
echo "[$(date -u +%FT%TZ)] axiom check exit=$rc" | tee -a "$OUT/phase3.timeline"
grep -v "has local changes" "$OUT/axioms.log"
exit $rc
