# AGENT HANDOFFS

*Every agent appends one entry at the end of every task, newest at the bottom. Format in `AGENT_STUDIO.md` section 9. The receiving agent reads the entry addressed to it before starting. Entries are never edited afterwards, only followed by new ones.*

---

### H-000: STU-003 Training dummy damage readout (team test brief)
- **From:** orchestrator (for the owner, who asked for a small isolated test feature, 2026-11-27)  **To:** kingdom-creative-director (team lead)
- **Task:** Prove the Agent Team works by having **designer** (kingdom-game-designer), **architect** (kingdom-technical-architect), **gameplay** (kingdom-gameplay-engineer) and **qa** (kingdom-qa-playtest) plan and build one small, isolated feature together, talking to each other directly and through the shared task list.
- **The feature:** the straw training dummy (`game/combat/training_dummy.gd`, used only in the sandbox maps `levels/sandbox/combat_test.tscn` and `movement_test.tscn`) shows a small damage readout above itself, so the owner can compare weapons and abilities while tuning: at least damage per second over a short recent window and the total of the current string of hits, resetting after a pause. The designer decides the exact numbers and wording; the architect decides how (it must work for every player in co-op, or the spec must say why it's local only).
- **Work completed:** nothing yet.
- **Files allowed:** `game/combat/training_dummy.gd`; `game/combat/training_dummy.tscn` only if needed; new `tests/dummy_check.gd`. **Nothing else in the game.** The team may also write the `AGENT_*.md` files.
- **Important findings:** another session is editing combat and ability files right now (`hit_info.gd`, `ability_caster.gd`, `player.gd`, `enemy.gd`, Arcane Surge Wave; full list in `AGENT_BOARD.md`). Read them if useful, never edit them. Before running any Godot check, make sure no other Godot process is running (`tasklist | findstr Godot`): checks share port 31499. Run the Godot console without quotes as `/c/Users/reals/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run.gd -- <check>`.
- **Done when:** (1) designer's spec and architect's review are in this file; (2) gameplay built it inside the allowed files; (3) qa wrote `tests/dummy_check.gd`, ran it and `combat_check` itself, and both pass (or the failure is written down with its cause); (4) `git status` shows no changes outside the allowed files from this team; (5) the lead reports to the owner how the team communicated (who messaged whom, what the task list held, what reviews happened) and what didn't work.
- **Not allowed:** commits, pushes, edits to other game files.
- **Required next action:** lead spawns the four teammates and runs the task.

---

### H-001: STU-003 Design spec: training dummy damage readout
- **From:** designer (kingdom-game-designer)  **To:** architect (kingdom-technical-architect), then gameplay and qa
- **Task:** T1 Design spec for the sandbox-only damage readout above the training dummy (brief H-000, lead verdict GO).
- **Work completed:** spec below. Status of everything in it: **proposal** inside an owner-assigned, lead-approved test task (sandbox debug aid, not game content, no balance change).

#### Goal (player feeling)
The owner swings at the dummy with a weapon or ability and, at a glance, reads "how hard is this hitting per second" and "how much did that whole string do", then switches weapon and compares. It should read like a quiet debug panel, not a reward popup: small, steady, no flashing.

#### What it shows (exact wording)
One small two-line text label floating above the dummy:
```
DPS 42.5
String 312 (7 hits, 2 crits)
```
- Line 1: `DPS ` + damage per second, **1 decimal** always (`DPS 0.0`, `DPS 15.0`, `DPS 42.5`).
- Line 2: `String ` + total damage of the current string, **whole number** (rounded the same way as the floating damage numbers, `roundi`), then ` (N hits, M crits)`. Always both counts, singular not special-cased except: `1 hit` / `1 crit` use the singular word. Zero crits shows `0 crits`.
- Before the first hit since the scene loaded, the label is hidden.

#### Rules and numbers
All numbers `(start)`: fine to tweak after the owner tries it.
1. **What counts:** every call to `receive_hit` whose `hit.damage > 0`. The amount counted is `hit.damage` exactly as received (the same value the floating number shows, before rounding). Crits count normally (their damage is already multiplied); a hit with `is_crit` also adds 1 to the crit count.
2. **Zero or negative damage** (`hit.damage <= 0`): ignored by the readout completely: no hit count, no crit count, does not start or extend a string. (The dummy's existing floating number, sparks and wobble are unchanged.)
3. **Blocked/parried/dodged:** the dummy never blocks; it always returns `HIT`. Nothing to handle. If that ever changes, only hits that return `HIT` count.
4. **String:** starts on the first counted hit. Each counted hit extends it. The string **ends after 3.0 s with no counted hit** `(start)`.
5. **Live DPS (string active):** rolling window of **5.0 s** `(start)`.
   `DPS = (sum of damage of hits with hit_time > now - 5.0) / clamp(now - string_start, 1.0, 5.0)`
   Boundaries: the string has ended when `now - last_hit_time >= 3.0`; the label hides when `now - last_hit_time >= 20.0`.
   The 1.0 s floor stops a single opening hit from showing a silly huge number; the 5.0 s cap makes it a true rolling window on long strings. Hits older than 5.0 s drop out of the sum but still count in the string total.
6. **When the string ends** (3.0 s pause): the label **freezes** and turns gray. Line 1 now shows the **string's average**: `DPS = string_total / max(last_hit_time - string_start, 1.0)`. Line 2 keeps the final total and counts. This is the "result" the owner reads after a test string.
7. **Next hit after a string ended:** total, counts and window reset to zero, then the new hit is counted (so the first hit of a new string reads `String <that hit> (1 hit, ...)`). Colour goes back to active.
8. **Hide:** 20.0 s after the last counted hit, the label hides. The next counted hit shows it again (as a new string).
9. **Update rate:** text refreshes **10 times a second** (every 0.1 s) while a string is active, and **immediately on every counted hit** and at the moment the string ends. No refresh needed while frozen or hidden.
10. **Settings toggle:** if `CombatFx.show_damage_numbers` is off, the label is hidden (the numbers are still tracked, so turning it back on mid-string shows correct values).

#### Look and placement
- A billboard text label, child of the dummy, at **3.0 m above the dummy's origin** (the floating damage numbers spawn at 1.9 m and rise about 0.9 m, so 3.0 m clears them). It follows the dummy when it patrols. It must **not** tilt with the hit wobble (the wobble only tilts `MeshInstance3D` children; a label is not one, so this is automatic, but keep it that way).
- Size: smaller than the damage numbers so it never competes with them: font size **28**, outline **8** (black, alpha 0.85), `pixel_size` 0.006, drawn on top (no depth test), like the floating numbers. Left or centre alignment: centre.
- Colours: active string `Color(0.95, 0.95, 0.92)` (the normal damage-number white); ended/frozen `Color(0.75, 0.75, 0.72)` (the gray used by `CombatFx.word`). No gold/yellow: that colour means "crit" on the floating numbers.
- Font: the default label font (same as the floating numbers). DESIGN.md 12.4 names IBM Plex Mono for debug readouts, but it is not in the project yet; do **not** add a font for this test task. Open question 2.

#### Co-op: local only, per player (designer's call)
Each player's screen shows **only the damage that player dealt**. Reason:
- In this code, hits are resolved on the attacker's own machine (`player.gd` `_physics_process` returns early for remote players; `_land_hit` and `ability_caster._strike` call the dummy's `receive_hit` locally), and the dummy is not networked. So a local readout naturally shows "your" damage, for free, with no network traffic and no files outside the allowed list.
- For tuning, "my damage with this weapon" is the number the owner wants. A combined number mixes two players' weapons and tells you nothing about either.
- Architect: please confirm hits from remote players never reach a dummy's `receive_hit` on another machine (if they do, the readout should count only hits whose `hit.attacker` is the local authority player, or `attacker == null` for tests). Combined co-op totals would need a networked readout: out of scope, not wanted.

#### Edge cases
- **Several dummies:** each has its own independent readout.
- **Several local hits in the same frame** (a sweep hitting the dummy twice, an ability and a blow together): each counts; same timestamp is fine.
- **Player dies, is downed or respawns mid-string:** nothing special; the string ends on the 3.0 s pause as usual.
- **Scene reload:** everything resets (no saving).
- **Lag:** not applicable (local only).
- **Very long strings** (minutes of hitting): the rolling-window record must not grow without limit; hits older than 5.0 s can be dropped from it (the total and counts are kept as plain numbers).
- **Time source:** use game time that tests can drive (see criteria); the readout must not depend on wall-clock time.

#### Acceptance criteria (headless; "t" is simulated seconds since the scene loaded, hits are `HitInfo` with the given damage sent to `receive_hit`)
The architect decides how tests drive time (for example a function that takes the current time, or stepping physics frames). QA checks values with a tolerance of 0.05 for DPS.
1. Before any hit, the readout is hidden.
2. 3 hits of 10 at t = 0.0, 0.5, 1.0; read at t = 1.0: string total 30, 3 hits, 0 crits, DPS 30.0 (span floored to 1.0). Text line 2 is exactly `String 30 (3 hits, 0 crits)`.
3. Same hits, read at t = 2.0: DPS 15.0 (30 / 2.0), still active (white).
4. One hit of 25 at t = 0.0, read at t = 0.0: line 1 exactly `DPS 25.0`, line 2 exactly `String 25 (1 hit, 0 crits)`.
5. One crit hit of 40 (`is_crit = true`) and one normal hit of 10: total 50, `2 hits, 1 crit`.
6. A hit with damage 0 and a hit with damage -5: readout stays hidden, counts stay 0. After a real hit, a 0-damage hit 2.9 s later does **not** stop the string ending at 3.0 s after the real hit.
7. Hits of 10 at t = 0, 1, 2, 3, 4, 5, 6 (7 hits); read at t = 6.0: total 70, 7 hits; rolling sum covers hits after t = 1.0 (t = 2..6 → 50; the hit exactly at t = 1.0 is outside a window of `> now - 5.0`), span clamped to 5.0, DPS 10.0.
8. String end: hits of 10 at t = 0.0 and 1.0; at t = 3.9 still active; at t = 4.0 or later (3.0 s after the last hit) frozen and gray, line 1 shows the average `DPS 20.0` (20 / max(1.0, 1.0)), line 2 `String 20 (2 hits, 0 crits)`.
9. Average with a longer string: hits of 10 at t = 0, 2, 4 → after it ends, `DPS 7.5` (30 / 4.0).
10. New string: after criterion 8 has ended, a hit of 15 at t = 6.0 → `String 15 (1 hit, 0 crits)`, DPS 15.0, active colour.
11. Hide: a single hit at t = 0.0; at t = 19.9 visible (frozen); at t = 20.0 or later hidden; another hit then shows it as a new string.
12. With `CombatFx.show_damage_numbers = false`, after hits the label is hidden; set back to true without new hits, it shows the correct current values.
13. Two dummies: hitting dummy A leaves dummy B hidden.
14. Rounding: hits of 10.4 and 10.4 → line 2 `String 21 (...)` (20.8 rounded), DPS line uses the unrounded sum.
15. The dummy still returns `HitInfo.Result.HIT`, still shows its floating number and still wobbles (existing behaviour unchanged); `combat_check` still passes.
16. Memory: after 200 hits spread over 100 s, the stored rolling-window record holds no hits older than 5.0 s (QA may check the record's size if the architect exposes it; otherwise skip and note).

#### Data files
None. This is a debug aid, not balance: the numbers (3.0 s, 5.0 s, 1.0 s floor, 20.0 s, 0.1 s, 3.0 m, sizes) can be constants or `@export`s at the top of `training_dummy.gd` with a one-line comment each. No `.tres`.

- **Files changed:** `AGENT_HANDOFFS.md` (this entry only).
- **Important findings:** hits on the dummy are resolved locally on the attacker's machine (see co-op section), which makes "local only, your own damage" both the simplest and the most useful choice. The dummy applies no armor or hex bonus, so `hit.damage` is the true number. IBM Plex Mono (DESIGN 12.4 debug font) is not bundled.
- **Remaining work:** technical review (T2), build (T3), test (T4).
- **Required next action:** architect reviews: confirm the co-op assumption, choose how tests drive time, say whether constants or `@export`s, and whether `training_dummy.tscn` needs touching (designer expects not: the label can be made in code). Push back on any number for technical reasons; designer answers in an addendum H-001a.
- **Status claims:** I read `training_dummy.gd`, `combat_fx.gd`, `hit_info.gd`, `player.gd` (`_physics_process`, `_land_hit`), `ability_caster.gd` (`_strike`) and DESIGN.md 12.4 myself. The claim that remote players' hits never reach another machine's dummy is from reading those lines, not from running co-op: architect to confirm.

#### Open questions (none block the build)
1. Should the readout also show the biggest single hit? Left out to keep it small; the floating numbers already show each hit.
2. Use IBM Plex Mono later when the UI font pass bundles it? (UI/owner call, not this task.)
3. Status damage-over-time (bleed ticks) does not apply: the dummy has no status buildup. If it ever gets one, its ticks should count as hits without crits.

---

### H-001a: STU-003 addendum to H-001 after architect's technical notes
- **From:** designer  **To:** architect, gameplay, qa
- **Task:** fold architect's four facts into the spec. Nothing in H-001 changes except what is written here.
- **Work completed:**
  1. **Co-op:** confirmed by architect (dummy not networked; each machine only calls `receive_hit` for its own player's hits; remote arrow copies have no shooter). The rule stays: **each player sees their own numbers**. No RPC.
  2. **What counts, reworded:** the readout counts **hits that land on the dummy** (calls to its `receive_hit` with damage > 0). That covers weapon swings, heavies and charged heavies, ripostes, arrows, and ability strikes that go through a weapon swing. **Known limits (not counted, out of scope):** area abilities and the Arcane Surge Wave (they only search the `enemies` group, which the dummy is not in), and bleed/poison/frost ticks (the dummy has no status system). This replaces the "ability and a blow together" example in H-001's edge cases.
  3. **Damage shown:** final hit damage after crit, sneak/flank bonus and armor (the dummy has none), as received. Same as H-001 rule 1.
  4. **Clock:** the dummy keeps its own clock, advanced by physics time (it stops while the game is paused), and stamps each hit. Fine. Tests feed hits at exact clock times.
  5. **DPS formula: H-001 stays as written:** `sum of damage with hit_time > now - 5.0` divided by `clamp(now - string_start, 1.0, 5.0)`. Architect suggested dividing by `max(time since the first hit inside the window, 1.0)`. I'm keeping mine because it is more accurate on a steady string. Example: hits of 10 once a second, read at t = 6: the window holds t = 2..6, which is 50 damage. Mine gives 50 / 5 = 10.0, the true rate. The other formula gives 50 / 4 = 12.5, which runs about 25% high. Both agree for strings under 5 s. Acceptance criterion 7 (DPS 10.0) tests exactly this case.
  6. **Update rate:** about 10 times a second, plus right away on every counted hit and when the string ends (H-001 rule 9). Agreed.
- **Files changed:** `AGENT_HANDOFFS.md` (this entry).
- **Remaining work:** T2 sign-off, T3 build, T4 tests.
- **Required next action:** architect finishes T2 against H-001 + H-001a.
- **Status claims:** items 1-4 are architect's findings, which I accept without re-checking them in code. Item 5 is my design call; I checked the arithmetic myself.

---

### H-002: STU-003 Technical review and build plan: training dummy damage readout
- **From:** architect (kingdom-technical-architect)  **To:** gameplay (kingdom-gameplay-engineer), cc qa (kingdom-qa-playtest)
- **Task:** T2 technical review of H-001 + H-001a; exact build plan and testable API.
- **Work completed:** reviewed the spec against the code. **Every number and rule in H-001 + H-001a works technically; no pushback.** I checked the arithmetic of criteria 2-11 and 14 against the formulas below. Answers to designer's four questions:
  1. **Co-op (confirmed from code, not from a co-op run):** remote players' hits never reach another machine's dummy. `player.gd:1376` `_physics_process` returns early for non-authority players, so `_land_hit` (called from `player.gd:1972` and via `arrow_hit`) only runs on the attacker's own machine. Remote arrow copies (`_net_arrow`, `player.gd:2081`) get no `shooter`, so they never call `arrow_hit` (`arrow.gd:51-53`). `ability_caster._strike` (`ability_caster.gd:385`) only targets nodes from the `enemies` group (`_enemies_near`, `:444`), and the dummy isn't in it. `training_dummy.gd` has no RPCs. **Decision: local-only. No `hit.attacker` filter is needed; don't add one** (tests send `attacker == null`, and a filter would only add a way to break).
  2. **Time:** the dummy owns a clock, `_readout_clock`, advanced by `delta` in its existing `_physics_process`, so it stops when the tree pauses and never reads wall-clock time. Every query takes the time as a parameter `at`, so tests pass fake times and need no real waits. `set_clock(t)` lets a test stamp real `receive_hit` calls at an exact time.
  3. **Constants, not `@export`s.** Exports would let the sandbox scenes' instances override values (8 instances across 2 maps) and get re-saved by the editor. Constants also let the test read `TrainingDummy.READOUT_WINDOW` etc. Tuning means editing one line.
  4. **No `.tscn` change.** The label is made in code in `_ready`. The wobble loop (`training_dummy.gd:53-55`) only tilts `MeshInstance3D` children, and `Label3D` is not one, so the label stays upright automatically. Patrol moves the body, so the child label follows.

#### Files
- `game/combat/training_dummy.gd`: gameplay (only writer).
- `tests/dummy_check.gd`: qa (only writer; a draft exists already, see "Note for qa" below).
- Nothing else. `combat_fx.gd` and `hit_info.gd` are **reused read-only**: no new helper in CombatFx (it belongs to the tech artist, and `hit_info.gd` is being edited by another session).
- The two can be built **in parallel**: separate files, and the API below is fixed.

#### Build plan for `training_dummy.gd` (gameplay)
Constants (top of the file, one-line comment each):
```
const READOUT_WINDOW := 5.0       # rolling DPS window (s)
const READOUT_SPAN_FLOOR := 1.0   # DPS divides by at least this (s)
const READOUT_RESET := 3.0        # a pause this long ends the string (s)
const READOUT_HIDE_AFTER := 20.0  # label hides this long after the last hit (s)
const READOUT_REFRESH := 0.1      # label refresh while a string is active (s)
const READOUT_HEIGHT := 3.0       # label height above the dummy's origin (m)
const READOUT_COLOR := Color(0.95, 0.95, 0.92)
const READOUT_FROZEN_COLOR := Color(0.75, 0.75, 0.72)
```
State (plain numbers; the only arrays are the rolling window):
```
var readout_label: Label3D
var _readout_clock := 0.0
var _readout_tick := 0.0
var _str_total := 0.0
var _str_hits := 0
var _str_crits := 0
var _str_start := 0.0
var _last_hit := 0.0
var _win_times := PackedFloat64Array()
var _win_amounts := PackedFloat64Array()
```
Public API (exact names; qa's test calls these):

| Function | Does |
|---|---|
| `clock() -> float` | returns `_readout_clock` |
| `set_clock(t: float) -> void` | sets `_readout_clock` (tests only; say so in the doc comment) |
| `record_hit(amount: float, at: float, is_crit := false) -> void` | if `amount <= 0`, return. If `_str_hits == 0` or `at - _last_hit >= READOUT_RESET`, start a new string: zero the total and counts, clear both window arrays, `_str_start = at`. Then add to the total, hits and crits, set `_last_hit = at`, append to the window, and prune entries with `time <= at - READOUT_WINDOW` (a `while` loop with `remove_at(0)`; the window holds a few dozen at most). |
| `string_active(at: float) -> bool` | `_str_hits > 0 and at - _last_hit < READOUT_RESET` |
| `string_total(at: float) -> float` | `_str_total`: **kept after the string ends** (H-001 rule 6 freezes it) and zero only before the first hit or until the next string starts. `at` is accepted for a uniform API. |
| `string_hits(at: float) -> int`, `string_crits(at: float) -> int` | the counts, same rule as `string_total` |
| `dps(at: float) -> float` | 0 if no hits. Active: sum of window amounts with `time > at - READOUT_WINDOW` / `clampf(at - _str_start, READOUT_SPAN_FLOOR, READOUT_WINDOW)`. Ended: `_str_total / maxf(_last_hit - _str_start, READOUT_SPAN_FLOOR)` |
| `readout_visible(at: float) -> bool` | `_str_hits > 0 and at - _last_hit < READOUT_HIDE_AFTER and CombatFx.show_damage_numbers` |
| `readout_text(at: float) -> String` | `"DPS %.1f\nString %d (%d %s, %d %s)" % [dps(at), roundi(_str_total), hits, "hit" if hits == 1 else "hits", crits, "crit" if crits == 1 else "crits"]` |
| `window_size() -> int` | `_win_times.size()` (criterion 16) |
| `update_readout(at: float) -> void` | applies the state to the label: `visible = readout_visible(at)`; if visible, `modulate = READOUT_COLOR if string_active(at) else READOUT_FROZEN_COLOR`; set `text` **only if it differs** (avoids re-shaping the label's text every refresh) |
| `refresh_readout() -> void` | `update_readout(_readout_clock)` |

Changes to existing functions:
- `_ready()`: after the existing lines, build `readout_label = Label3D.new()` with `name = "Readout"`, `position = Vector3.UP * READOUT_HEIGHT`, `billboard = BaseMaterial3D.BILLBOARD_ENABLED`, `no_depth_test = true`, `render_priority = 9` (one below the floating numbers' 10, so they draw over it), `font_size = 28`, `outline_size = 8`, `outline_modulate = Color(0, 0, 0, 0.85)`, `pixel_size = 0.006`, `horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER`, `visible = false`, then `add_child`. Default font: no font file.
- `receive_hit(hit)`: keep everything it does now (number, sparks, wobble, `return HIT`). Before the return add: if `hit.damage > 0.0`, `record_hit(hit.damage, _readout_clock, hit.is_crit)` then `refresh_readout()`.
- `_physics_process(delta)`: add `_readout_clock += delta`, and if `_str_hits > 0 and _readout_clock - _last_hit < READOUT_HIDE_AFTER + 0.5`, then `_readout_tick += delta`; when `_readout_tick >= READOUT_REFRESH`, set `_readout_tick = 0.0` and `refresh_readout()`. That covers the live 10/s refresh, the switch to gray at the moment the string ends (to within 0.1 s), the hide at 20 s, and the settings toggle (criterion 12). It must keep running while frozen; that's one bool check and an unchanged-text compare. Leave the existing `_time` (patrol) alone.

**Performance:** no per-frame allocation. One string format per dummy at most 10 times a second, only for about 20 s after a hit. The packed arrays are tiny. The label exists only on sandbox dummies (8 total). Negligible.

#### Note for qa (`tests/dummy_check.gd`)
- **Registration: none.** `tests/run.gd` loads `res://tests/<name>.gd` by name. Run: `... --headless --path . --script res://tests/run.gd -- dummy_check`, then `-- combat_check`. Before the first run, `--headless --path . --import` (new file + `.uid`). Check for other Godot processes first (port 31499).
- **Your current draft assumes my earlier wording, which the spec overrides:** after a string ends, `string_total`/`string_hits` **keep** the frozen values (H-001 rule 6); they reset only when the next hit starts a new string. Lines 66-67 of the draft must change. `refresh_readout()` still exists; `update_readout(t)` is new. `record_hit(amount, t)` with two arguments still works (`is_crit` defaults to false).
- Map the acceptance criteria to the API: use `record_hit(amount, t, is_crit)` plus `dps/string_*/readout_text/readout_visible(t)` for criteria 2-11, 14 and 16. For label checks (1, 8 colour, 11, 12, 13), call `update_readout(t)` and inspect `dummy.get_node("Readout") as Label3D` (`visible`, `modulate`, `text`). For real `receive_hit` cases (6, 15), call `set_clock(t)` immediately before `receive_hit`, **in the same frame** (any `await` lets `_physics_process` advance the clock).
- Use a **fresh time base per case** (e.g. `t0 = 1000 * case_number`): each first hit after a 3.0 s gap starts a new string, so cases can't leak into each other. Criterion 13: `Practice/Dummy2` must stay `readout_visible == false` and `string_hits == 0`. Criterion 12: restore `CombatFx.show_damage_numbers = true` afterwards.
- Float checks: DPS within 0.05 (spec). Fake times like 1.0 and 6.0 are exact in floats, so the strict `>` window boundary in criterion 7 is deterministic.

- **Files changed:** `AGENT_HANDOFFS.md` (this entry only).
- **Important findings:** (a) Local-only is not a compromise here. It's how the dummy already behaves (friends don't see each other's damage numbers on dummies today), and it needs no network code. (b) Known limits as in H-001a: area abilities and the Surge Wave never touch the dummy (they only search `enemies`; adding the dummy to that group would expose it to about 25 enemy-only loops, some calling methods it lacks, e.g. `scale_threat` at `ability_caster.gd:405`). Not this task. (c) README's check list (`README.md:36`) doesn't name `dummy_check`. It's outside the allowed files, so the lead decides whether to add it at the end.
- **Remaining work:** T3 build (gameplay), T4 test (qa), then qa runs `dummy_check` and `combat_check`.
- **Required next action:** gameplay builds `training_dummy.gd` exactly as above. qa adjusts the draft to the final API and spec criteria 1-16. Questions go to architect.
- **Status claims:** checked myself: the code paths cited above (by reading, with line numbers), the sandbox placement (`levels/sandbox/combat_test.tscn` `Practice/Dummy1`, `Dummy2`; `movement_test.tscn` 6 dummies), the test conventions (`tests/run.gd`, `tests/combat_check.gd` end/exit code), the spec arithmetic, and `git status` (only `hit_info.gd` modified in `game/combat/`, by the other session; `tests/dummy_check.gd` untracked, qa's draft). Assumed, not run: co-op behaviour (no net check exercises dummies) and the label's look in a real window.

---

### H-002a: STU-003 API addendum to H-002 (qa's questions)
- **From:** architect  **To:** gameplay, cc qa, lead
- **Task:** close qa's API questions. Everything else in H-002 stands.
- **Work completed:** (a) the crit flag is in H-002: `record_hit(amount, at, is_crit := false)`, and **`record_hit` itself ignores `amount <= 0`**, so the rule lives in one place (receive_hit also checks it, which is harmless). (b) `readout_text(at)` returns the full two-line string `"DPS x\nString n (...)"`. (c) **Added `readout_color(at: float) -> Color`**: `READOUT_COLOR` while `string_active(at)`, otherwise `READOUT_FROZEN_COLOR`. `update_readout(at)` uses it and sets `label.modulate` (not `font_color`). `readout_visible(at)` stays as in H-002. `refresh_readout()` stays parameterless and means `update_readout(clock())`; qa uses `update_readout(t)` for fake times. (d) Constant names: `READOUT_WINDOW` 5.0, `READOUT_SPAN_FLOOR` 1.0, `READOUT_RESET` 3.0, `READOUT_HIDE_AFTER` 20.0, `READOUT_REFRESH` 0.1, `READOUT_HEIGHT` 3.0. (e) `window_size() -> int`. (f) `CombatFx.show_damage_numbers` is checked **only in `readout_visible(at)`**, which the label update uses, so hits are always tracked and turning the setting back on shows the right values on the next refresh (criterion 12). The lead's DPS ruling is already H-002's formula, and I have no technical objection.
- **Files changed:** `AGENT_HANDOFFS.md` (this entry).
- **Important findings:** I re-checked the local-only co-op claim against the real hit path. It holds: the code citations are in H-002, item 1.
- **Remaining work / Required next action:** gameplay adds `readout_color` along with the H-002 API; qa writes the test against these names.
- **Status claims:** API decisions only; nothing built or run by me.

---

### H-003: STU-003 Build: training dummy damage readout
- **From:** gameplay  **To:** qa
- **Task:** T3 build of H-002 in `game/combat/training_dummy.gd`.
- **Work completed:** built exactly as H-002: constants, state vars, public API (`clock`, `set_clock`, `record_hit`, `string_active`, `string_total`, `string_hits`, `string_crits`, `dps`, `readout_visible`, `readout_text`, `window_size`, `update_readout`, `refresh_readout`), the `Readout` Label3D made in `_ready`, hook in `receive_hit` (only when damage > 0, before the unchanged `return HIT`), and clock/refresh in `_physics_process`. Local-only, no RPC, no attacker filter. No `.tscn` change.
- **Files changed:** `game/combat/training_dummy.gd` only.
- **Checks run:** `--check-only` parse of the file fails only with "Identifier not found: CombatFx" (autoload, not available to a bare script check; this is the existing use of CombatFx too). No game or dummy_check run by me.
- **Known gaps:** not run in a real window; label look unseen. Area abilities and Surge Wave never hit the dummy (known limit, H-001a).
- **Required next action:** qa runs `dummy_check` and `combat_check`. For real `receive_hit` cases call `set_clock(t)` right before it, same frame.

---

### H-004: STU-003 QA verification: training dummy damage readout
- **From:** qa (kingdom-qa-playtest)  **To:** kingdom-creative-director (lead)
- **Task:** T4: write `tests/dummy_check.gd`, run it and `combat_check` myself.
- **Verdict:** **PASS.** Board row STU-003.T4 can be set to verified.
- **Commands (from the project folder, port 31499 free before each run, one at a time):** `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run.gd -- dummy_check`, then `-- combat_check`. No import was needed (no new `class_name`). `tests/run.gd` loads checks by name, so nothing outside `tests/dummy_check.gd` was edited.
- **Results:** `dummy_check`: 57 `ok` lines, final line `PASS: 0 problem(s)`, exit 0. `combat_check`: 52 `ok` lines, final line `PASS: 0 problem(s)`, exit 0.
- **Criteria (H-001, numbers match `dummy_check` case labels):** 1 hidden before hit, label 3.0 m up: pass. 2 (30 / 3 hits / 0 crits / DPS 30.0): pass. 3 (DPS 15.0 at t=2, white): pass. 4 (`DPS 25.0`, `String 25 (1 hit, 0 crits)`): pass. 5 (crit counting, `1 crit`): pass. 6 (0 and -5 damage ignored, a 0-damage hit does not extend the string): pass. 7 (rolling window, DPS 10.0, total 70): pass. 8 (active at 3.9, frozen gray `DPS 20.0` at 4.0, values kept): pass. 9 (`DPS 7.5`): pass. 10 (new string after end, `String 15 (1 hit, 0 crits)`, white again): pass. 11 (visible at 19.9, hidden at 20.0, new string shows again): pass. 12 (hidden when numbers are off, values still tracked, correct when turned back on): pass. 13 (two dummies independent): pass. 14 (`String 21`, `DPS 20.8` from the unrounded sum): pass. 15 (still returns HIT, still wobbles, label upright, clock advances, label refreshes on its own, `combat_check` passes): pass, except the floating damage number itself, which headless cannot observe (code path unchanged by the diff). 16 (200 hits over 100 s: window size 10, none older than 5.0 s; total 2000 and 200 hits kept): pass.
- **Test-side finding (not a game bug):** my first run failed 7 checks because `CombatFx.show_damage_numbers` came up false: the setting loads from the saved preferences (`prefs.gd:70`), and in this environment it is off. `dummy_check` now forces it on at the start and restores it at the end. Consequence for the owner: **if damage numbers are switched off in Settings, the readout is hidden too** (that is the spec, criterion 12), so the owner will not see it until the numbers are turned back on.
- **Scope check (`git status`):** this team's changes are only `game/combat/training_dummy.gd`, `tests/dummy_check.gd`, `tests/dummy_check.gd.uid` and the `AGENT_*.md` files. `training_dummy.tscn` is untouched. `game/ui/hud.gd` also shows as modified (boss bar moved to the top of the screen): that is not from this team's task, it is the other session's work, and I did not touch it. The other files in the status list (`hit_info.gd`, `player.gd`, ability files, etc.) were already modified before this task.
- **Not testable automatically:** how the label looks (size, outline, overlap with floating numbers at 3.0 m, readability at distance); the floating damage number itself; real co-op (local-only by design, no net check needed).
- **Suggested owner playtest (add to `TODO.md` 🧪):** open `combat_test`, make sure damage numbers are on, hit a practice dummy with a few weapons and abilities: the readout should appear above the dummy, show DPS and string total, turn gray about 3 s after the last hit, and disappear after 20 s. Check it is readable and does not hide the floating numbers. Area abilities and the Arcane Surge Wave are not counted (known limit, H-001a).
- **Files changed (mine):** `tests/dummy_check.gd` (+ `.uid`), this entry.
- **Required next action:** lead reports to the owner; sets the board rows.
- **Status claims:** I ran both checks myself and read their output. I read the `update_readout` / `readout_visible` code to diagnose the first failures. I did not run any other check.

### H-LEAD: STU-002 / STU-003 Agent Teams test: lead report
- **From:** kingdom-creative-director (team lead)  **To:** owner (via orchestrator)
- **Task:** Run the first real Agent Team (designer, architect, gameplay, qa) on STU-003, the training dummy damage readout, and report how the team coordinated.
- **Work completed:**
  - Creative verdict: GO. It's a sandbox-only tuning aid, not new content, and fits the "stabilise and tune" priority.
  - Designer wrote the spec (H-001, plus H-001a after the architect's notes). Architect reviewed it against the code and wrote the build plan (H-002, plus H-002a for qa's questions). Gameplay built it (H-003). QA wrote `tests/dummy_check.gd`, ran it and `combat_check` itself, and recorded the results (H-004).
  - The readout is two lines above the dummy, `DPS 42.5` and `String 312 (7 hits, 2 crits)`. DPS counts the last 5 s. A string ends after 3 s without a hit, then the label freezes grey with that string's average and hides after 20 s. It follows the damage-numbers setting.
  - Co-op: local only. Each player sees only their own hits. The architect confirmed this in the code: hits are worked out on the attacker's own machine, remote arrow copies can't hit anything, and the dummy has no network code.
- **How the team communicated:**
  - All four were spawned at once with the same plan: designer → architect → gameplay → qa.
  - **Direct messages between teammates** (not routed through the lead):
    - Architect sent designer technical limits before the spec was finished, and later sent designer a DPS-formula objection.
    - Designer replied to architect and kept its formula. Its reason: architect's version would read about 25% high on a steady string.
    - Architect sent qa a draft test API early, then the final API.
    - QA asked architect for missing hooks: a crit flag, visibility and colour readers, and a window-size reader. Architect answered in H-002a.
    - Designer reviewed QA's draft test and caught a wrong check ("DPS goes to 0 after the window"). The spec says the label freezes and shows the average.
    - Architect told gameplay "build plan ready", and gameplay told qa "ready".
  - **Reports to the lead:** every teammate reported progress and holds (gameplay and qa correctly waited for their inputs).
  - **Lead rulings:**
    - On the DPS formula: the designer's stands, because the designer owns numbers.
    - On designer's open questions: no "biggest hit" line, default font.
    - Told the team to re-read `AGENT_HANDOFFS.md` before appending, after two agents wrote to it at the same time.
  - **Parallel work:** QA drafted its test while design and build were still going on (no file overlap), so the test was ready when the build landed.
- **What passed (QA's own runs, H-004):**
  - `dummy_check`: 57 ok, "PASS: 0 problem(s)".
  - `combat_check`: 52 ok, "PASS: 0 problem(s)".
  - 15 of the 16 acceptance criteria are checked automatically. The 16th (the floating damage number still shows) can't be seen in a headless run; the dummy's wobble and HIT result are checked instead.
  - Lead checked with `git status`: this team changed only `game/combat/training_dummy.gd` (+141 lines), `tests/dummy_check.gd` (+ `.uid`) and `AGENT_*.md`. `game/ui/hud.gd` and `tests/net_surge_check.gd.uid` also changed during the session; those come from the other session, not this team.
- **What failed or didn't work:**
  1. **The shared task list was not available.** Neither the lead nor any teammate had TaskCreate, TaskUpdate or TaskList in this session, so T1-T4 were tracked in `AGENT_BOARD.md` plus messages. Every teammate asked the lead to "mark my task done", which added round-trips.
  2. **Message lag:** several idle notices crossed with newer messages (for example, architect still said "waiting for H-001" after designer had sent it). It caused no harm, but status was briefly stale.
  3. **Simultaneous appends:** two agents edited `AGENT_HANDOFFS.md` at the same moment once. The order was checked and is intact.
  4. **QA's first run failed 7 checks** because the saved preferences here have damage numbers turned off. The test now turns them on for the run and restores the setting afterwards (it doesn't save it).
- **Known limits (written into H-001a):** area abilities, the Arcane Surge Wave and bleed/poison/frost ticks never reach the dummy (they only search for enemies). Fixing that would mean touching enemy code, which is out of scope.
- **Files changed (whole team):** `game/combat/training_dummy.gd`, `tests/dummy_check.gd`, `tests/dummy_check.gd.uid`, `AGENT_HANDOFFS.md`, `AGENT_BOARD.md`.
- **Remaining work / for the owner:**
  - Playtest in `levels/sandbox/combat_test.tscn`: hit the dummy and check that the label is readable. Note that the frozen grey (0.75) is close to the live colour (0.95) and may be hard to tell apart.
  - If damage numbers are off in your settings, the readout is hidden too.
  - Small follow-ups outside this task's files, if you want them: `README.md` doesn't list `dummy_check` yet, and the IBM Plex Mono debug font from `DESIGN.md` 12.4 isn't in the project.
  - Decide whether to commit (nothing is committed or pushed).
  - Integration was not run as a separate step (the task was one game file).
- **Required next action:** owner reviews, playtests, and says whether to commit.
- **Status claims:** I checked `git status`, the function list in `training_dummy.gd`, and the damage-numbers handling in `dummy_check.gd` myself. The check results come from QA's report; I didn't re-run them. The co-op claim comes from the architect's code reading; nobody ran a co-op game.
