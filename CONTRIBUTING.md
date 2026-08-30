# Contributing to CRMTHREE

Thanks for caring about this. Two rules cover almost everything:

## 1. Issues: everywhere

Found a bug in the reference implementation? A gap or contradiction in the spec?
A feature idea? Open an issue. There are no templates to fight and no wrong door.

## 2. Pull requests: on the specifications

**PRs are welcome on `specs/`.** The specification is the product - that is where
collaboration happens. Improve an acceptance criterion, close a gap, sharpen the UX
definition, extend the data model.

**PRs on `implementations/` are not accepted.** The reference implementations follow
the specs - when a spec change is merged, the implementations are updated to match.
This keeps every implementation a faithful proof of the specification rather than a
codebase that drifts away from it. If the implementation disagrees with the spec,
that is a bug: open an issue.

Want CRMTHREE on another stack? Build it from the spec - that is the whole point.
Open an issue and we will link your implementation from the README.

## Practicalities

- MIT license: by contributing you agree your contribution is MIT-licensed like
  everything else. No CLA, no paperwork.
- Keep spec PRs focused: one concern per PR.
- Spec language: English, concrete, testable. Acceptance criteria over prose.
