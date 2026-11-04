# Domain docs

This repo uses a single context:

- `GLOSSARY.md` at the repository root defines domain vocabulary.
- `docs/adr/` contains architecture decisions.

## Read before exploring

Read `GLOSSARY.md` when present and the ADRs relevant to the area being explored.
If either location is absent, continue silently with the available repository context.

Create glossary entries and ADRs through `/domain-modeling` when terminology or decisions are resolved. These documents are created as needed.

## Use the glossary's vocabulary

Use the glossary's terms in issues, proposals, hypotheses and tests. Follow any distinctions it makes between terms.

If a concept is missing, check whether the codebase already has a name for it. Bring a real vocabulary gap to `/domain-modeling`.

## Surface ADR conflicts

If a proposal contradicts an existing ADR, identify the ADR and explain why its decision should be reconsidered.
