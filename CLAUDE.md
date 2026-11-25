# KINGDOM: notes for Claude Code

Read automatically at the start of every Claude Code session. Keep it short: the details live in the files below.

## Start of every session
0. If a GitHub remote is set up, `git pull` first: ChatGPT may have added notes to `DESIGN_INBOX.md` on GitHub.
1. `HANDOFF.md`: where we are right now, plus the paths, ports and gotchas.
2. `PRIORITIES.md`: what to do next. It's the only "next" list.
3. `SPEC.md`: the owner's original brief and the "How to work" rules. Never edit it.
4. `DESIGN_INBOX.md`: design and art-direction decisions from the owner's ChatGPT chats. Tell the owner what's new under "Waiting", then follow "How Claude Code handles the inbox" in that file.

Before working on an area, read its doc:
| Area | Doc |
|---|---|
| Game design, combat, classes, stats, loot, death, art direction (section 12.1), palette | `DESIGN.md` |
| Zones 1-3 layout and story (Tithelands, Highcrown, Barrow Fells) | `ZONES_DESIGN.md` + the `ZONE*_MAP` images |
| Zone 1 rebuild and performance plan | `ZONE1_OVERHAUL.md` |
| Zone 1 Greenwood look (trees, limestone, plants, light) | `GREENWOOD_OVERHAUL.md` |
| The Gullet dungeon and Harl the Delver | `GULLET_DESIGN.md` + `GULLET_MAP.svg` |
| White Knights Outpost (north end of zone 1), its asset library | `OUTPOST_PLAN.md` + `assets/outpost/MANIFEST.md` + `docs/outpost/` |
| Martial / Vanguard / Mystic classes, subclasses, factions | `CLASS_PLAN.md` |
| Art and audio shopping list | `ART_NEEDS.md` |
| Checklist by phase, playtest (🧪) items | `TODO.md` |

## How to work (from SPEC.md)
- The owner has no coding experience. Explain in plain language.
- Ask before any design change. If the code and a doc disagree, ask before changing either one.
- One step at a time. After each step, say how to run it and what to test.
- Don't gold-plate: get it working, then make it good.
- Everything stays original: no names, lore or assets from other games.
- The currency is **coins**, never "gold".

## After making changes
- Update `HANDOFF.md` ("Where we are"), tick items in `TODO.md` / `PRIORITIES.md`, and update the area doc if the design changed.
- Commit (local identity "Kingdom Dev"). Commit only your own files: check `git status` first.
- If a GitHub remote is set up, push after committing. ChatGPT reads this project from GitHub (read-only), so unpushed changes are invisible to it.

## Design decisions made in ChatGPT
They arrive in `DESIGN_INBOX.md`: written there by ChatGPT or Codex through GitHub, or pasted in by the owner. If the owner pastes a decision straight into chat, add it to the inbox under "Waiting" first, then handle it like the others.
