# DESIGN INBOX: ChatGPT → Claude Code

Design and art-direction decisions made in ChatGPT land here. Claude Code reads this file at the start of every session.

## How ChatGPT (or the owner) adds an entry
Add it at the top of **Waiting**, using this format:

```
### YYYY-MM-DD: short title
- **Area:** art direction / zone 1 / zone 2 / zone 3 / Gullet / classes / factions / UI / combat / loot / other
- **Decision:** what was decided, in plain words
- **Details:** colors (hex), materials, shapes, references, numbers
- **Status:** decided / idea, not decided yet
- **Replaces:** the older decision or doc section this overrides, if any
```

Keep each entry short and concrete. "Idea" entries are for planning only: Claude Code must not build them.

## How Claude Code handles the inbox
1. Read everything under **Waiting**, and tell the owner what's new.
2. For each **decided** entry: write it into the right doc (art direction and palette: `DESIGN.md` 12.1; zones: `ZONES_DESIGN.md`; Zone 1 look: `GREENWOOD_OVERHAUL.md`; the Gullet: `GULLET_DESIGN.md`; classes and factions: `CLASS_PLAN.md`; art needs: `ART_NEEDS.md`). Add any new work to `PRIORITIES.md` or `TODO.md`.
3. If an entry clashes with `SPEC.md`, an existing doc or what's built, ask the owner before filing it.
4. Move the entry to **Filed**, saying where it went. Commit and push.

---

## Waiting
_(nothing yet)_

## Filed
_(nothing yet)_
