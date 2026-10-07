# Audit request: check a verification report against its evidence

You are auditing another AI agent's report. The agent ran an independent check of a Lean 4 proof
published by OpenAI (repository openai/math, commit adc7f1241b42e322a6451854ab7e4b4c146bf78a): the
theorem `OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re`, which says the Riemann zeta function has no
zeros with real part greater than 7/8. The check used Lean FRO's `comparator` tool in a Linux
container, then printed the theorem's axioms.

Note: the proof was produced by an OpenAI model, and you are an OpenAI model. Judge only whether the
report's claims follow from the evidence in this folder.

## Your job

Find every place where the report (DRAFT_REPORT.md) says something the evidence does not support, or
leaves out something the evidence shows. In particular:

1. Verdict. The user's pass rule: comparator exits 0 AND prints "Your solution is okay!", AND
   `#print axioms` lists exactly `propext`, `Quot.sound`, `Classical.choice`. Any `sorryAx` or
   `Lean.ofReduceBool` is a fail. Out-of-memory, dependency build errors, or interrupted runs are
   "incomplete", not "fail". Does the evidence meet the rule the report says it meets?
2. Statement. Does the evidence show the theorem is about Mathlib's `_root_.riemannZeta` with the
   hypothesis `(7 / 8 : ℝ) < s.re`?
3. Axiom list. Is the reported list exactly what the log printed?
4. Times. Recompute every duration in the report from the timestamps and `/usr/bin/time` files.
5. Errors and warnings. Search all logs. Did the report miss or mischaracterize any error, warning,
   `sorry`, or abnormal exit?
6. Trust assumptions. Compare the report's list of deviations from comparator's stated assumptions
   (comparator-pinned/README.md) with what the setup files and logs show was actually done. Flag any
   deviation that is missing, overstated, or understated. Example: the check ran in two parts (a
   paused first run and a resumed second run); is that reported accurately?
7. Anything else a careful reviewer would challenge.

The user has said they are not worried about deliberate attacks on the checking machine. Do not
recommend anti-tampering hardening. Do report trust-assumption deviations accurately.

## Folder layout

- DRAFT_REPORT.md: the report under audit.
- evidence/: raw logs and timing files. Key files: phase1.timeline, phase2.timeline,
  comparator.run1.log (paused run), comparator.run2.log (the run that finished),
  comparator.run2.time, cgroup-mem.run2.log, axioms.log, AxiomCheck.lean, lake-update.log,
  cache-get.log, trusted-build.log, packages-state.txt, mathlib-pristine.txt, phase1b.log.
- project/: the challenge file, its JSON config, the solution file, the project's lakefile and manifest.
- comparator-pinned/: comparator's README and source at the pinned commit d03acab.
- setup/: Dockerfile, the scripts that ran each phase, the landrun wrapper, the seccomp change.

## Output

A numbered list of findings, most serious first. For each finding: the report's claim (quote it), the
evidence (file and line, quoted), why they disagree, and the fix. Then one line: "Report supported as
written", "Report supported with the fixes above", or "Report not supported".
Read only. Do not modify files.
