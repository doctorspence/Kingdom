# Enemy life plan: what enemies do before the fight

*Written 2026-11-25 at the owner's request. Stages 1-4 and 6 are built (see "Progress" at the end).*

## Decided (owner, 2026-11-25)
1. **Weapons while calm: on the hip (shields on the back) and drawn when the fight starts** (option B below).
2. **Hits from behind always do extra damage**, in or out of a fight, not only on unaware enemies. This touches the player's damage code (`player.gd` `_land_hit`), so it is built together with the sneak attack in `STEALTH_PLAN.md` stage 3, not here. The size of the bonus is still open (suggestion: x1.5 from behind, and the sneak attack's x2 replaces it on an unaware enemy rather than stacking).
3. **Yes, enemies can lose track of you** and go back to their post. The suspicious step and the awareness meter are built by the stealth work (`STEALTH_PLAN.md` stage 2), so this plan's stage 5 is covered there. Posts only change how keen each enemy is (sitting, working, watching).
4. **Yes: Knights disciplined, bandits loose.**

## The owner's brief
> Enemies should be gathered around each other, or a task, or a watch, before pulling aggro, as opposed to standing in battle stance 24/7. They should also patrol, or be on "tasks", or stand with each other, or keep watch. Improve their animations in the rested and the fighting state.

## How it works today
- **Everyone is in battle stance all the time.** Every humanoid enemy file sets `idle_anim = Sword_Idle`, and an idle enemy just plays it (`enemy.gd` `_state_idle`).
- **Groups stand in a ring all facing the same way.** `SpawnDirector._spawn` puts a group evenly around the spawn point and gives every member the spawn point's rotation, so a bandit group looks like a drill formation.
- **Patrols walk without stopping.** They walk point to point at walking speed in the same battle stance, and never pause or look around.
- **Aggro is instant and solo.** The moment one enemy sees or hears you it charges (callers blow a horn first). Its friends standing right next to it only join if they see you themselves. `DESIGN.md` 8.1 lists a "suspicious (investigates a noise)" step that was never built.
- **Going home ends in battle stance again**, not in what it was doing before.

## What we already have to work with
The two animation files on the shared skeleton (`UAL1_Standard.glb`, `UAL2_Standard.glb`) already hold plenty of calm, everyday animations, so stages 1-5 need no new art:

| Use | Animations |
|---|---|
| Standing around | `Idle`, `ual2/Idle_FoldArms`, `Idle_Talking`, `ual2/Yes` (nod), `ual2/Idle_No` (shake head), `ual2/Idle_TalkingPhone` (hand gesture) |
| Sitting at a fire or on a log | `Sitting_Enter`, `Sitting_Idle`, `Sitting_Talking`, `Sitting_Exit` |
| Keeping watch | `ual2/Idle_Rail` (leaning on a rail or palisade), `ual2/Idle_Rail_Call` (shouting, already the caller's horn), `Idle_Torch` / `ual2/Idle_Lantern` (at night) |
| Tasks | `ual2/TreeChopping`, `Fixing_Kneeling`, `PickUp_Table`, `Interact`, `ual2/Walk_Carry`, `ual2/Consume` (drinking), `ual2/Chest_Open`, `ual2/Farm_Harvest`, `Crouch_Idle` |
| Lying down / waking up | `ual2/LayToIdle` (also played backwards to lie down) |
| Patrol walk | `Walk_Formal` (Knights), `Walk` (bandits) |
| Fighting | `Sword_Idle`, `ual2/Idle_Shield`, the sword attack sets, `Hit_Chest`, `ual2/Hit_Knockback` |

The camps already have props to gather around: the Hobb camp has log seats, crates, barrels, hay, a cart and a lookout; the Gullet and the Knight's checkpoint have their own.

## The idea in one paragraph
Every enemy group gets a **post**: what it is doing while nobody is around. While on its post it plays calm animations (weapon lowered, facing its friends or its job, not you). When it notices you it goes through a short **alert ladder** (notice, turn, warn the others, draw), and the **whole group** joins together. The fight looks like it does now, with a few more fighting animations. When the fight ends and they walk home, they go **back to their post**, not back into battle stance.

## 1. Posts (the calm state)
A spawn point gets a new setting, `post`, plus optional marker children for seats, work spots and look-out spots. Members of the group share the post:

| Post | What it looks like | Where |
|---|---|---|
| **Huddle** (the default) | 2-4 standing close in a loose circle, **facing each other**. Each one picks its own idle from the "standing around" set and changes it every 6-15 s; whoever is "talking" plays `Idle_Talking`, the others nod, fold arms or shift. Slightly different start times so nobody moves in sync. | Roads, the hamlet, woods groups |
| **Campfire** | Sitting on the log seats around a fire, `Sitting_Idle` / `Sitting_Talking`, one may stand drinking (`Consume`). | Hobb camp, raider camp, the Gullet's yard |
| **Watch** | Stands at a look-out marker facing outward (`Idle_Rail` on a palisade or a tower, else `Idle_FoldArms`), and slowly scans left and right. Torch or lantern at night. Sees **farther** in its cone but nothing behind it. | Hobb lookout, the checkpoint, Gullet gates |
| **Task** | Works at a job marker: chopping at a woodpile, kneeling at a cart, sorting crates, carrying a sack between two markers (`Walk_Carry`), harvesting in the farms. Hears less while working (noisy job). | Farms, tithe barn, mill, camps |
| **Patrol** | Walks the route at a relaxed pace, **stops at each corner** for 3-6 s to look around, then walks on. Pairs walk side by side (or one behind the other) instead of all on the same line. Knights use `Walk_Formal`. | Road patrol, tithe barn patrol |
| **Rest** (night only, later) | Lying down by the fire or in a tent; wakes with `LayToIdle`. Slowest to react. | Camps at night |

Mixing is allowed: a camp of 5 might be 3 at the fire, 1 at a task and 1 on watch. A spawn point that has no post set gets a **Huddle**, so every existing spawn point improves without being re-done.

### Weapons while calm
Calm enemies should not hold a raised sword. Two ways, the owner picks (question 1):
- **A. Sword held low** in the hand: no new art, just the calm animations (the sword hangs down by the leg). Shields go on the back.
- **B. Sword on the belt or back**, drawn when the fight starts: looks best, but the animation library has no "draw sword" move, so the draw would be faked (the hand goes to the hip with the arm tool used for the jump chop, the sword jumps to the hand halfway). Sitting and working enemies would always look like this.

## 2. The alert ladder (calm to fighting)
| Step | What happens | Time |
|---|---|---|
| **Unaware** | On its post. Senses depend on the post: sitting or resting sees less, watchers see farther in their cone, workers hear less. Night already shortens sight. | |
| **Suspicious** | Hears a noise (sprinting, fighting, an arrow hitting) or glimpses you at the edge of its sight: stops what it is doing, turns toward it, a short "Hm?" sound, may walk a few steps to look. If nothing more happens it goes back to its post after a few seconds. Sneaking past or picking off one at a time becomes possible. | 2-5 s |
| **Alert** | Sure it saw you: shouts (or the horn, for callers), and **its whole group** turns to fight, even those who didn't see you. | |
| **Getting up** | Each enemy needs a moment to be ready, depending on its post: standing 0.4 s (turn and raise the sword), working 0.8 s (drop the job), sitting 1.2 s (`Sitting_Exit`), lying 2 s (`LayToIdle`). The player gets an opening for a first strike on a sleepy camp, which rewards sneaking up. | 0.4-2 s |
| **Fighting** | The current fight (rings, taking turns, guard, balance, everything from the combat rhythm pass) is not changed. | |
| **Going home** | Lowers the weapon, walks home, heals, and **goes back to its post** (sits back down, picks the axe back up). | |

Getting hit always skips straight to fighting, whatever the step.

## 3. Better fighting animations
Small additions on top of the combat rhythm pass, no rule changes:
- **Waiting its turn** (not one of the 2 attackers): instead of a still stance, a mix of slow circling (already there), short taunts (`Idle_No`, a weapon-raise) and guard poses (`Idle_Shield` for shield users).
- **Hurt and tired**: below a third of its health it breathes harder (slower stance animation) and steps back more often.
- **Different stances per enemy type**: bandits a loose, low stance; Knights an upright shield stance; Harl and the Captain their own. Today all share `Sword_Idle`.
- **A group that loses its friends**: when most of a group is dead, the last one may hesitate (one step back, a look round) before fighting on. Martyr's fury (Zealots) stays as it is.

## How it is built (for later sessions)
- **`enemy.gd`**: the IDLE state splits into small parts: `UNAWARE` (doing its post), `SUSPICIOUS`, and a short `READYING` step before `CHASE`. RETURN ends in the post. The chase, attack and guard code is left alone. Because `enemy.gd` is already 1,500 lines (PRIORITIES P2 asks to split it), the post logic goes in its own file, `game/enemies/enemy_post.gd`, that the enemy asks "what should I be doing now?".
- **`spawn_point.gd`**: new settings `post` (huddle, campfire, watch, task, patrol, mixed) and how many of each; marker children named `Seat*`, `Work*` (with the job in the name or a setting), `Watch*`. `SpawnDirector._spawn` hands each member its spot and faces it the right way (toward the huddle center, the fire, the job or outward).
- **Group**: members of one spawn point share a group id; alerting one alerts the group (plus anyone within call range, as horns do today).
- **Network**: animations are already shared (`net_anim`), so friends see the calm poses with no extra network work. Posts are decided on the host only.
- **Performance**: far-off enemies already sleep (`enemy_sleep.gd`). A sleeping calm enemy freezes mid-pose, which looks fine for sitting or huddling; patrols keep walking only while someone is near, like now.
- **Hounds** use a different body (`quadruped_model.gd`) with their own animations: they get a simpler version (lying by the fire or sniffing near their handler, then the same alert ladder). Their animation list still needs checking.
- **Checks**: `tests/enemy_check.gd` gets new parts: a huddle faces inward, a sitting enemy takes longer to engage than a standing one, the whole group joins when one is hit, going home ends on the post. A picture script (`tests/visual_posts.gd`) takes shots of each post type.

## Stages
Each stage is playable on its own and ends with the checks and pictures.

| # | Stage | What you'll see |
|---|---|---|
| 1 | **Calm idle and huddles, group alert, going home to the post** | No more battle stance at rest: groups stand facing each other with varied calm animations; the whole group fights together; after a chase they go back to standing around. This alone covers most of the brief. |
| 2 | **Better patrols** | Patrols pause and look around at corners, walk in pairs, Knights march. |
| 3 | **Watch posts** | Look-outs on the Hobb lookout, the checkpoint and the Gullet gates, scanning outward, with longer sight in their cone. |
| 4 | **Campfire and tasks** | Sitting around the camp fires, chopping wood, working at carts and crates, carrying sacks; the "getting up" delay. Uses the existing camp props; adds marker children to those spawn points. |
| 5 | **Suspicious step** | Enemies investigate noises and glimpses before committing; sneaking becomes a real option. |
| 6 | **Fighting animation pass** | Taunts and guard poses while waiting, per-type stances, hurt behavior. |
| 7 | **Weapons on the belt / drawing** (if the owner picks B) and **night rest** | Sheathed weapons, a draw on alert; camps sleep at night with a lit watch. |

## Progress
| Stage | State |
|---|---|
| 1 | **Built 2026-11-25, not playtested by hand.** Details below. |
| 2 | **Built 2026-11-25, not playtested by hand.** Details below. |
| 3 | **Built 2026-11-25, not playtested by hand.** Details below. |
| 4 | **Built 2026-11-25, not playtested by hand.** Details below. |
| 6 | **Built 2026-11-25, not playtested by hand.** Details below. |
| 7 | Not started. |

**Stage 6 as built (fighting animations):**
- All the fight-look code is in one small helper, `game/enemies/enemy_fight.gd` (`EnemyFight`). `enemy.gd` only asks it what to do. Looks only: damage, timing and how many attack at once (still 2) are unchanged.
- **Stances:** bandits keep their low crouch (`Sword_Idle`). Knights (`calm_style = "disciplined"`) with a shield stand upright behind it (`ual2/Idle_Shield`). Out of a fight everyone goes back to the stance they started with. Bosses, archers and hounds keep their own look.
- **Waiting its turn:** an enemy that isn't one of the 2 attackers now circles in its stance with its feet stepping (it used to switch to a normal walk). Every 2.5-5 s it stops for a pose: bandits raise the sword overhead (`ual2/Idle_Rail_Call`), shake their head (`ual2/Idle_No`) or, with a shield, lift it (`ual2/Idle_Shield`). Knights never taunt: they stand their ground behind the shield for about 2 s. A free attack slot cuts any pose short.
- **Hurt (below a third of health):** bandits hunch over with the weapon low (`ual2/Zombie_Idle`). Knights keep the shield up. Both play their stance slower (0.7 speed, heavy breathing) and pause more often (every 1.4-3 s). 60% of those pauses are a step back instead of a pose.
- **Network:** decided on the host. Friends see it through the shared animation and its speed. Each machine works out the stance from the enemy's state, so the feet step there too.
- Not done: the "last one standing hesitates" idea, and separate stances for Harl and the Captain (no fitting animations; they keep `Sword_Idle`).
- Checks: `tests/fight_idle_check.gd`:
  - bandits taunt while waiting, with never more than 2 swinging;
  - hurt ones hunch, slow down and step back;
  - Knights hold their shields up, guard while waiting and never taunt;
  - stances reset after the fight;
  - bosses and archers are left out.
- Pictures: `tests/visual_fight.gd` (f01-f04).

**Stage 4 as built (seats and camp work):**
- About 0.3 s after appearing, a calm enemy (not a watcher, not on patrol) looks for camp props within 7 m that nobody has taken: log seats (`log_seat.tscn`, two places per log), crates, barrels and carts (`crate.tscn`, `barrel.tscn`, `cart.tscn`). Props are found by their scene file, so no scene changes were needed. A seat near a fire is picked 70% of the time when a job is also free.
- **Sitting:** on the log, facing the nearest fire within 7 m (`Sitting_Enter`, then `Sitting_Idle` / `Sitting_Talking`, one talker at a time). Sees 0.75 times as far. A small helper (`EnemyPost.SpotLock`) holds the body on the seat (the log's own collision would push it off) and lets go the moment the enemy leaves its post.
- **Working:** at the side of the prop facing the camp's fire: crates and barrels `PickUp_Table`, `Chest_Open`, `Interact` (barrels also a drink); kneeling at the middle of a cart's long side (`Fixing_Kneeling`, with a crouched breather now and then). Sees 0.85 times as far.
- **Getting up:** alerted while seated, it plays `Sitting_Exit` and charges about 1.35 s later (standing: 0.35 s); a worker needs 0.8 s. Friends add their own get-up time to their warning delay. With stealth's suspicious step, a sitter that grows suspicious stands up first (`_become_suspicious` calls `post.get_up()`, and `_state_suspicious` waits while `post.is_getting_up()`). A hit makes it fight at once.
- **After a fight:** home is just in front of its seat (or the job itself), so it walks back, then sits down again.
- Nobody is near at the start, so it is placed straight on its seat; otherwise it walks there.
- Not done: chopping wood and carrying sacks (no axe or sack to hold: a sheathed sword can't chop), night rest (stage 7).
- Checks: `tests/posts_check.gd` (2 sit and 1 works in a small camp, on the log facing the fire, sees less, stands up before fighting, its body is released, back on the seat after a fight). Pictures: `tests/visual_posts.gd` shots p11-p13. In the real zone at start: both Hobb camp bandits sit by the fire; about 7 sit and 1 works zone-wide (the spawn rolls vary).
| 5 | Moved to `STEALTH_PLAN.md` stage 2. |

**Stage 1 as built:**
- `game/enemies/enemy_post.gd` (EnemyPost, one per enemy): about 0.3 s after appearing (then every 2.5-4 s) it looks for idle friends within 5 m; a group turns to face its middle, and that becomes its home facing. Calm animations per `EnemyData.calm_style` ("loose" for bandits, "disciplined" for Zealots, "none" keeps the old stance): one talks at a time while the others listen, nod, fold their arms or drink (bandits), at slightly different speeds and start points. Patrols walk with `Walk` (bandits) or `Walk_Formal` (Knights).
- Not given a post: bosses, hounds (no human animations), ambushers (`ambush_range`), camp raiders (they march on the camp ready to fight).
- **Alert:** an enemy that spots you stands for 0.35 s turning toward you, then charges; calm friends within 10 m (with a clear line between them) turn and join 0.5-0.95 s after. Callers still blow the horn at once; friends warned by a caller don't blow their own. A hit on a calm enemy makes it fight at once. After a chase they walk home, sheathe, and face the group again.
- **Weapons:** `CharacterModel.sheathe()` moves the hand items onto the left hip (weapon, grip forward), the back (shield) or across the back (bow). Every machine sheathes when the enemy's state is IDLE and draws otherwise, so nothing new goes over the network. The draw is instant at the start of the charge: the library has no draw animation (a real one would go on `ART_NEEDS.md`).
- Hooks in `enemy.gd`: `_notice`, `raise_alarm`, `_get_ready`, `set_home_facing`, `_update_sheath`, and `_aggro(p, spread)`. The stealth work's awareness meter should call `_notice(p)` where it would call `_aggro(p)`, so posts and stealth stack.
- `SpawnDirector` now places a non-patrol group 1.3-2 m apart (was the spawn point's radius, usually 3 m), a little untidy.
- Checks: `enemy_check` (huddle facing, sheathed, notice delay, group joins, drawn, back to post, hit while calm, hounds). Pictures: `tests/visual_posts.gd` (run without `--headless`).
**Stage 2 as built (patrols):**
- A spawn point with a patrol route and more than one enemy gives them a shared `patrol_group` and a `patrol_side` (1.4 m apart, + = right of travel). They start abreast at the first point, facing down the road, and walk the route side by side (each walks its own offset copy of the route).
- At every corner the group stops for 3-6 s (the same pause for everyone, from the group name and corner count) and looks around: ahead, 65 degrees left, 65 degrees right, ahead. Nobody leaves until the others have arrived (at most 12 s of waiting), and when one leaves, the rest go too. Someone who got ahead slows down until the others catch up.
- An enemy that fought and walked home rejoins its patrol at the corner its friends are walking to.
- Lone patrollers (one enemy, or hand-placed routes) pause and look around the same way. Raiders don't (no post).
- Code: `EnemyPost.patrol()` and friends; `enemy.gd` only hands the patrol over when the enemy has a post. Checks in `enemy_check` (abreast, both stop, look around, still sheathed, set off together).
**Stage 3 as built (watch posts):**
- A spawn point's new `post` setting: "auto" (as before) or "watch". Watchers stand in a line across the way the point faces (its -Z), 1.6 m apart, face that way, and slowly scan 45 degrees to each side, holding each look 2.5-4.5 s. They see 1.35 times farther (22 m becomes about 30 m, through `Enemy.sight_scale`); the sight cone and hearing are unchanged. `watch_rail = true` makes them lean on a rail in front of them (`Idle_Rail`) and only glance around.
- Any **lookout** (an enemy id with "lookout" in it, the Gullet's B08) keeps watch on its own and turns its back on its camp (away from the friends within 15 m), so no scene changes were needed for it.
- Watchers don't join huddles. Calm animations: standing or arms folded (bandits now and then drink). Night torches are not done (no torch prop yet).
- **The Knights' checkpoint** (`Checkpoint` in `tithelands.tscn`) is now a watch post facing south down the road, toward where players come from.
- The first look round (finding friends, or the watch direction) now runs on a timer 0.3 s after an enemy appears, even if it is already asleep (`EnemySleep`). Before, a far-off enemy turned to its group only when it woke up, right as the player arrived.
- Checks in `enemy_check`: faces its watch direction, sheathed, scans, sees farther than an ordinary bandit, a lookout faces away from its camp. In the real zone at start: 20 enemies in huddles, 7 on patrol, 3 on watch, 15 standing alone, 11 without a post (hounds, bosses, ambushers).
- Known: the archer's placeholder bow is a full ring (the placeholder mesh, same in hand), so it looks odd on the back until a real bow model exists.

## Questions for the owner (answered above, kept for the record)
1. **Weapons while calm:** A (sword held low, quick) or B (sword on the belt or back and drawn when the fight starts, slower to build and the draw is faked)?
2. **Sneaking:** is it OK that sitting, working or sleeping enemies take a moment to get up, so a careful player gets a free first hit? Should hitting an unaware enemy from behind do extra damage (a backstab), or just the free hit?
3. **The suspicious step (stage 5):** do you want enemies that can lose track of you and go back to their post, or should seeing you always mean a fight?
4. **Knights vs bandits:** should Knights (Zealots) behave more disciplined (formal posts, marching patrols, upright stance) and bandits looser (drinking, sitting, slouching)? That is what this plan assumes.
5. **Start with stage 1?**
