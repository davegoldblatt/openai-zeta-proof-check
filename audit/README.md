# Audit of the draft report

- `AUDIT_INSTRUCTIONS.md`: the request given to the auditor (an OpenAI model, gpt-6-astra, via Codex in a
  read-only sandbox).
- `DRAFT_REPORT_as_audited.md`: the draft the auditor read, unchanged.
- `AUDIT_RESULT.md`: the auditor's findings, unchanged except that absolute local paths were shortened.

The auditor read a bundle laid out as `evidence/`, `setup/`, `project/` and `comparator-pinned/`. This
repository's `evidence/` holds everything the auditor saw, plus files added afterwards: four records made in
response to its findings (`runtime-config.txt`, `mathlib-deps-vs-mathlib-own-manifest.txt`, `tool-versions.txt`,
`build-facts.txt`) and the `reference/` folder, the second run's logs (Run B, `*run3-nanoda*`, `phase4.timeline`,
`verifier-inputs.sha256`, `nanoda-image-build.log`), and `image-build.log`. `setup/` is now `reproduce/`. `project/` and
`comparator-pinned/` held copies of third-party files that are not republished here. They are OpenAI's challenge,
config, solution file, lakefile and manifest at commit `adc7f12`, and comparator's source at commit `d03acab`.

All 11 findings were applied in `REPORT.md`. None changed the verdict.
