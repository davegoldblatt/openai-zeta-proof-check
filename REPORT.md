# Report: independent check of OpenAI's Lean proof that ζ(s) ≠ 0 for Re(s) > 7/8

Checked 2026-10-06 to 2026-10-07 (UTC). All file references are to this repository. This report was
reviewed against the raw logs by an OpenAI model (see `audit/`) and read by an Anthropic model. Their
corrections are applied.

## Verdict

The proof checks.

Run A, OpenAI's challenge and config (`evidence/comparator.run2.log`, `evidence/comparator.run2.time`,
`evidence/phase2.timeline`):

- comparator printed `Running Lean default kernel on solution.`, `Lean default kernel accepts the solution` and
  `Your solution is okay!`, and exited 0.

Run B, a challenge and config written by the checker, with the independent nanoda kernel enabled
(`evidence/comparator.run3-nanoda.log`, `.time`, `evidence/phase4.timeline`):

- comparator printed `nanoda kernel accepts the solution`, `Lean default kernel accepts the solution` and
  `Your solution is okay!`, and exited 0.
- comparator's statement comparison against the checker's own challenge, and its axiom check, both passed. They
  run before either kernel.

Axioms and statement (`evidence/AxiomCheck.lean`, `evidence/axioms.log`, `evidence/phase3.timeline`):

- `#print axioms OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re` printed exactly
  `'OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re' depends on axioms: [propext, Classical.choice, Quot.sound]`.
  No `sorryAx`, no `Lean.ofReduceBool`.
- In a scratch file importing only `OAI.NumberTheory.DirichletL.Nonvanishing`, this elaborated with no Lean errors
  or warnings: `example {s : ℂ} (hs : (7 / 8 : ℝ) < s.re) : _root_.riemannZeta s ≠ 0 :=
  OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re hs`. Lake also printed its 23 notices about patched libraries.
- comparator's axiom check runs on the exported kernel terms against the config's permitted list, so it is the
  strong check. `#print axioms` runs inside the solution's own environment, so it is the weaker confirmation.

## What the statement says

- `∀ {s : ℂ}, (7 / 8 : ℝ) < s.re → riemannZeta s ≠ 0`, with Mathlib's root-level `riemannZeta`. The challenge
  imports only Mathlib and opens nothing.
- There is no `s ≠ 1` hypothesis. Mathlib gives `riemannZeta` a conventional value at the pole s = 1, so the
  theorem also covers that point. Mathlib v4.34.1 already proves that value is nonzero (`riemannZeta_one_ne_zero`,
  `Mathlib/NumberTheory/Harmonic/ZetaAsymp.lean`) and already proves `riemannZeta s ≠ 0` for `1 ≤ s.re`
  (`riemannZeta_ne_zero_of_one_le_re`, `Mathlib/NumberTheory/LSeries/Nonvanishing.lean`). The new content is the
  strip 7/8 < Re(s) < 1.

## What was checked

- openai/math at `adc7f1241b42e322a6451854ab7e4b4c146bf78a`, directory `lean/`, toolchain
  `leanprover/lean4:v4.34.1` (Lean commit `5045d0056413266e57c625dcd7c365b10e377c52`).
- Proof closure: 2,924 OAI modules (486,490 source lines, `evidence/build-facts.txt`), plus 19 modules from two
  outside libraries (4 PrimeNumberTheoremAnd, 15 rellich-kondrachov), on top of prebuilt Mathlib.
- Mathlib `d13f23b723b8a846827a245b89c10fc7d3f11612` is the official Mathlib tag `v4.34.1` and was git-clean. Its 8
  dependencies are clean, match the project manifest, and match Mathlib's own manifest at that tag
  (`evidence/mathlib-pristine.txt`, `evidence/mathlib-deps-vs-mathlib-own-manifest.txt`,
  `evidence/reference/mathlib-v4.34.1-lake-manifest.json`).
- Mathlib's own modules all came from its prebuilt cache (8,908 files downloaded during `lake update`, then
  `No files to download`). Only Mathlib's cache tool (36 modules plus its executable) and 2 Batteries modules it
  uses were compiled locally (`evidence/lake-update.log`).
- All 42 dependency checkouts were at their manifest commits (`evidence/packages-state.txt`). `lake update` left
  `lake-manifest.json` unchanged (`evidence/phase1.timeline`).

## Tools

- comparator `d03acab154d269c06e60e4de7e4cc85deebff94b` and lean4export `076e8e57707e813375e8f9da8bf989799ace9680`:
  their `v4.34.0` tags. No `v4.34.1` tags exist. Later commits bump the toolchain to v4.35 release candidates
  (comparator: `lean-toolchain` and `lake-manifest.json` only; lean4export: `lean-toolchain` and `Test.lean`).
  Both were rebuilt with Lean 4.34.1 (`evidence/tool-versions.txt`, `reproduce/docker/Dockerfile`).
- landrun: `main` at `811cfff51ceaf3d9843708aa6d22e9b84ccac8b4` (v0.1.18), Go 1.27.1.
- nanoda: github.com/ammkrn/nanoda_lib `master` at `3a2407216ee84a75f9e1aead6803d0578be06ae7` (v0.4.19), Rust
  1.99.0 (`reproduce/docker/Dockerfile.nanoda`). It accepts export format 3.1.0, which lean4export produced.
- Environment: Docker Desktop on Apple Silicon, Linux 6.12.76 (aarch64), Ubuntu 24.04 image, unprivileged user,
  no network for the comparator runs (`evidence/runtime-config.txt`).

## Timings (UTC)

- Setup, clone through trusted build: 23:13:17 to 23:21:04 = 7 min 47 s (clone 1:27, `lake update` 4:38, cache
  get 0:15, trusted challenge build 1:27).
- Run A, part 1 (2 parallel jobs, 5 GiB cap): 23:27:20 to 23:34:02 = 6 min 42 s, stopped on purpose to give Docker
  more memory. Interrupted, so no exit status. It had compiled 155 modules: 136 OAI and the 19 outside ones.
- Between parts (Docker Desktop restart): 74 s.
- Run A, part 2 (4 parallel jobs, 16 GiB cap): 23:35:16 to 00:43:01 = 1:07:45 (time file: 1:07:44). A fresh
  comparator invocation that reused the compiled modules and compiled the other 2,788 OAI modules.
- Proof compile time, from compiled-file timestamps (`evidence/build-facts.txt`): about 23:29:15 to the 23:34:02
  stop, then about 23:36:13 to the last module at 00:34:38. About 63 minutes in total.
- After the build (proof export, parsing, statement comparison, axiom check, kernel replay): 00:34:38 to
  00:43:01 = 8 min 23 s.
- Axiom check: 9 s.
- Run B: 01:15:33 to 01:29:50 = 14 min 17 s. No proof module recompiled.

## Resources

- Run A, part 2: container cap 16 GiB plus 4 GiB swap. Observed peak 14.59 GiB including page cache, no swap, zero
  memory-limit events and zero OOM kills, through the last 30-second sample, 14 s before exit. Largest single
  process 6,909,468 KiB = 6.59 GiB.
- Run A, part 1: pinned at its 5 GiB cap (27,627 memory-limit events, swap peak 2.57 MiB, no OOM kills).
- Run B: cap 16 GiB, observed peak 12.00 GiB, no swap, no OOM events.

## Errors and warnings

- Errors: none in any log.
- Warnings, all expected: the challenges' `declaration uses 'sorry'` (their placeholder proofs); Lake's
  `repository ... has local changes` for the 23 libraries the project patches; and in `lake update`,
  `toolchain not updated; multiple toolchain candidates` (the fixed v4.34.1 was kept; TauCeti asked for
  v4.35.0-rc3 and fixed-point-theorems for v4.32.0).
- OAI proof modules with warnings: 0 of 2,924.

## Trust assumptions

One assumption governs everything below: that OpenAI's repository is not trying to attack the checker. This
check makes that assumption. Against a non-hostile repository none of the items below can change the verdict,
because comparator's kernel replay re-checks every declaration the proof uses and trusts nothing the build
produced. Against a hostile repository, items 1 to 4 would matter.

1. comparator assumes the challenge's imports and the lakefile are controlled by the checker or trustworthy. Here
   the challenge file and config used in Run A came from OpenAI's repository. They were read by hand: 8 lines,
   `import Mathlib` only, the intended statement. Run B used a challenge and config written by the checker
   (`reproduce/verifier/`). The lakefile and the 23 patches it applies were written by OpenAI. Read by hand: it
   pins every dependency to a commit and patches third-party libraries through a `run_cmd` (runs whenever the
   configuration is elaborated) and a `post_update` hook. No patch touches Mathlib or its dependencies. Setup
   commands and comparator's outer `lake env` load all package configurations outside the sandbox. comparator's
   own challenge and solution builds run inside landrun.
2. comparator assumes the solution was not compiled beforehand. Run A was paused after 155 modules had compiled
   inside comparator's sandbox, and its second part reused them. Under the non-hostile assumption this is a resume.
3. comparator's README recommends wrapping the run in `systemd-run --property=RestrictAddressFamilies=~AF_UNIX`.
   A container has no systemd. Instead the container's seccomp profile blocks creating AF_UNIX sockets with
   `socket(2)` (`socketpair(2)` stays allowed, as with systemd's rule), and the comparator containers had no
   network (`reproduce/docker/seccomp-change.txt`).
4. The kernel is Linux 6.12.76, older than the 7.1 kernel that fixes the gap the README's wrapper covers.
   comparator runs landrun in best-effort mode. landrun's exact Landlock level was not measured.
5. comparator's sandbox program was supplied through a one-line wrapper that adds `LEAN_NUM_THREADS` (2, then 4) to
   cap parallel compile jobs for memory (`reproduce/scripts/landrun-threads.sh`). It adds no permissions.
6. OpenAI's configs leave the second kernel off. Of the 405 comparator configs in the repository, 402 set
   `enable_nanoda` to false, 2 leave it unset (off by default) and 1 turns it on. Run B turned it on.

Not deviations: running as an unprivileged user satisfies comparator's assumption 6. Passing landrun and
lean4export by exact path (`COMPARATOR_LANDRUN`, `COMPARATOR_LEAN4EXPORT`) is a documented option. Note on the
PATH-based setup: `lake env` puts about 40 package build folders, which the sandboxed build can write to, ahead
of the system folders on PATH (`evidence/phase1c.log`), and comparator looks up landrun by name. Exact paths
avoid that.

## Limits

- One operator ran both runs, on one machine. A rerun by an independent party from a fresh clone has not been done.
- The review of this report against the logs was done by an OpenAI model. It did not check the proof, and it is
  not independent of the party whose proof this is. The second read was by an Anthropic model, the same vendor as
  the agent that ran the check.
- This checks the Lean proof only. It says nothing about the accompanying paper.
