# Independent check of OpenAI's Lean proof that ζ(s) ≠ 0 for Re(s) > 7/8

## The short version

OpenAI recently published a proof, produced with one of its AI models, of something mathematicians have been
stuck on for over a century. We wanted to know whether it actually holds up, so we checked it ourselves.

Some background: The Riemann zeta function is one of the most important objects in math, mostly because it
quietly encodes how the prime numbers are spread out. The Riemann Hypothesis, one of the most famous unsolved
problems anywhere, says all of the function's interesting zeros sit on a single line, at real part 1/2. Nobody
has proven that. For over 100 years, the best anyone managed was to rule out zeros at real part 1 and in a
sliver just to the left of it, a sliver that keeps getting thinner the higher you go.

OpenAI's claim pushes much further: no zeros anywhere past 7/8. That doesn't prove the Riemann Hypothesis, but
it's a real step toward it. As far as we know, nobody had ruled out a strip like this before OpenAI's work on it.

The proof is written in Lean, a language where a computer checks every single logical step, so you don't have
to take anyone's word for it. It's huge: about 2,900 files and close to half a million lines.

So we ran the check. Lean's own checker accepted the proof. Then, to be extra careful, we wrote the statement
out ourselves, so we knew exactly what was being proven. We also had a second checker, written independently in
a different programming language, go through the whole thing. It accepted the proof too. And the proof leans
only on the standard ground rules that ordinary math uses. No shortcuts, no skipped steps.

Bottom line: unless both checkers are broken in the same way, the proof checks out. Two caveats. We didn't
review OpenAI's written paper, only the computer proof. And it was just us, on one machine. The more people who
reproduce it independently, the better, and everything you need to do that is in this repo.

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

## License

Everything here, the scripts, the logs and the documents, is released under the MIT License ([LICENSE](LICENSE)).
Reuse it freely with attribution.
