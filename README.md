# Independent check of OpenAI's Lean proof that ζ(s) ≠ 0 for Re(s) > 7/8

## In plain English

OpenAI published a computer-checked proof about the Riemann zeta function, a central object in number
theory. The proof says the function has no zeros whose real part is greater than 7/8. The famous Riemann
Hypothesis says all its nontrivial zeros have real part exactly 1/2. Mathematicians proved long ago that there
are none with real part 1 or more. As far as we know, no strip to the left of 1 had been ruled out before
OpenAI's work on this problem. If correct, this result rules out the strip between 7/8 and 1. That is a real
step toward the Riemann Hypothesis, though far from a proof of it, and it sharpens what can be proven about how
the prime numbers are spread out.

The proof is written in Lean, a programming language for mathematics. In Lean, a small trusted program called
the kernel checks every logical step. OpenAI's proof is large: about 2,900 files and 486,000 lines.

We re-ran the official check from OpenAI's public code, on our own machine. Lean's checker accepted the proof.
We then wrote our own copy of the statement, to confirm the proof proves exactly what it claims, and had a
second, independently written checker go through every step. Both checkers accepted it. The proof relies only on
the three standard axioms that ordinary mathematics in Lean uses, and on no shortcuts that skip checking.

What this means: unless both checkers have the same bug, the statement as written in Lean's standard math
library is proven. What it does not mean: this is not a review of OpenAI's accompanying paper, and it was run by one
operator on one machine, so independent reproductions would add weight.

## The details

This repository records an independent re-run of the Lean check for this theorem from
[openai/math](https://github.com/openai/math) at commit `adc7f1241b42e322a6451854ab7e4b4c146bf78a`
(Lean v4.34.1, Mathlib v4.34.1):

```lean
theorem OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re
    {s : ℂ} (hs : (7 / 8 : ℝ) < s.re) : riemannZeta s ≠ 0
```

## Result: the proof checks

| Check | Output |
| --- | --- |
| Lean FRO's [comparator](https://github.com/leanprover/comparator) with OpenAI's challenge and config | `Lean default kernel accepts the solution`, `Your solution is okay!`, exit 0 |
| comparator with a challenge and config written for this check, plus the independent [nanoda](https://github.com/ammkrn/nanoda_lib) kernel | `nanoda kernel accepts the solution`, `Lean default kernel accepts the solution`, `Your solution is okay!`, exit 0 |
| `#print axioms OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re` | `[propext, Classical.choice, Quot.sound]` |
| `example … : _root_.riemannZeta s ≠ 0 := OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re hs` | elaborates |

Two independent kernel implementations, Lean's own and nanoda (written in Rust), accept a proof of the
statement from Mathlib's definitions using only Lean's three standard axioms. The statement uses Mathlib's
root-level `riemannZeta`.

The theorem also covers s = 1, where Mathlib gives `riemannZeta` a conventional value. Mathlib already proves
that value is nonzero and already proves `riemannZeta s ≠ 0` for `1 ≤ s.re`, so the new content is the strip
7/8 < Re(s) < 1.

## What this does not establish

- One operator ran both checks, on one machine. Nobody has yet reproduced it independently from a fresh clone.
- The check assumes OpenAI's repository is not adversarial. The project's build configuration and its 23
  dependency patches are OpenAI's, and they run outside comparator's sandbox during setup. OpenAI's challenge
  file and config were read by hand, and the second run used a challenge written for this check.
- comparator's README recommends a systemd wrapper. A container rule stood in for it.
- OpenAI's configs leave the second kernel off (402 of 405 set it to false). The second run turned it on.
- This covers the Lean proof only, not the accompanying paper.

Full details: [REPORT.md](REPORT.md).

## How it was run

- comparator `d03acab` and lean4export `076e8e5` (their `v4.34.0` tags, rebuilt with Lean 4.34.1),
  landrun `811cfff` (main), nanoda `3a24072` (master).
- Docker on Apple Silicon, Linux 6.12.76, Ubuntu 24.04 image, unprivileged user, no network for the checks.
- The proof closure is 2,924 OpenAI modules (486,490 lines) plus 19 modules from two outside libraries, built on
  Mathlib's prebuilt cache. Compiling took about 63 minutes. comparator's export, comparison and kernel replay
  took 8 min 23 s. The second-kernel run took 14 min 17 s.
- No errors. No warnings from any of OpenAI's proof modules.

To reproduce: [reproduce/RUNBOOK.md](reproduce/RUNBOOK.md). Raw logs: [evidence/](evidence/).

## Reviews of this report

- An OpenAI model (gpt-6-astra, via Codex, read-only) audited the draft report against the raw logs. Its verdict
  was "Report supported with the fixes above", and its fixes are applied ([audit/](audit/)). It checked the
  report, not the proof, and it is not independent of OpenAI.
- An Anthropic model (Claude Fable) read the report with raw excerpts and found no contradictions. Its
  corrections are applied.

## Who ran this

The check was carried out by Claude Code, Anthropic's coding agent, on the repository owner's machine at the
owner's request, 2026-10-06 to 2026-10-07 (UTC).
