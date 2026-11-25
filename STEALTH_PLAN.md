# Stealth plan: crouching, being noticed, and the sneak attack

*Written 2026-11-25 (Opus) at the owner's request, to be built by a later session (Sonnet). Stages 1-4 (crouch, awareness meter, sneak attack, HUD eye) are built (2026-11-25); stage 5 (tuning playtest) is not. The defaults below are the designer's picks. The owner can change any of them (see "Questions for the owner" at the end). Read `ENEMY_LIFE_PLAN.md` too: this plan builds its stage 5 ("suspicious step") early and answers its question 2.*

## The owner's brief
> Design a crouch/stealth mechanic that gives a damage bonus for an opener if they aren't aggro'd on you yet. Stealth should let you get closer before aggro.

## How it works today
- **Spotting is instant.** Every frame an idle enemy runs `_find_player()` (`enemy.gd`). If you are inside its sight cone (120°, 22 m, shorter at night) or its hearing range (6 m, 12 m if you sprint, attack or roll) with a clear line, it charges at once (`_aggro`). There is no "getting noticed" in between.
- **Nothing rewards a first hit** except that the enemy wasn't ready yet. The only damage bonuses are crits, ripostes, charged heavies and the perfect-dodge counter (`player.gd` `_land_hit`).
- **There is no crouch.** `Ctrl` is "walk" (1.5 m/s). The animation library has only two crouch moves: `Crouch_Idle` and `Crouch_Fwd` (already used for being downed).
- **Bug found while reading:** `is_sprinting` is not shared over the network, so the host's enemies never "hear" a friend sprinting. The stealth work fixes this in passing (see "Network").

## The idea in one paragraph
Press **Ctrl or C** (gamepad: **click the left stick**) to crouch. Crouched, you move slowly and quietly, and enemies have to be **much closer** to see or hear you. Enemies no longer spot you instantly: each one has an **awareness meter** toward you that fills while it can see or hear you and drains when it can't. Halfway, it becomes **suspicious** (stops, turns toward you, "?" over its head). Full, it **fights** ("!" and the charge, like today). Standing in plain view, the meter fills almost instantly, so normal play feels the same as now. The first blow you land on an enemy that isn't fighting you yet is a **sneak attack**: double damage, a guaranteed crit, and a hard hit to its balance.

## 1. Crouching (the player)
| Rule | Default |
|---|---|
| Key | **Ctrl or C** toggles crouch (owner's pick, 2026-11-25). `C` is only used inside the inventory today. Ctrl was "walk (hold)": walk keeps its action and its line in the controls settings, but has **no keyboard key by default** (the owner can bind one; on the gamepad, tilting the stick gently still walks). Gamepad crouch: **left stick click** (only used inside menus today). |
| Speed | **2.2 m/s** (walk is 1.5, run 5.8). With the gamepad stick tilted gently, a little slower. |
| Look | `Crouch_Idle` standing still, `Crouch_Fwd` moving. The body turns toward where you move (no side-step crouch animation exists). While locked on, you still face your target and slide in a crouch. |
| Stands you up | Sprinting (hold Shift / B: you stand and sprint, like leaving the crouch by running), rolling, jumping, blocking, drinking a flask, casting, climbing, getting hit, getting downed. After the swing of an attack you stay crouched only if the attack **didn't land** (a miss). |
| Can't crouch | While overloaded (too much weight), in water deeper than the knees, while downed. |
| Stamina | Crouching costs no stamina and stamina refills normally. |
| Attacks from a crouch | The normal light / heavy attacks. Light starts slightly faster (a lunge from low). No new animations needed. |

### How quiet and how hidden
Two numbers describe you each frame. Enemies read them:

| What you are doing | **Seen at** (× enemy sight range) | **Heard at** (× enemy hearing range) |
|---|---|---|
| Sprinting | 1.0 | 2.0 |
| Attacking, rolling, landing from a jump | 1.0 | 2.0 |
| Running | 1.0 | 1.0 |
| Walking (Ctrl) | 1.0 | 0.6 |
| Standing still | 1.0 | 0.3 |
| **Crouch, moving** | **0.45** | **0.35** |
| **Crouch, still** | **0.35** | **0** |

Gear can change these later (a `stealth` bonus stat on light armor, a "heavy armor is loud" penalty), but stage 1 uses only the table.

Example: a bandit sees 22 m in daylight. Crouched and moving, he sees you at about **10 m** inside his cone (at night, less again). His hearing of 6 m becomes about **2 m** while you creep. So you can walk up behind him to striking distance, but walking up to his face is still a fight.

## 2. The awareness meter (the enemy)
Each enemy keeps a meter from **0 to 1** for each player (per player so co-op partners are tracked apart). The host fills it.

**Filling.** Every frame, for each player not "out of the fight":
- **Sight:** if you are inside its cone and within its sight range × your "seen at" number, with a clear line of sight, the meter fills. The closer you are, the faster: at the edge of that range it takes about **2.5 s** to fill, at point blank **0.2 s**. (Rate = 1 / lerp(0.2, 2.5, distance ÷ that range).)
- **Hearing:** if you are within its hearing range × your "heard at" number (no cone needed, but walls still block it), the meter fills over about **0.6 s**, no matter how close (a noise is a noise).
- Sight and hearing add up.
- A standing player in plain view of the old 22 m cone fills the meter in **0.2-2.5 s** depending on distance. Up close that is as fast as today. Far off there is a short moment where they only turn to look first. This is a small change to how normal fights start, and it's intentional (see question 3).

**Draining.** Nothing seen or heard for 1.5 s: the meter drains at **0.2 per second**.

**The steps:**
| Meter | Step | What you see |
|---|---|---|
| 0 - 0.5 | **Unaware** | Doing what it was doing (standing guard, walking its patrol). |
| 0.5 - 1 | **Suspicious** | Stops. Turns toward where it last noticed you. A grey "?" over its head (`CombatFx.word`). After 1 s of being suspicious it walks slowly toward that spot. If the meter drains below 0.25 it shrugs and goes back to its post or patrol. |
| 1 | **Fighting** | A red "!" over its head, then exactly today's `_aggro` (callers blow the horn first, then the chase). |

**Always straight to fighting:** being hit (by anyone), being within **1.2 m** of a visible player, or a nearby friend calling for help (callers, as today). A suspicious enemy that is hit counts as unaware for the sneak attack (it still didn't know where you were).

**Left alone:** bosses (they wait for you to step into the arena, then fight at once), ambushers (`ambush_range`: they stay asleep until you are that close, then fight at once), and enemies walking home (`RETURN`: they already know about you and spot you the old instant way).

**Per-enemy keenness.** A new `perception` number on each enemy file (default 1.0) multiplies its fill rate: lookouts and hounds 1.5, sleepy or busy ones lower. The posts in `ENEMY_LIFE_PLAN.md` later multiply it too (sitting 0.6, working 0.7 hearing, watch 1.4 in the cone).

## 3. The sneak attack (the opener)
**When:** you land a blow on an enemy that is **unaware or suspicious** (not fighting anyone, not walking home). You don't have to be crouched: an arrow from the bushes counts, and so does a standing player who simply got behind an enemy unseen. Crouching is just the way to get there.

| Effect | Default |
|---|---|
| Damage | **× 2.0** (on top of everything else: weapon, heavy, charge, armor) |
| Crit | Always a crit (the big crit number, the crit hit-stop and camera shake). It does **not** also apply the weapon's crit multiplier: the sneak attack replaces it. |
| Balance | **× 2.0** balance damage, so a heavy sneak attack can throw a light enemy off balance at once, ready for a riposte. |
| Word | "Sneak attack" pops above it (`CombatFx.word`). |
| Weapons | A new `sneak_multiplier` on each weapon file, default **2.0**. Daggers (the future Rogue) get **3.0**, big two-handers **1.5**. Bows 2.0. |
| Bosses | No bonus (they are never unaware anyway). Named rares: bonus capped at **× 1.5**. |
| Afterwards | The enemy is now fighting you. Its friends notice through the noise of the blow (attacks are loud: × 2 hearing), so a guard right next to his friend joins in at once, one 10 m away turns to look first. Kill quietly from a distance or pick off the strays. |

Only one blow per enemy gets it: the first blow makes it fight, so the next is normal. A multi-hit swing (cleave, area) gets the bonus on every enemy it hits that was still unaware at that moment.

## 4. What the player sees (HUD)
- While crouched, a small **eye** above the stamina bar: **closed** (no one aware), **half open, grey** (someone is suspicious), **open, red** (someone is fighting you). It shows the highest meter of any enemy toward you, so you can feel the danger rise. Hidden when standing.
- "?" and "!" over enemy heads as above (everyone in the group sees them: they come from the enemy's state, which is already shared).
- A soft vignette at the screen edges while crouched (optional, cheap).

## 5. How it is built (for the implementing session)
Keep each stage small and playable. Line numbers are as of 2026-11-25 and will drift.

### Player (`game/player/player.gd`, `player_tuning.gd`, `game/core/input_setup.gd`)
- `input_setup.gd`: add `_add("crouch", [_key(KEY_CTRL), _key(KEY_C), _button(JOY_BUTTON_LEFT_STICK)])` and change `walk` to `_add("walk", [])`. In `prefs.gd`, add a `["crouch", "Crouch (toggle)"]` line next to walk and rename walk's label to "Walk (hold, unbound)" or similar; update the controls table in `DESIGN.md` section 4. Check menus don't eat it: `inv_compare` (C) and `inv_junk` (L3) are only read while the inventory is open, and crouch must be ignored while `Net.in_menu` or `Net.typing`.
- `player_tuning.gd`: add `crouch_speed := 2.2`, and the two tables above as exported numbers (`crouch_seen_mult := 0.45`, `crouch_still_seen_mult := 0.35`, `crouch_heard_mult := 0.35`, `walk_heard_mult := 0.6`, `still_heard_mult := 0.3`, `loud_heard_mult := 2.0`).
- `player.gd`: `var is_crouching := false`. Toggle in the MOVE state on `crouch` just-pressed. Every place that already sets `is_sprinting = false` on leaving MOVE (roll, jump, drink, cast, climb, stagger, downed, ...) is the list of places that also clear `is_crouching`. Also clear it when sprint starts, when blocking starts, and when hit. In the speed block of the MOVE state (~line 1505) add `elif is_crouching: speed = tuning.crouch_speed` before the walk check, and pick the crouch animations instead of `update_locomotion` (see `_state_downed` ~line 2260 for the same two animations in use).
- Add two functions for enemies: `seen_mult() -> float` and `heard_mult() -> float`, which return the table values from the current state (`is_crouching`, speed, `state == ATTACK/ROLL`, `is_sprinting`). On remote players (not authority) they read the shared `net_stealth` instead (below).

### Network
- Add `var net_stealth := 0` to `player.gd`, set by the owning player every frame: 0 = normal, 1 = walking or still, 2 = crouch moving, 3 = crouch still, 4 = loud (sprint, attack, roll). Add it to the player scene's `MultiplayerSynchronizer` (same `replication_mode = 2` as `net_state`). The host's enemies use it through `seen_mult()` / `heard_mult()`. This also fixes the remote-sprinting bug.
- Remote copies of a player play the crouch animations already, because animations are shared through `net_anim`.
- Enemy awareness lives only on the host. The new `SUSPICIOUS` state is shared through the existing `net_state`. **Add it at the end of the `State` enum** so the numbers of the old states don't change.

### Enemy (`game/enemies/enemy.gd`, `enemy_data.gd`)
- `enemy_data.gd`: `@export var perception := 1.0`.
- `enemy.gd`: `enum State { ..., GUARD, SUSPICIOUS }`. `var _awareness := {}` (peer id → 0..1), `var _last_noticed := Vector3.ZERO`, `var _quiet_time := 0.0`.
- Split `_find_player()` into a new `_sense(delta) -> Player` that updates the meters with the rules in section 2 and returns the player whose meter hit 1 (or null). Keep the boss, ambush and `is_out_of_fight` checks as they are. `RETURN` keeps calling the old instant check.
- `_state_idle`: call `_sense`. A meter crossing 0.5 → `_set_state(State.SUSPICIOUS)` + "?" word. A full meter → `_aggro(p)` + "!" word.
- New `_state_suspicious(delta)`: face `_last_noticed`; after 1 s walk to it at walk speed; full meter → `_aggro`; meter below 0.25 → `IDLE` (patrol picks up again by itself).
- `_apply_hit`: the existing "if state == IDLE then _aggro" (~line 489) must also cover `SUSPICIOUS`. Being hit should also set that attacker's meter to 1.
- New `func is_unaware() -> bool: return state in [State.IDLE, State.SUSPICIOUS] and not data.boss`. It reads `state`, which friends' copies also have from `net_state`, so it works for whoever is swinging.
- **Fitting with enemy posts** (`enemy_post.gd`, ENEMY_LIFE_PLAN stage 1, built by the posts session 2026-11-25). Its rules, from that session:
  - When the meter fills, call **`_notice(p)`**, not `_aggro(p)`. `_notice` handles the post's short "get ready" (`_alarm_time = EnemyPost.READY_TIME`, turn toward p, then `_aggro(p, false)`) and alerts calm friends within 10 m (`post.alert_friends(p)`). Enemies without a post, and callers, go straight to `_aggro`. `_aggro(p, spread := true)` clears `_alarm_time` and warns friends.
  - While getting ready the enemy is still `State.IDLE` with `_alarm_time >= 0`, handled by an early return at the top of `_state_idle` (`_get_ready`). **Keep that early return first**, and skip meter updates while `_alarm_time >= 0`.
  - The patrol branch of `_state_idle` (`post.patrol(delta)`) belongs to the posts session; call `_sense` after it, don't restructure it.
  - Sheathing: `_update_sheath()` sheathes only when `state == IDLE`, so a suspicious enemy **draws its weapon** (designer's pick: a clear warning to the player, keep it).
  - `is_unaware()` also returns true while `_alarm_time >= 0` (it hasn't drawn yet). `_alarm_time` is host-only, so on a friend's machine an enemy getting ready already counts as aware; that 0.35 s difference is fine.
- Any list of "fighting" states (`is_engaged`-style checks at ~line 333, `_write_net_state` ~line 743, the ring code ~line 982) must **not** include `SUSPICIOUS`. Any list of "calm" states (`[State.IDLE, State.RETURN]`, e.g. the caller's helpers ~line 825, the shield block ~line 433) **should** include it.

### Damage (`player.gd` `_land_hit`, ~line 1905)
- Before the crit roll: `var sneak := target.has_method("is_unaware") and target.call(&"is_unaware")`.
- If `sneak`: `hit.is_crit = true`; skip the weapon crit multiplier; `dmg *= weapon.sneak_multiplier` (capped at 1.5 when the target's `data.named` is true); `hit.poise_damage *= 2.0`; `CombatFx.word(..., "Sneak attack")`.
- **Owner decision (recorded in ENEMY_LIFE_PLAN.md, 2026-11-25): hits from behind always do extra damage, in or out of a fight.** That is a separate, smaller "flank" bonus that also lives here in `_land_hit`; the stage 3 session should read the exact rule in ENEMY_LIFE_PLAN.md, and the sneak attack and the from-behind bonus should not both stack in full (suggested: take the larger of the two).
- `weapon_data.gd`: `@export var sneak_multiplier := 2.0`. Set 3.0 on daggers, 1.5 on two-handers, in their `.tres` files.
- Player arrows (`game/items/arrow.gd`) and spell bolts (`arcane_bolt.gd`, `shield_throw.gd`) build their own hits: give them the same check (stage 3).

### HUD (`game/ui/hud.gd`, `hud.tscn`)
- The eye: a small `TextureRect` or drawn icon above the stamina bar, visible while `player.is_crouching`. It needs the highest awareness toward this player. On the host, read the meters directly. On a friend's machine, use a cheap approximation: red if any enemy targets you, grey if any enemy within 25 m is `SUSPICIOUS`, else closed. (Good enough, no extra network.)
- The debug info line (`hud.gd` ~line 490) should show "(crouching)" too.

### Checks (`tests/enemy_check.gd`, `tests/combat_check.gd`, `tests/movement_check.gd`)
- A crouched player 12 m behind-and-to-the-side of a bandit stays unnoticed for 5 s. A standing one at the same place is noticed.
- A crouched player walking straight at a bandit's face gets noticed before reaching 3 m. Behind him, reaches 1.5 m unnoticed.
- The meter goes suspicious, then back to idle when the player backs off and waits.
- A sneak attack does `sneak_multiplier` × the normal non-crit damage and always shows as a crit. The second hit is normal.
- Bosses and `ambush_range` enemies behave exactly as before.
- Hitting a suspicious enemy makes it fight at once.
- Crouch is cleared by roll, jump, sprint, block, getting hit.
- Two-player net check (`run_net_check.ps1`): the host's enemy notices a sprinting friend at the doubled hearing range (the fixed bug) and doesn't notice a crouching one.

## Stages
| # | Stage | What you'll see |
|---|---|---|
| 1 | **Crouch** (built 2026-11-25) | C / left stick crouches: slow, low, the crouch animations, stands up on roll/jump/sprint/block/hit. Shared with friends. No effect on enemies yet. |
| 2 | **Awareness meter + suspicious step** (built 2026-11-25) | Enemies turn and look ("?") before charging ("!"). Crouching lets you get much closer, especially from behind. The remote-sprint bug is fixed. |
| 3 | **Sneak attack** (built 2026-11-25) | Double damage, guaranteed crit, big balance hit on the first blow against an unaware enemy. Arrows and bolts too. |
| 4 | **HUD eye** (built 2026-11-25) | The eye shows how close you are to being found. |
| 5 | **Tuning playtest** (🧪) | The owner plays the Gullet entrance yard and a road patrol and we tune the numbers. |

## Questions for the owner
**Answered 2026-11-25:** crouch is a toggle on **Ctrl or C**; every other question goes with the default (no crouch needed for the sneak attack; standing players use the meter too; ×2 / ×3 / ×1.5; suspicious enemies give up and go back; armor left for later; start with stage 1).

1. **Crouch key:** C (keyboard) and left stick click (gamepad), toggle on/off. OK? Or hold-to-crouch?
2. **Must you be crouched for the sneak attack?** Default: no, any first blow on an unaware enemy counts (so archers can open from the bushes). Alternative: only from a crouch.
3. **Normal (standing) fights start a little differently:** a far-off enemy now turns to look for a moment before charging, instead of charging the instant you enter its cone. Up close it stays instant. OK, or should standing players keep today's instant spotting and only crouching use the meter?
4. **Size of the bonus:** × 2 for most weapons, × 3 daggers, × 1.5 two-handers. Too big, too small?
5. **Losing track of you:** a suspicious enemy that doesn't find you goes back to what it was doing. This is also `ENEMY_LIFE_PLAN.md` question 3. Yes?
6. **Should armor matter?** Later, heavy plate could make you louder and light armor quieter. Want it in this plan or leave it?
7. **Start with stage 1?**

## Built 2026-11-25: stages 2-4, and where the build differs from the plan
Code: `enemy.gd` (`_sense`, `_fill_rate`, `_state_suspicious`, `is_unaware`, `is_flanked_by`, `awareness_of`), `enemy_data.gd` (`perception`, 1.5 on lookouts and hounds), `player.gd` (`is_sneak_target`, `position_bonus`, used by `_land_hit` and by `AbilityCaster.strike` for Arcane Bolt and Shield Throw; arrows go through `_land_hit`), `weapon_data.gd` (`sneak_multiplier`: 3.0 on the three daggers, 1.5 on the three 2h swords and the greatsword, bows and staffs keep 2.0), numbers in `player_tuning.gd` "Stealth", the eye in `game/ui/stealth_eye.gd` (drawn in code, `preload`ed by `hud.gd`, no `class_name`). `CombatFx.word` takes an optional colour. Checks: `enemy_check` (meter, suspicious, give up, hit while suspicious, ambusher) and `combat_check` (sneak, flank, caps).
Deviations and choices:
- **From-behind bonus** (owner's rule in ENEMY_LIFE_PLAN.md, size was open): x1.5 when the attacker is more than 120 degrees off the enemy's facing, in or out of a fight, bosses included. With a sneak attack the larger of the two applies (no stacking).
- **Point blank** (1.2 m) only counts for a player **in front** of the enemy (inside the half-cone). Otherwise the lunge of a sneak attack from behind would set it off before the blow lands.
- Remote players are read through `seen_mult()` / `heard_mult()`; a friend standing still counts as "walking" (0.6) for hearing, as stage 1 already did.
- A standing, still player is now only heard within 0.3 x hearing range (about 2 m), as the plan's table says; the old 6 m "always heard" is gone for non-bosses.
- Bosses and ambushers keep the old instant `_find_player`; `RETURN` and `CHASE` re-targeting too. Raiders use the meter like everyone else.
- A suspicious enemy keeps `target = null` and stays in `SUSPICIOUS` while it gets ready after its meter fills (`_alarm_time`), so its weapon stays drawn. `EnemyPost.alert_friends` only warns `IDLE` friends, so `Enemy._wake_suspicious_friends` fills the meter of suspicious friends within 10 m.
- Giving up: back to `IDLE` (post/patrol resumes). A guard that wandered more than 2.5 m from its spot goes `RETURN` to walk home (instant spotting while it walks).
- Eye: it sits at the top-left above the bars (not squeezed between health and stamina). Openness follows the highest meter on the host (red when something fights you); a friend's game guesses from shared states within 25 m.
- The soft vignette (optional in the plan) is not built.
