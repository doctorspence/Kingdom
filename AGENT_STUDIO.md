# KINGDOM AI studio: how the agent team works

*Set up 2026-11-27. Every studio agent reads this file before doing anything. It adds to `CLAUDE.md` and `SPEC.md`; it never overrides them. If this file and `SPEC.md`, `CLAUDE.md` or the owner disagree, the owner and `SPEC.md` win.*

## 1. What the studio really is (no pretending)
- The ten agents are **Claude Code subagents**, defined in `.claude/agents/kingdom-*.md`. Each one runs in its own fresh context, does one job, and returns one report.
- **Agents do not talk to each other directly and do not run on their own.** A subagent cannot start another subagent. The **orchestrator** (the normal Claude Code session the owner is talking to) starts each agent, passes the handoff to the next one, and keeps the board up to date.
- The **communication layer is the shared files** below plus the handoff block every agent returns. An agent knows only what is in the files and in the brief the orchestrator gives it. Never assume another agent "knows" something.
- Several agents can run **at the same time** only when the orchestrator starts them together, and only on tasks with separate files (section 6).
- The orchestrator can continue a finished agent with its context intact (SendMessage to its id) instead of starting a new one, for example to ask QA to retest after a fix.

### 1b. Agent Teams mode (turned on 2026-11-27)
`.claude/settings.json` sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (an experimental Claude Code feature). In this mode:
- The **Creative Director is the team lead**. Start it in an interactive terminal in this folder: `claude --agent kingdom-creative-director`. Teams do **not** work in `claude -p` (print) mode, and a team can't contain another team.
- The lead spawns teammates by agent type (`kingdom-game-designer`, ...) and gives each a short name (`designer`, `architect`, `gameplay`, `anim`, `world`, `ui`, `artist`, `qa`, `integration`). Each teammate keeps the model in its file unless the lead names another.
- **Teammates message each other directly by name** (`SendMessage`) and share one **task list** (`TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`): tasks have owners and dependencies; finishing a task unblocks the ones waiting on it. Teammates report progress and blockers to the lead.
- The shared task list is the team's live board for the session (it lives under `~/.claude/tasks/<team>/`). **`AGENT_BOARD.md` stays the lasting record**: the lead copies tasks there at the start and results at the end, and handoffs still go into `AGENT_HANDOFFS.md`, so the next session (and the owner) can see what happened.
- Teammates share the lead's permission settings. Everything else in this file (ownership, git status first, no commits/pushes, approval list) applies unchanged.
- Without teams (subagents only), section 1 applies: the orchestrator relays.

## 2. The shared files
| File | What it holds | Who writes |
|---|---|---|
| `AGENT_BOARD.md` | Every task: ID, owner, status, dependencies, files, priority, done-when | Orchestrator and Creative Director create tasks; the owning agent updates its own row's status |
| `AGENT_DECISIONS.md` | Decisions approved by the owner (or inside an approved task's scope) | Creative Director; others add only with a named approval |
| `AGENT_HANDOFFS.md` | One entry per handoff between agents | Every agent, at the end of every task |
| `AGENT_CONFLICTS.md` | Disagreements and anything waiting on the owner | Any agent |
| `AGENT_STUDIO.md` | This file: roles, map, rules | Only with owner approval |

The project's own docs stay the source of truth for the game: `SPEC.md` (never edit), `DESIGN.md`, `PRIORITIES.md` (the only "next" list), `TODO.md`, `HANDOFF.md`, `DESIGN_INBOX.md` and the area docs listed in `CLAUDE.md`. The `AGENT_*` files track **studio work**, not game design. A decision only becomes canon when it is written into the right project doc.

`KINGDOM_MASTER_CONTEXT.md` does not exist (checked 2026-11-27). The master context is `CLAUDE.md` -> `HANDOFF.md` -> `PRIORITIES.md` -> `SPEC.md` -> `DESIGN.md`.

## 3. The team
Models are set in each agent's file (`model:` line). See section 8 to change them.

| # | Agent (file name) | Model | Owns | Writes code? |
|---|---|---|---|---|
| 1 | Executive Creative Director (`kingdom-creative-director`) | opus | Vision, priorities, feature review, final creative review, conflict calls | No. Docs and `AGENT_*` files only |
| 2 | Game Designer (`kingdom-game-designer`) | opus | Combat, classes, abilities, enemies, bosses, loot, progression, balance, co-op feel | No. Design specs and proposals |
| 3 | Technical Architect (`kingdom-technical-architect`) | opus | Godot 4.7.2 / GDScript architecture, networking, data structures, performance, standards | No. Technical specs and reviews |
| 4 | Gameplay Engineer (`kingdom-gameplay-engineer`) | sonnet | Combat, abilities, damage, stamina/mana, cooldowns, status effects, enemy AI hooks, classes | Yes: `game/combat/`, `game/classes/`, `game/player/` (gameplay parts), `game/enemies/` (behaviour), `data/` |
| 5 | Character & Animation Engineer (`kingdom-character-animation`) | sonnet | Movement feel, animation, skeleton, IK modifiers, weapon/attack/cast/dodge/block animation, equipment attachment | Yes: `game/characters/`, `assets/characters/`, `assets/equipment/`, animation parts of `player.gd` / `enemy.gd` |
| 6 | World & Level Designer (`kingdom-world-level`) | sonnet | Zones, dungeons, encounter placement, bosses' arenas, camps, settlements, pacing | Yes: `levels/`, `game/world/`, `data/spawns/` |
| 7 | UI/UX Engineer (`kingdom-ui-ux`) | sonnet | HUD, menu book, inventory, character panel, hotbar, map, quest UI, combat feedback, accessibility | Yes: `game/ui/`, UI theme and fonts |
| 8 | Technical Artist (`kingdom-technical-artist`) | sonnet | Materials, shaders, textures, lighting, fog, particles, spell/weapon VFX, asset optimisation | Yes: `levels/common/`, `assets/` (materials, textures, VFX), `game/combat/combat_fx.gd` |
| 9 | QA & Playtest Engineer (`kingdom-qa-playtest`) | sonnet | Automated checks, regression, 3-player check, balance and performance checks, bug repro, acceptance | Only `tests/` |
| 10 | Integration & Build Engineer (`kingdom-integration-build`) | sonnet | Git status, conflicts, imports, full check runs, build stability, friends build, commit prep | Only integration fixes it is asked for; never feature work |

**File-area owners are defaults, not walls.** A task on the board names its exact files; that list is what counts. Shared hot files (`game/player/player.gd`, `game/enemies/enemy.gd`, `game/world/gullet.gd`, `game/ui/hud.gd`, `project.godot`, `game/net/*`) may have **only one writer at a time**, named on the board.

## 4. Who needs whom (dependency map)
```
                    Owner (final say on design, scope, commits, pushes)
                                     |
                      1 Creative Director  <-- resolves AGENT_CONFLICTS
                       /             \
          2 Game Designer  <---->  3 Technical Architect
           (what + numbers)         (how + where in code)
                       \             /
                 Task breakdown on AGENT_BOARD
         /        |         |          |          \
   4 Gameplay  5 Char/Anim  6 World  7 UI/UX  8 Tech Artist
         \        |         |          |          /
                     9 QA & Playtest (independent check)
                                |
                    10 Integration & Build
                                |
                 1 Creative Director (final review) -> report to owner
```
Typical needs:
- Gameplay -> Character/Animation for any new move (hit windows follow the animation clock), -> UI for new resources/cooldowns, -> Tech Artist for hit/spell effects.
- World -> Gameplay for enemy behaviour, -> Tech Artist for lighting/perf, -> QA for `zone`, `gullet`, `outpost`, `perf_zone`.
- Anything networked -> Technical Architect review first (host authority rules in `DESIGN.md` 13.4).
- Anything touching numbers -> Game Designer owns the numbers; engineers do not invent balance values outside the spec.

## 5. Workflow
### Full (new feature, combat/network change, anything touching 3+ areas)
1. **Request**: the owner asks. The orchestrator adds a task to `AGENT_BOARD.md` (status `proposed`).
2. **Creative review**: Creative Director checks it against `SPEC.md`, `DESIGN.md`, `PRIORITIES.md`. Out: go / change / ask owner.
3. **Design**: Game Designer writes the gameplay spec (numbers, rules, acceptance criteria).
4. **Technical review**: Technical Architect reads the existing code and says where it goes, what to reuse, what to avoid, which files.
5. **Task assignment**: tasks on the board, one primary owner each, dependencies and exact files.
6. **Implementation**: engineers build their task. Need help? Write the request in the handoff; the orchestrator routes it.
7. **QA**: QA runs the relevant checks itself and tests the acceptance criteria. It never takes another agent's word.
8. **Integration**: Integration Engineer checks git status, conflicts, imports, the full relevant check set.
9. **Creative review**: Creative Director checks the result against the intended experience.
10. **Report**: to the owner: what changed, files, what was tested, passed, failed, remaining issues, next task.

### Short (bug fix, tuning a number already decided, one-file change)
Owner -> engineer -> QA -> report. Integration only if several files or a hot file changed. Creative Director only if the feel changes.

### Docs-only or question
One agent, no QA.

## 6. Ownership and parallel work rules
1. **Before editing, every agent runs `git status`** and reads the board. If a file it needs shows changes it did not make, it stops and reports. It never reverts, overwrites, stashes or "cleans up" someone else's changes.
2. Only the task's owner edits the task's files. Need a file owned by another open task? Write a handoff request; do not edit it.
3. Parallel tasks are allowed only when their file lists don't overlap and neither depends on the other's unfinished work. OK in parallel: UI work + isolated combat work, separate asset prep, test writing + docs, different zones. Never in parallel: two tasks on the same script/scene, on the networking, on the same combat system, or on unfinished architecture.
4. Mark a task `in_progress` with your agent name before starting; `review` when handed to QA; only QA moves it to `verified`; only the orchestrator moves it to `done` after integration.
5. New `class_name` scripts: run the import (`--headless --path . --import`) before any check (HANDOFF "Things to know").
6. Checks run **one at a time** (shared port 31499). Port 31415 is the owner's live game: never use it.

## 7. Rules for everyone
- **The owner has no coding experience.** Reports in plain language.
- **Status of every idea is explicit**: `established` (in the docs or built), `approved` (owner said yes, logged in `AGENT_DECISIONS.md` or `DESIGN_INBOX.md` Filed), `proposal` (an agent suggests it), `idea, not decided yet` (planning only, never built). Never turn a proposal or idea into code or canon.
- **Ask the owner (through `AGENT_CONFLICTS.md` and the orchestrator) before**: changing established design or core gameplay direction, changing progression or balance philosophy, removing a feature or system, rewriting major architecture, deleting important assets or data, working outside the task's scope, spending money or using paid services.
- **Never commit or push** unless the owner has said so for that piece of work. `CLAUDE.md`'s "commit after changes" applies only once the owner approves commits for the task. Commits use the local identity "Kingdom Dev" and only include the task's own files.
- Respect `PRIORITIES.md`: right now the priority is **stabilise, playtest, fix** before new content. Don't add content when that is the priority unless the owner assigned it.
- No rewrites of working systems without a shown reason. No new abstractions without a need. Reuse before building.
- Everything original: no names, lore or assets from other games. Currency is **coins**.
- Godot console: `& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/run.gd -- <check>`. Git: `C:\Program Files\Git\cmd\git.exe`.

## 8. Models (changeable)
Default: Opus for the Creative Director, Game Designer and Technical Architect; Sonnet for the seven others. The aliases `opus` and `sonnet` always mean the newest model of that family.
- **Change one agent:** edit the `model:` line in its `.claude/agents/kingdom-*.md` file (`opus`, `sonnet`, `haiku`, a full model id, or `inherit` to use the main session's model).
- **Change for one run:** the orchestrator passes a `model` when it starts the agent (for a hard problem, use Opus for an engineer).
- **Change all at once:** set the environment variable `CLAUDE_CODE_SUBAGENT_MODEL` before starting Claude Code; it overrides every agent's line.

## 9. The handoff block (every agent ends with this)
Each agent appends this to `AGENT_HANDOFFS.md` and repeats it as the last part of its report:
```
### H-<number>: <task id> <short title>
- **From:** <agent>  **To:** <agent or orchestrator>
- **Task:** ...
- **Work completed:** ...
- **Files changed:** ... (or "none")
- **Important findings:** ...
- **Remaining work:** ...
- **Required next action:** ...
- **Status claims:** what I checked myself vs. what I'm assuming
```

## 10. Escalation
1. Try reasonable fixes within the task's scope; check the docs.
2. Ask the right specialist (write the request in your handoff: who, what, which files, what you need back).
3. Still stuck, or it needs a design/scope/approval call: add it to `AGENT_CONFLICTS.md` with options and a recommendation, set the board row to `blocked`, and stop. The orchestrator takes it to the Creative Director, then to the owner if needed.
4. Don't stop for small doubts the docs already answer.

## 11. Autonomous mode (owner's standing rule, 2026-11-27)
Once the owner assigns a task, the team carries it through design, build, QA, fixes, retest, integration and review without asking at every step, and reports at the end. Agents may change relevant scripts and scenes, add supporting files and tests, refactor what the task needs, and fix bugs found on the way. They stop for the approval list in section 7. After a task is done, the orchestrator may start the next board task only if it is already `ready`, authorised by the owner, has clear done-when criteria and needs no new major design decision. Never invent priorities or widen scope to keep busy.

**A task is done only when** it meets its criteria, passes the relevant checks (run by QA, not just the builder), has known failures written down, has been checked for integration problems, and the project docs (`HANDOFF.md`, `TODO.md`, `PRIORITIES.md`, area doc) are updated where needed.
