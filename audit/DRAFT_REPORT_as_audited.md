# Draft report: OpenAI's Lean proof that zeta(s) != 0 for Re(s) > 7/8

## Verdict

PASS.

- comparator (Lean FRO, pinned commit d03acab = tag v4.34.0) printed "Lean default kernel accepts the
  solution" and "Your solution is okay!", and exited 0 (evidence/comparator.run2.log, last lines;
  evidence/comparator.run2.time "Exit status: 0"; evidence/phase2.timeline "run=run2 comparator exit=0").
- `#print axioms OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re` printed exactly:
  `'OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re' depends on axioms: [propext, Classical.choice, Quot.sound]`
  (evidence/axioms.log). No sorryAx, no Lean.ofReduceBool.
- In a scratch file importing only OAI.NumberTheory.DirichletL.Nonvanishing, this compiled with no
  error or warning (evidence/AxiomCheck.lean, evidence/axioms.log, evidence/phase3.timeline exit=0):
  `example {s : ℂ} (hs : (7 / 8 : ℝ) < s.re) : _root_.riemannZeta s ≠ 0 :=
   OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re hs`
- comparator itself also checks that the statement's constants match the trusted challenge
  (`import Mathlib`, project/ComparatorChallenges_QuasiRiemannHypothesis.lean) and that only
  permitted_axioms [propext, Quot.sound, Classical.choice] are used (project/..._QuasiRiemannHypothesis.json).
- Only Lean's built-in kernel checked the proof. The config sets enable_nanoda false, so the optional
  second kernel did not run.

## What was checked

- openai/math at adc7f1241b42e322a6451854ab7e4b4c146bf78a, lean/ directory, toolchain leanprover/lean4:v4.34.1
  (Lean commit 5045d0056413266e57c625dcd7c365b10e377c52).
- Proof: 2,924 OpenAI files (about 486,000 lines) in OAI/NumberTheory, plus 19 files from two outside
  libraries (4 from PrimeNumberTheoremAnd, 15 from rellich-kondrachov), on top of prebuilt Mathlib.
- Mathlib pin d13f23b = official Mathlib tag v4.34.1, git-clean, its 8 dependencies clean at the commits
  Mathlib's own manifest pins (evidence/mathlib-pristine.txt). Mathlib was not compiled: 8,908 prebuilt
  files were downloaded from Mathlib's cache during `lake update`, and the explicit `lake exe cache get`
  had nothing left to download (evidence/lake-update.log, evidence/cache-get.log).
- All 42 dependency checkouts are at their manifest commits (evidence/packages-state.txt).
  `lake update` left lake-manifest.json unchanged (evidence/phase1.timeline).

## Timings (UTC, 2026-10-06 to 07)

- Setup, from clone to trusted build done: 23:13:17 to 23:21:04 = 7 min 47 s. Clone 1 min 27 s,
  `lake update` 4 min 38 s, `lake exe cache get` 15 s, trusted build of the challenge 1 min 27 s
  (evidence/phase1.timeline and *.time files).
- comparator run 1: 23:27:20 to 23:34:02 (6 min 42 s), stopped on purpose to raise Docker's memory.
  It had compiled 147 proof files by then.
- Docker Desktop restart with more memory: 23:34:02 to 23:35:16.
- comparator run 2: 23:35:16 to 00:43:01 = 1 h 7 min 45 s (comparator.run2.time says 1:07:44).
- Proof compile overall: first compiled output 23:29:34, last (Nonvanishing.olean) 00:34:38. That span
  includes the pause. Compiling time excluding the pause is about 62 minutes (about 4 min 45 s in run 1,
  about 57 min in run 2).
- After the build: proof export plus kernel replay, 00:34:38 to 00:43:01 = 8 min 23 s.
- Axiom check: 9 s (00:43:13 to 00:43:22).
- End to end, setup start to axiom result: 23:13:17 to 00:43:22 = 1 h 30 min 5 s.

## Resources

- Run 2 container limit 16 GiB RAM (+4 GiB swap). Container peak 14.59 GiB including page cache, no
  swap used, zero memory-limit events and zero OOM kills (evidence/cgroup-mem.run2.log). Largest single
  process 6.9 GB (comparator.run2.time "Maximum resident set size (kbytes): 6909468").
- Run 1 ran under a 5 GiB limit and was pinned at it (memory.peak = 5 GiB, 27,627 memory-limit events,
  no OOM kills) (evidence/cgroup-mem.run1.final.txt).

## Errors and warnings

- Errors: none in any log.
- Warnings, all expected:
  - `declaration uses 'sorry'` in ComparatorChallenges/QuasiRiemannHypothesis.lean (the challenge's
    placeholder proof). It appears in the trusted build and in each comparator run's challenge step.
  - "repository ... has local changes" for the 23 dependency packages that the project's lakefile
    patches for Lean 4.34.1 compatibility.
  - `lake update`: "toolchain not updated; multiple toolchain candidates" (the project's fixed v4.34.1
    was kept; TauCeti asked for v4.35.0-rc3 and fixed-point-theorems for v4.32.0).
- Proof files with warnings: 0 of 2,924 (no "⚠ ... Built" lines in either run).

## Deviations from comparator's stated trust assumptions (comparator-pinned/README.md)

1. Assumption 1 (Challenge's import closure and the lakefile are controlled by you or trustworthy):
   the lakefile, and the 23 dependency patches it applies, were written by OpenAI, the party being
   checked. I read the lakefile. It pins all dependencies to commits and patches third-party libraries
   at config time and after update. No patch touches Mathlib or its dependencies. Mathlib was checked
   against upstream (see above). Dependencies' own lakefile.lean configs also run, outside the
   sandbox, on every lake command, including the trusted build.
2. Assumption 2 (you have not previously compiled the Solution): the check ran in two parts. Run 1
   compiled 147 proof files inside comparator's sandbox, then was stopped. Run 2 reused those files and
   compiled the rest. Under the README's adversarial model that is a prior compilation of the solution.
   The user said they are not concerned about deliberate attacks, so run 2 was treated as a resume.
3. The README's systemd-run wrapper (RestrictAddressFamilies=~AF_UNIX) was not used, since a container
   has no systemd. Instead, the container's seccomp profile blocks creating new AF_UNIX sockets with
   socket(2) (socketpair(2) stays allowed, as with the systemd rule), and the comparator container had
   no network.
4. Docker Desktop's Linux kernel is 6.12, older than the 7.1 kernel that fixes the landrun gap the
   README's wrapper covers. comparator calls landrun in best-effort mode, so landrun used what this
   kernel supports. Its exact Landlock level was not separately measured.
5. comparator's sandbox program was given through a one-line wrapper that adds one environment variable,
   LEAN_NUM_THREADS=4, to limit parallel compile jobs for memory. It adds no permissions.
6. Tool versions: comparator d03acab and lean4export 076e8e5 are their v4.34.0 tags (there are no
   v4.34.1 tags, and later commits only bump to v4.35 release candidates). Both were rebuilt with Lean
   4.34.1. landrun is main at 811cfff.
7. Stricter than the instructions: setup and the trusted build also ran inside the container, as a
   non-root user. landrun and lean4export were given to comparator by exact path rather than found on
   PATH. Note on the README's PATH-based setup: `lake env` puts about 40 package build folders, which
   the sandboxed build can write to, ahead of the system folders on PATH, and comparator finds landrun by
   name. Exact paths avoid that.
