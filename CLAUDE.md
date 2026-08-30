# CRMTHREE - Instructions for AI agents

This repository is spec-first. The specification in `specs/` is the product; the code
in `implementations/` proves it.

## Mandatory: specs before code

ALWAYS update the spec BEFORE changing any implementation - features, modifications,
behavior-changing fixes. No exceptions.

1. `specs/specifications.md` for any functional change
2. `specs/ux.md` for any UI/UX change
3. `specs/architecture.md` for any technical change
4. THEN change the implementation to match

## Building CRMTHREE from the spec

Everything you need is in `specs/`: functional stories with acceptance criteria
(`specifications.md`), UX definitions (`ux.md`), architecture (`architecture.md`), and
the machine-readable data model (`data-model.json`). Target any stack; the Firebase
implementation in `implementations/firebase/` is the canonical reference for behavior.
