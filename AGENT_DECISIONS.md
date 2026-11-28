# AGENT DECISIONS

*Decisions that shape studio work. Game-design canon still lives in `DESIGN.md` and the area docs, and owner decisions from ChatGPT in `DESIGN_INBOX.md` (Filed). Log a decision here only when it was approved by the owner, or made inside an already-approved task's scope (say which). Proposals and ideas go in `AGENT_CONFLICTS.md` or a handoff, marked `proposal` or `idea, not decided yet`.*

Format:
```
### D-<number>: <title>
- **Date:** YYYY-MM-DD
- **Owner of the decision:** owner / Creative Director (within task <id>) / ...
- **Decision:** ...
- **Reasoning:** ...
- **Systems affected:** ...
- **Recorded in:** <project doc and section, if any>
```

---

### D-001: Set up a multi-agent studio for KINGDOM
- **Date:** 2026-11-27
- **Owner of the decision:** owner (brief pasted in chat)
- **Decision:** Ten Claude Code subagents (Creative Director, Game Designer, Technical Architect on Opus; Gameplay, Character & Animation, World & Level, UI/UX, Technical Artist, QA & Playtest, Integration & Build on Sonnet), coordinated through `AGENT_BOARD.md`, `AGENT_DECISIONS.md`, `AGENT_HANDOFFS.md`, `AGENT_CONFLICTS.md`, with rules in `AGENT_STUDIO.md`.
- **Reasoning:** One team with clear roles, file ownership and independent QA, so parallel sessions stop colliding and work gets checked before it reaches the owner.
- **Systems affected:** how work is done; no game systems.
- **Recorded in:** `AGENT_STUDIO.md`

### D-002: Autonomous development mode
- **Date:** 2026-11-27
- **Owner of the decision:** owner (brief pasted in chat, section 10)
- **Decision:** Once the owner assigns a task, the team carries it through to a tested result without asking at every step. It stops for: changes to established design or direction, progression or balance philosophy, removing features, major rewrites, deleting important assets/data, out-of-scope work, commits/pushes (unless authorised), spending money. Undecided design is proposed and marked `idea, not decided yet`.
- **Reasoning:** Owner wants minimal supervision with clear safety stops.
- **Systems affected:** all studio work.
- **Recorded in:** `AGENT_STUDIO.md` section 11

### D-003: Commits and pushes need the owner's say-so
- **Date:** 2026-11-27
- **Owner of the decision:** owner (brief: "Do not commit or push until the user reviews the setup"; section 10 approval list)
- **Decision:** Studio agents never commit or push on their own. `CLAUDE.md`'s "commit after changes" applies once the owner authorises commits for a piece of work. Integration prepares commit plans.
- **Reasoning:** Several sessions share this working tree; unreviewed commits would mix their work.
- **Systems affected:** git workflow.
- **Recorded in:** `AGENT_STUDIO.md` section 7
