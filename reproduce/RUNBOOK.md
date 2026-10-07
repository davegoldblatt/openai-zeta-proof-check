# How to reproduce

These are the commands used for this check, in order. Run them from the repository root.

Requirements: Docker on a Linux kernel with Landlock enabled (Docker Desktop's LinuxKit kernel 6.12 works),
at least 20 GB of memory available to Docker, about 25 GB of disk, and network access for the setup step.
The original run was on Apple Silicon (aarch64). The Dockerfile pins the arm64 Go tarball, so change
`GO_TARBALL` and `GO_SHA256` for x86_64.

```sh
# Images: Lean v4.34.1, landrun, lean4export and comparator (root-owned), then nanoda on top.
docker build -t qrh-verify:1 reproduce/docker
docker build -t qrh-verify:2 -f reproduce/docker/Dockerfile.nanoda reproduce/docker

# Work volume and an output folder for logs.
docker volume create qrh-work
mkdir -p evidence-out
COMMON="--security-opt seccomp=$PWD/reproduce/docker/seccomp-no-af-unix.json \
  -v qrh-work:/home/verifier/work \
  -v $PWD/evidence-out:/home/verifier/work/evidence \
  -v $PWD/reproduce/scripts:/opt/qrh-scripts:ro"

# 1. Clone openai/math at the checked commit, lake update, Mathlib cache, trusted challenge build.
#    Nothing from the proof is compiled here.
docker run --rm --memory 5g --memory-swap 6g $COMMON qrh-verify:1 bash /opt/qrh-scripts/phase1_trusted.sh

# 2. Integrity checks: package commits, Mathlib clean, lakefile hooks, module shadowing.
docker run --rm --network none --memory 5g $COMMON qrh-verify:1 bash /opt/qrh-scripts/phase1b_integrity.sh

# 3. Run A: the official comparator check with OpenAI's challenge and config.
docker run --rm --network none --memory 16g --memory-swap 20g -e RUN=run2 -e QRH_LEAN_THREADS=4 \
  $COMMON qrh-verify:1 bash /opt/qrh-scripts/phase2_comparator.sh

# 4. Axiom list and the _root_.riemannZeta statement check.
docker run --rm --network none --memory 16g --memory-swap 20g $COMMON qrh-verify:1 bash /opt/qrh-scripts/phase3_axioms.sh

# 5. Run B: the checker's own challenge and config, with the nanoda kernel enabled.
docker run --rm --network none --memory 16g --memory-swap 20g $COMMON \
  -v $PWD/reproduce/verifier:/opt/qrh-verifier:ro qrh-verify:2 bash /opt/qrh-scripts/phase4_nanoda.sh
```

Pass requires, in each comparator log, `Your solution is okay!` with exit status 0 in the matching `.time` file,
and in `axioms.log` exactly `[propext, Classical.choice, Quot.sound]`.

Notes on the original run:

- Run A ran in two parts. Part 1 (`RUN=run1`, `QRH_LEAN_THREADS=2`, `--memory 5g --memory-swap 6g`) was stopped
  after 155 modules to give Docker more memory. Part 2 (`RUN=run2`, shown above) reused them. A fresh reproduction
  needs only part 2.
- `evidence/phase1c.log` came from a one-off command run after step 2: it lists each build folder's contents and
  the PATH that `lake env` sets, before any proof module was compiled.
- `reproduce/scripts/cmp_manifest.py` compares the project manifest with Mathlib's own manifest, and
  `reproduce/scripts/critical_path.py` counts the proof's modules and source lines.
- Run B's memory cap started at 17 GiB and was lowered to 16 GiB in the first minute (`evidence/runtime-config.txt`).
