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

### 2026-11-25: Bandits in an Old School RuneScape-inspired style
- **Area:** art direction / characters
- **Decision:** Bandits use chunky low-poly shapes, low-resolution hand-painted textures and strong equipment silhouettes, as an original design (no assets, names or designs copied). Weapon variants: sword, mace, dagger, crossbow.
- **Details:** Built 2026-11-25 (see `HANDOFF.md`, "Bandit characters"). Reference sheet: `docs/bandit/reference_bandit_sheet.webp`; the hooded dagger and crossbow sheets were pasted into chat and are not saved as files. Muted earth palette: dirty olive, dark brown, weathered leather, muted grey, dull iron.
- **Status:** decided for the bandits; **open question for the owner:** `DESIGN.md` 12.1 says "detailed, not low-poly". Is this style only for bandits, or the new direction for characters?
- **Replaces:** nothing yet.

### 2026-11-23: KINGDOM inventory and character panel UI standard
- **Area:** UI / loot
- **Decision:** Adopt the approved Champions of Norrath-inspired combined character and spatial inventory screen, with Oblivion-inspired top navigation. The clarified equipment layout is authoritative for the UI: one ring slot, no belt slot, and one Utility slot that also equips the cloak. Keep the existing two weapon sets and their swap behavior; the character panel shows the currently active main-hand and off-hand slots.
- **Details:** Keep the player character visible beside the backpack at all times. Left: spatial backpack grid with real item footprints, stack counts, rarity borders, weight/capacity, sorting, drag-and-drop, and rotation where appropriate. Center: 3D character on a pedestal with equipment slots around the paperdoll. Right: level/XP, attributes, combat stats, health, mana, stamina. Equipment slots: Head, Shoulders (directly beneath Head), Chest, Hands, Legs, Feet, Neck, Ring (exactly one), Utility (cloak uses this slot), active Main Hand, active Off Hand (weapon or shield). There is no Belt slot. Existing two weapon sets remain a gameplay feature; provide a way to inspect/swap the active set without adding four permanent paperdoll slots. Top tabs, in order: Character, Inventory, Map, Talents, Quests, System. Remove Magic and Help. Preserve the dark, ornate, aged-gold medieval fantasy look and controller navigation. Item footprints must be data-driven and prevent overlap/out-of-bounds placement; item selection supports inspect, compare, equip, drop and mark-junk actions.
- **Status:** decided
- **Replaces:** The previous UI mockup slot arrangement (including belt and separate ring/utility assumptions); clarifies DESIGN.md 9.2 for the displayed equipment slots. Does not remove the existing two-weapon-set gameplay system.

## Filed

### 2026-11-25: Zone 1 and the Gullet go dark and dreary
- **Area:** art direction / zone 1 / Gullet
- **Decision:** Bring back the darkest, dreariest look. Daytime open countryside should match the forest's mood, not bright or green; fog consistent and atmospheric, not a flat brown-grey filter. Nights darker, with only nearby things seen by lantern, but still enough to navigate and fight. Firelight lights nearby objects and characters naturally. The dungeon much darker, lit by lanterns and small holes in the cave ceiling.
- **Details:** The owner's feedback list had an empty point 2.
- **Status:** decided (owner, in chat).
- **Replaces:** the Greenwood stage 8 light values and the Gullet's room fill lights.
- **Filed (2026-11-25):** built; HANDOFF.md, DESIGN.md 11.4 and 12.1, GREENWOOD_OVERHAUL.md, GULLET_DESIGN.md.

### 2026-11-25: White Knight character sheet
- **Area:** art direction / factions
- **Decision:** The White Knight looks like the owner's character sheet: flat-topped great helm with a cross-shaped slit, breaths and brass trim; mail coif, hauberk and chausses; an ivory tabard to mid-shin with the red cross pattee front and back, red under-panels in its splits and a ragged hem; a hood bunched round the neck; steel pauldrons with a red cross, vambraces with elbow cops, plated gauntlets; a wide belt with a square buckle, a slung sword belt and a pouch; brown knee-high boots. Build it from the sheet, not from the existing armour.
- **Details:** `docs/white_knight/white_knight_sheet.webp` and `white_knight_details.png` (pasted by the owner in chat). Palette as in the sheet (ivory, dark red, steel, tarnished brass, brown leather).
- **Status:** decided (owner, in chat).
- **Filed (2026-11-25):** built as `assets/characters/white_knight/` (HANDOFF, ART_NEEDS, PRIORITIES P4). The owner then asked for it on the White Knight Zealot: done, every Zealot wears it.

### 2026-11-25: The outpost's White Knights are hostile, but can be won over
- **Area:** factions / zone 1 / quests
- **Decision:** The White Knights at the outpost start hostile. A quest or storyline can make them friendly and give the player access to the outpost.
- **Details:** Needs a quest system (not built yet; PRIORITIES P4) and a saved "truce" flag. Until then the outpost is simply hostile. Open: does the truce belong to one character or to the whole world; what access gives (the inn, smith and market as vendors, resting, passage toward the castle); can it be lost; does it change Knights elsewhere?
- **Status:** decided (the owner, in chat, 2026-11-25).
- **Replaces:** nothing. It refines SPEC.md's "both factions are enemies of the players" for this outpost (SPEC.md itself is not edited).
- **Filed (2026-11-25):** OUTPOST_PLAN.md sections 2 and 7; DESIGN.md section 2; PRIORITIES.md P4 (quest system).

### 2026-11-25: White Knights Outpost (north end of the Tithelands, in front of Highcrown's moat)
- **Area:** zone 1 / art direction / factions
- **Decision:** A small permanent medieval settlement just outside Highcrown's gate (inn, civilian blacksmith, stables and farrier, market, carpenter, cottages, well), with a White Knights checkpoint at the drawbridge. It replaces the Knights' checkpoint (banner poles, tents, stalls) in Knight's Gap. Built as a reusable library of 228 modular assets with a manifest. Hand-painted look; 12th-13th century England. The castle itself is not part of this job.
- **Details:** White Knights palette ivory `#E5E0CE`, dark red `#A52F35`, tarnished gold `#C3A45B`, charcoal iron `#292B30`. Emblem (owner, 2026-11-25): white field with a red Templar cross (cross pattee), the same on everything; the gold lion in the in-game concept picture is not used. Size targets: road and drawbridge 12 m, checkpoint 14 m, market about 28 x 24 m, outpost about 160 x 120 m. Brief word for word: `docs/outpost/OUTPOST_BRIEF.md` (the paste stops partway through section 9).
- **Status:** decided (pasted by the owner into Claude Code, 2026-11-25; location and emblem confirmed in chat the same day).
- **Replaces:** the gold cross on the White Knight banners; DESIGN.md 12.1's "off-white and tarnished gold" line for the Knights.
- **Filed (2026-11-25):** `OUTPOST_PLAN.md` (decisions, what exists, layout proposal, stages, asset rules, open questions); `assets/outpost/MANIFEST.md` (all 228 assets); DESIGN.md 12.1 (palette, emblem, hand-painted outpost); ZONES_DESIGN.md section 3; ART_NEEDS.md; PRIORITIES.md P4; TODO.md. Stage 1 (the White Knights set, WK01-WK12) is built. Still open, in OUTPOST_PLAN.md section 7: scale, who lives there, moving the castle closer, GLBs, hand-painted everywhere, the rest of the brief.

### 2026-11-23: Female base player character, the Outcast
- **Area:** art direction / classes
- **Decision:** The female base player is the same Outcast as the male: same art standard, scale, UAL1 skeleton, modular clothes and hand-painted texture quality. An adult woman from the medieval English countryside, a playable adventurer, not a noblewoman, faction NPC or armored warrior. **No armor.**
- **Details:**
  - Body and face: slim, naturally athletic, feminine proportions with a naturally fuller bust worked realistically into the clothes; attractive but believable face, natural complexion, light freckles, no makeup; auburn or dark-brown hair in loose braids or tied back; confident expression. A real medieval traveler, not a fantasy princess or pin-up.
  - Upper body: fitted but practical cream linen blouse, rolled sleeves, worn fabric. **Neckline: low and open, laced, as on her concept sheet** (owner, 2026-11-23; this replaces the brief's "without excessive exposure").
  - Cloak: dark olive-green wool, attached hood, simple bronze or iron clasp, weathered edges.
  - Lower body: dark-brown wool trousers (or practical medieval divided garment), leather belt, small pouches, faded red cloth.
  - Feet: simple brown leather boots with cloth leg wraps.
  - Kit: small leather satchel, utility knife, rope or travel supplies, simple wrist wraps.
  - Avoid: chainmail, breastplate, metal shoulders, armored gloves; Viking/Norse, Renaissance, pirate, modern fantasy, anime, photoreal, pixel art.
  - Sheet: front, back, T-pose (arms level, palms down, legs straight, symmetrical), three-quarter, face close-up, clothing close-ups, modular clothing breakdown.
- **Status:** decided (pasted by the owner into Claude Code chat)
- **Replaces:** nothing. Matches the male Outcast entry below and the owner's answers there (base look under gear, hand-painted characters).
- **Filed:** `DESIGN.md` 12.1 ("The base Outcast look"); `ART_NEEDS.md` "Player body" row. Concept sheet: `docs/concept/outcast_female_sheet.jpg`.

### 2026-11-23: Base player character, "the English Outcast"
- **Area:** art direction / classes
- **Decision:** The base playable human is an Outcast: an ordinary 12th–13th century English countryside wanderer or displaced villager, not a knight, soldier or faction member. He wears **no armor at all**, only worn, handmade civilian clothes. Look: chunky hand-painted MMORPG style (Warhammer Online, classic-era World of Warcraft as style references only), not photoreal, not pixel art.
- **Details:**
  - Body: adult male, athletic but ordinary, slightly chunky MMORPG proportions, messy medium dark-brown hair, short beard, weathered but approachable face. No superhero muscles.
  - Upper body: loose off-white linen shirt, oversized sleeves rolled up, short laced neckline, dirty and stained.
  - Cloak: dark olive / forest-green wool with attached hood, simple iron or bronze clasp, torn weathered hem.
  - Lower body: loose dark-brown or charcoal wool trousers, plain leather belt, small pouches, optional faded red cloth hanging from the belt.
  - Feet: worn brown leather boots, cloth or leather leg wraps, mud.
  - Kit: small leather satchel, rope, utility knife, pouches, optional bedroll. A plain, worn iron/steel sword at the waist.
  - Avoid: chainmail, plate, metal shoulders, armored gloves or boots, uniforms; Viking/Norse, Renaissance, pirate and modern-fantasy styling.
  - Production sheet: front, side, back, three-quarter, face close-up, material close-ups, separate clothing pieces, belt and accessory breakdown; dark neutral background.
  - Tech: existing UAL1 skeleton (don't change it), modular clothing, Godot 4.7.2, ~30–60k triangles equipped, animation-friendly, hand-painted textures.
  - Reference: the owner's concept sheet "Player Character: Outcast (Level 1)" (front, back, T-pose, head, cloak/shirt/belt/boot details, palette: olive, leather brown, rust red, dark brown, gray).
- **Status:** decided (pasted by the owner into Claude Code chat)
- **Replaces:** nothing directly. Touches `DESIGN.md` 12.1 (PBR materials; levels 1–10 armor) and the "Player body" row in `ART_NEEDS.md`.
- **Owner's answers (2026-11-23):** hand-painted textures for characters first; once one stands in Zone 1, decide whether the world follows (scanned world textures stay for now). This outfit is the **base under gear** (empty slots); starting armor is unchanged. A **female** version is wanted too: the owner already has a matching sheet (same clothes, long braid).
- **Filed:** `DESIGN.md` 12.1 ("The base Outcast look", "Characters are hand-painted"); `ART_NEEDS.md` "Player body" row; male sheet saved as `docs/concept/outcast_male_sheet.webp`.

### 2026-11-23: Movement redesign (grounded, "Gloria Victis" weight), hybrid
- **Area:** combat / movement
- **Decision:** Hybrid. Exploring stays camera-relative (push a direction and you turn and go that way). In **combat stance** (locked on, or guard raised) your body faces the foe (or the camera's direction when guarding with no target) and WASD moves relative to the body: real sidesteps and a slower backpedal. Getting going, stopping and turning all take noticeably longer than before.
- **Details:** walk 1.5 (first 2.0; owner chose the realistic pace once the feet were matched to the animation), run 5.8, sprint 8.0 m/s. In combat stance backward is 0.7× and sideways became a slow side-step, 1.1 then 1.3 m/s in fighting stance (owner, same day: "side step slowly while strafing") (locked on 5.0 → back 3.5). Full run in ~0.35 s, stop in ~0.3 s, direction changes and body turns at about a third of the old rate. Backpedalling plays the walk/jog in reverse until proper backward and sidestep animations exist (`ART_NEEDS.md`).
- **Status:** decided (owner pasted a brief into Claude Code chat; it was cut off after "Exploration movement". The owner picked the hybrid with tuned speeds over the brief's fully character-relative controls and 5.0 run)
- **Replaces:** `DESIGN.md` 5.2 speeds (walk 2.6, run 6.8, sprint 9.6) and the near-instant acceleration.
- **Filed:** `DESIGN.md` 5.2; `game/player/player_tuning.gd`, `player.gd`; `ART_NEEDS.md` directional locomotion row.

### 2026-11-23: Inventory and character equipment screen
- **Area:** UI
- **Decision:** One combined screen, laid out like the owner's reference image: spatial backpack grid on the left, the player's 3D character on a pedestal in the middle with equipment slots around it, level, attributes, combat stats and resources on the right. A horizontal tab bar on top (Character, Inventory, Map, Talents, Quests, System) with a gold underline and glow on the current tab; L1/R1 cycle tabs.
- **Details:**
  - Left slots, top to bottom: Helmet, Shoulders (directly under the helmet), Chest, Gloves, Belt, Legs, Boots. Right slots: Necklace, Ring (one slot only), Main hand, Off hand (shields, secondary weapons, other off-hand gear), Utility / accessory. Every slot shows the equipped item's icon.
  - Backpack: items take their real size (potion 1×1, ring 1×1, dagger 1×2, sword 1×4, shield 2×2, helmet 2×2, chest 2×3, boots 2×2), no overlap, nothing outside the grid, rotation where it makes sense, drag and drop, stack counts, weight / carrying capacity, rarity border colors, auto-sort, category filter tabs (L2/R2).
  - Item details: name, rarity, damage or defense, attack speed, weight, value, special bonuses, required level; actions Equip, Compare, Drop, Mark Junk.
  - Right panel: level and XP bar, Strength, Intelligence, Willpower, Agility, Endurance, Personality, Luck, Attack, Defense, Spell Power, Spell Resistance, Health, Mana, Stamina.
  - Look: dark medieval, ornate aged-gold frames, stone and weathered metal, warm torchlight, ivory serif text, subtle gold highlights, detailed readable icons. "A premium early-2000s fantasy RPG, remastered."
  - Tech: functional grid, data-driven item sizes, slot validation, equipping updates the character's look and stats, resolution-independent, mouse/keyboard and controller, data kept separate from the UI.
- **Status:** decided (pasted by the owner into Claude Code chat)
- **Replaces:** the old plain inventory panel (`game/ui/inventory_panel.gd`, removed). Clashes, settled with the owner 2026-11-23: gear slots in `DESIGN.md` 9.2 (cloak, 2 rings, 2 weapon sets, no belt), stats in `DESIGN.md` 7 (Strength, Agility, Intellect, Vitality, Armor; class resources instead of mana), sword size 1×3 in `DESIGN.md` 9.3, and "crafting materials" (SPEC: no crafting or gathering).
- **Owner's answers (2026-11-23):** show the game's real stats (Strength, Agility, Intellect, Vitality; Attack, Defense, Ability Power, Critical; Health, Stamina, class resource) in the reference layout, no new attributes or mana. Cloaks go in the Utility slot; **no belt slot for now**. Keep both weapon sets (the slots show the active set, with a switch). Keep item sizes (one-handed swords 1×3); no crafting materials.
- **Filed:** built (`game/ui/character_screen.gd`, `ui_style.gd`, `character_preview.gd`); `DESIGN.md` 9.2, 9.3, 12.3; `TODO.md` "Inventory and character screen"; `ART_NEEDS.md` Phase 6 rows.
