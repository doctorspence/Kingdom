# AGENT BOARD: studio tasks

*Rules in `AGENT_STUDIO.md` sections 5-6. One primary owner per task. A task is `done` only after QA `verified` it and integration checked it.*

**Statuses:** `proposed` · `ready` (authorised, criteria clear, can start) · `in_progress` · `blocked` · `review` (with QA) · `changes_requested` · `verified` (QA passed) · `done` · `waiting_owner`

**Priorities:** P0 stabilise · P1 milestone · P2 owner decisions · P3 under-the-hood · P4 content (same as `PRIORITIES.md`; that file stays the master "next" list).

## Files nobody on the board owns (do not touch)
Checked 2026-11-27 at setup. These were already changed in the working tree by another session or the owner before the studio existed. No agent edits, reverts, stages or commits them unless the owner says so:
- Staged: `HANDOFF.md`, `ZONE2_HIGHCROWN_MAP_V2.png`, `ZONE2_HIGHCROWN_MAP_V2.svg`, `ZONES_DESIGN.md`, `game/world/forest_scatter.gd`, `tools/fit_outcast.gd`
- Unstaged: `HANDOFF.md`, `game/classes/ability_caster.gd`, `game/classes/ability_data.gd`, `game/classes/arcane_bolt.gd` (deleted), `game/combat/hit_info.gd`, `game/enemies/enemy.gd`, `game/player/player.gd`
- Untracked: `ZONE2_HIGHCROWN_MAP_V2.png.import`, `ZONE2_HIGHCROWN_MAP_V2.svg.import`, `tests/net_stealth_check.gd.uid`
- Appeared during setup (another session is active, apparently replacing Arcane Bolt with an Arcane Surge Wave): `data/classes/class_lamplighter.tres`, `tests/class_check.gd`, `tests/sound_check.gd`, `game/classes/arcane_surge_wave.gd` (+ `.uid`), `tests/stamina_check.gd.uid`, `tests/visual_stamina.gd.uid`
- `main` is 1 commit ahead of `origin/main` (not pushed).

## Active tasks

| ID | Task | Owner | Status | Priority | Depends on | Files | Done when |
|---|---|---|---|---|---|---|---|
| STU-001 | Set up the AI studio (agents, shared files, rules) | orchestrator | review | P0 | none | `.claude/agents/kingdom-*.md`, `AGENT_*.md`, `CLAUDE.md` (one table row) | Owner has reviewed the setup; nothing committed until then |
| STU-002 | Agent Teams test (replaces the subagent-only simulated handoff at the owner's request): the team plans and builds STU-003 | kingdom-creative-director (lead) | verified (report H-LEAD; shared task list was unavailable, board used instead) | P0 | STU-001 | `AGENT_*.md` | Team ran with real messages and the shared task list; QA verified; lead reported how they coordinated |
| STU-003 | Test feature: training dummy damage readout (sandbox only). Brief: H-000 in `AGENT_HANDOFFS.md` | designer -> architect -> gameplay -> qa | verified (QA H-004: dummy_check 57 ok, combat_check 52 ok); waiting_owner: playtest + commit decision | P0 (owner-assigned test) | STU-002 | `game/combat/training_dummy.gd`, `game/combat/training_dummy.tscn` (only if needed), new `tests/dummy_check.gd` | H-000's done-when list passes, checked by QA itself |
| STU-003.T1 | Design spec (H-001, H-001a) | designer | done | P0 | none | `AGENT_HANDOFFS.md` | Spec with numbers and 16 acceptance criteria |
| STU-003.T2 | Technical review and build plan (H-002) | architect | done | P0 | T1 | `AGENT_HANDOFFS.md` | Build plan, test API, co-op decision |
| STU-003.T3 | Build the readout | gameplay | verified | P0 | T2 | `game/combat/training_dummy.gd` only | H-003 written, qa told |
| STU-003.T4 | Write `tests/dummy_check.gd`; run it and `combat_check` | qa | verified (H-004) | P0 | T3 for the real run | `tests/dummy_check.gd` | Both checks pass or failure cause written in H-004 |

## Waiting on the owner (from `PRIORITIES.md` P1; not studio work yet)
| ID | Task | Owner | Status | Note |
|---|---|---|---|---|
| OWN-001 | Solo playtest round (Gullet run, death and recover, nine abilities, camp raid, sound, settings, inventory) | owner | waiting_owner | `PRIORITIES.md` P1. The studio's next real work is fixing what it finds. |
| OWN-003 | Playtest the dummy readout in `levels/sandbox/combat_test.tscn`; decide whether to commit STU-003 (`training_dummy.gd`, `tests/dummy_check.gd`) | owner | waiting_owner | Frozen grey may be too close to the live colour. Optional follow-ups: `README.md` check list, IBM Plex Mono font missing. |
| OWN-002 | Decide what happens to the uncommitted combat/ability changes listed above | owner | waiting_owner | They look like an in-progress Mana/ability change from another session. |

## Done
*(none yet)*
