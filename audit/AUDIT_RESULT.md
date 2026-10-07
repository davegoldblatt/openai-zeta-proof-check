1. **Several runtime settings are asserted without supporting records.**  
   The draft says “the comparator container had no network,” “Docker Desktop’s Linux kernel is 6.12,” and “Run 2 container limit 16 GiB RAM (+4 GiB swap)” (lines 54, 87–88).

   [setup/seccomp-change.txt:1](setup/seccomp-change.txt:1) describes “Docker’s upstream default profile … with these rule changes,” but the bundle contains no container launch command or inspection showing that profile or network configuration was applied. The memory recorder reads `"memory.current"`, `"memory.peak"` and swap usage, rather than configured limits ([setup/phase2_comparator.sh:14](setup/phase2_comparator.sh:14)). There is no kernel-version output.

   **Fix:** Distinguish the documented seccomp modification from verified runtime configuration. Remove or mark the network, kernel-version, and RAM/swap-limit assertions as unverified by this bundle. The run-1 evidence establishes a 5 GiB peak and memory-limit events, rather than directly recording its configured limit.

2. **The Mathlib dependency verification is overstated.**  
   The draft says its eight dependencies are “clean at the commits Mathlib’s own manifest pins” (line 29).

   The checking script actually loads the project manifest: `python3 -I - lake-manifest.json "$PKG"` and compares `head == p["rev"]` ([setup/phase1b_integrity.sh:11](setup/phase1b_integrity.sh:11), lines 11–24). [evidence/mathlib-pristine.txt:1](evidence/mathlib-pristine.txt:1) records `tag=v4.34.1 status=[clean]`, followed by clean dependency checkouts, but contains no comparison against Mathlib’s own manifest. That manifest is absent.

   **Fix:** Say the eight listed dependencies were clean and matched the **project’s** manifest. The recorded Mathlib commit, tag, and clean status are supported.

3. **The description of configuration execution outside the sandbox is too broad.**  
   The draft says dependency configurations run “outside the sandbox, on every lake command” (lines 78–79).

   Comparator’s `safeLakeBuild` explicitly calls `runSandBoxed` with `cmd := "lake"` and `args := #["build", target.toString]` ([comparator-pinned/Main.lean:124](comparator-pinned/Main.lean:124)). Conversely, the outer invocation is `lake env /usr/local/bin/comparator ...` ([setup/phase2_comparator.sh:21](setup/phase2_comparator.sh:21)).

   **Fix:** State that setup commands and the outer `lake env` load configuration outside Landrun; Comparator’s internal challenge and solution builds run inside Landrun. Also distinguish loading configuration from executing every hook: the project separately defines `run_cmd` and `post_update` ([project/lakefile.lean:263](project/lakefile.lean:263)).

4. **Run 1’s completed-module count and thread setting are wrong.**  
   The draft twice says run 1 compiled “147 proof files” (lines 42 and 81), and describes the wrapper as adding `LEAN_NUM_THREADS=4` (line 92).

   Counting the consecutive `✔ … Built` entries in [evidence/comparator.run1.log:76](evidence/comparator.run1.log:76), lines 76–230, gives **155 modules: 136 OAI, four PrimeNumberTheoremAnd, and 15 RellichKondrachov**. The first entry is `"Built RellichKondrachov.Analysis.FunctionalSpaces.Sobolev.Euclidean.H1 (10s)"`. Run 2 records 2,788 additional OAI modules, with no overlap. Thus the final totals of 2,924 OAI plus 19 outside modules are correct.

   [evidence/phase2.timeline:1](evidence/phase2.timeline:1) says `"run=run1 comparator start threads=2"`; line 3 says `"run=run2 comparator start threads=4"`.

   **Fix:** Correct both occurrences of 147 and report two threads followed by four. Describe run 1 as interrupted/incomplete; its `.time` file is empty and no exit status was recorded. Run 2 was a fresh Comparator invocation reusing completed build artifacts.

   **The final PASS remains supported:** [comparator.run2.log:2868](evidence/comparator.run2.log:2868) prints `"Your solution is okay!"`, [comparator.run2.time:23](evidence/comparator.run2.time:23) records `"Exit status: 0"`, and [axioms.log:24](evidence/axioms.log:24) prints exactly `[propext, Classical.choice, Quot.sound]`. The explicit example in [AxiomCheck.lean:3](evidence/AxiomCheck.lean:3) checks `(7 / 8 : ℝ) < s.re` against `_root_.riemannZeta s ≠ 0`, with `"axiom check exit=0"` in [phase3.timeline:2](evidence/phase3.timeline:2).

5. **The compilation/export timing split cannot be reconstructed, and its arithmetic is inconsistent.**  
   The draft claims “first compiled output 23:29:34,” final compilation at “00:34:38,” “about 62 minutes” excluding the pause, and “proof export plus kernel replay … 8 min 23 s” (lines 45–48).

   Neither compilation timestamp appears in the supporting files. The final build entry merely says `"Built OAI.NumberTheory.DirichletL.Nonvanishing (2.1s)"`, without a wall-clock timestamp ([evidence/comparator.run2.log:2863](evidence/comparator.run2.log:2863)). The timeline records the pause at `23:34:02` and next invocation at `23:35:16`.

   Even accepting the draft’s unsupported boundaries, the span is **65 min 4 s**, minus a **74 s** gap = **63 min 50 s**, rather than 62 minutes. Its stated boundaries give 4 min 28 s before the pause and 59 min 22 s after it; they do not establish 4 min 45 s and 57 minutes. A first completed module also does not identify compilation’s start.

   Recomputed recorded durations are:

   | Interval | Timeline difference | `/usr/bin/time` |
   |---|---:|---:|
   | Clone | 1:27 | — |
   | `lake update` | 4:38 | 4:37.93 |
   | Explicit cache get | 0:16 | 0:15.47 |
   | Trusted build | 1:26 | 1:26.55 |
   | Clone through trusted build | 7:47 | — |
   | Run 1 through pause | 6:42 | Empty file |
   | Between comparator runs | 1:14 | — |
   | Run 2 | 1:07:45 | 1:07:44 |
   | Axiom check | 0:09 | 0:08.80 |
   | Clone through axiom result | 1:30:05 | — |

   Sources: [phase1.timeline:1](evidence/phase1.timeline:1), [phase2.timeline:1](evidence/phase2.timeline:1), [phase3.timeline:1](evidence/phase3.timeline:1), and line 5 of the corresponding `.time` files, which report `"Elapsed (wall clock) time"`.

   **Fix:** Remove the unsupported compilation/export split. Keep the recorded totals; the draft’s 15-second cache and 87-second trusted-build figures are valid rounded command timings. Label 74 seconds as the interval between runs, rather than a separately measured Docker restart. Post-build processing also includes parsing, statement comparison, and axiom checking before kernel replay ([Main.lean:288](comparator-pinned/Main.lean:288)).

6. **The axiom-check invocation was not warning-free.**  
   The draft says it “compiled with no error or warning” (lines 13–14).

   [evidence/axioms.log:1](evidence/axioms.log:1) begins `"warning: PrimeNumberTheoremAnd: repository ... has local changes"`; lines 1–23 contain the 23 repository warnings.

   **Fix:** Say the scratch file produced no Lean diagnostics, while Lake emitted the expected repository warnings. The broader log search supports the reported warning categories and finds no error diagnostics or warnings from OAI proof modules. The challenge’s `sorry` warnings do not indicate a forbidden axiom in the checked solution theorem.

7. **The resource summary has a conversion error and omits measurement limits.**  
   The draft reports “Largest single process 6.9 GB” and an unconditional run-2 peak/no-swap/no-events result (lines 54–56).

   [evidence/comparator.run2.time:10](evidence/comparator.run2.time:10) prints `"Maximum resident set size (kbytes): 6909468"`. Linux reports this in KiB: **7.075 GB, or 6.589 GiB**, rather than 6.9 GB.

   The last cgroup sample, [evidence/cgroup-mem.run2.log:136](evidence/cgroup-mem.run2.log:136), is timestamped `00:42:47` and records `"peak=15662587904 swap=0 swap_peak=0 max 0 oom 0 oom_kill 0"`. Comparator exits 14 seconds later. The observed peak does correctly convert to **14.59 GiB**, but no final cgroup sample covers those last seconds.

   Run 1 also records `"swap_peak=2695168"` ([evidence/cgroup-mem.run1.final.txt:1](evidence/cgroup-mem.run1.final.txt:1)), an omitted **2.57 MiB** swap peak.

   **Fix:** Correct RSS units, describe the cgroup figures as observed through the last sample, and include run 1’s small swap usage.

8. **The tool-version history claims exceed the evidence.**  
   The draft says both tools are at their `v4.34.0` tags, “there are no v4.34.1 tags,” and “later commits only bump to v4.35 release candidates” (lines 93–95).

   [setup/Dockerfile:60](setup/Dockerfile:60) checks Comparator’s tag using `"git rev-parse 'v4.34.0^{commit}'"`. For lean4export, line 64 only checks `"git ... rev-parse HEAD"` against its pinned hash. [comparator-pinned/lake-manifest.json:8](comparator-pinned/lake-manifest.json:8) records that hash with `"inputRev": "master"` at line 11. No tag inventory or commit history substantiates the remaining claims; Dockerfile comments repeat the rationale without verifying it.

   **Fix:** Retain the pinned revisions and the build recipe’s Lean 4.34.1 override. Remove or qualify the unsupported tag/history assertions.

9. **Documented options are presented as stricter trust-assumption deviations.**  
   Under “Stricter than the instructions,” the draft highlights running as a non-root user and using exact executable paths (lines 96–100).

   [comparator-pinned/README.md:39](comparator-pinned/README.md:39) already requires `"You are not running this under a privileged user"`. Lines 12–13 explicitly allow `"full paths to these binaries"` through `COMPARATOR_LANDRUN` and `COMPARATOR_LEAN4EXPORT`.

   **Fix:** Classify non-root execution as satisfying the stated assumption and exact paths as a documented option. Additional container confinement can remain described as an extra measure.

10. **The source-line count is unsupported.**  
    The draft describes the 2,924 OAI files as “about 486,000 lines” (line 27).

    [evidence/built-modules.txt:2925](evidence/built-modules.txt:2925) transitions from the OAI module list to `"PrimeNumberTheoremAnd.Fourier"`. This inventory and the build logs substantiate module counts, but contain no source-line totals. The bundle lacks the complete sources or a recorded line-count command/result.

    **Fix:** Remove the 486,000-line estimate or identify it as unverified. Describe the supported counts as the compiled module closure.

11. **“Mathlib was not compiled” needs a narrower qualification.**  
    The draft makes this categorical statement at line 30.

    During Mathlib’s post-update hook, the log records `"Built Cache.Cli (517ms)"`, numerous other cache-tool builds, and `"Built Batteries.Tactic.OpenPrivate (827ms)"` ([evidence/lake-update.log:116](evidence/lake-update.log:116), lines 116–155).

    **Fix:** Say **Mathlib’s mathematical modules came from cache**, while cache tooling and a Batteries helper were compiled locally. The 8,908 downloads and subsequent `"No files to download"` are supported.

Report supported with the fixes above