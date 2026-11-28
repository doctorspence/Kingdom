# AGENT CONFLICTS and open questions

*Any agent adds an entry when recommendations clash, a technical or design disagreement comes up, or something needs the owner. The Creative Director rules on studio-level conflicts; anything touching established design, direction, balance philosophy, removals, big rewrites, scope or money goes to the owner.*

Format:
```
### C-<number>: <title>
- **Raised by:** <agent>, YYYY-MM-DD
- **Type:** design / technical / scope / file ownership / approval needed
- **The disagreement:** side A says ..., side B says ...
- **Options:** 1) ... 2) ...
- **Recommendation:** ...
- **Needs owner approval:** yes / no
- **Resolution:** (filled in later, with who decided and the date)
```

---

## Open

### C-001: Uncommitted changes from before the studio existed
- **Raised by:** orchestrator, 2026-11-27
- **Type:** file ownership / approval needed
- **The disagreement:** none yet. The working tree holds staged and unstaged changes no studio task owns (list in `AGENT_BOARD.md`), including an ability/Mana change in `ability_caster.gd`, `ability_data.gd`, `hit_info.gd`, `enemy.gd`, `player.gd` and the deletion of `arcane_bolt.gd`. Gameplay tasks on those files can't start safely until they are committed or set aside.
- **Options:** 1) The session that made them finishes and commits them. 2) The owner tells Integration to commit them as they are. 3) Leave them, and keep studio work away from those files.
- **Recommendation:** 1, then the studio starts from a clean tree.
- **Needs owner approval:** yes
- **Resolution:**

## Resolved
*(none yet)*
