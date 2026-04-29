# Phase 9 Progress: Storytelling & World Structure

## Effect

Narrators tell stories. Portals lead to dimensions. The world has depth.

## Status: Planning

## Goal

Add narrative and structural depth to the world. Wandering narrators read
literature and share rumors. Portals become gateways to shared dimensions.
Dungeons have meaningful room structures. Language barriers create social
puzzles.

---

## Issues

Ordered by narrative arc: world-structure substrate → creature
selection layered on top → narrative agents who tell stories → social
systems → cross-cutting infrastructure.

### World structure substrate
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 902 | dungeon-room-spawn-zones | Open | Room detection in dungeons. Blocks 903. |
| 905 | portal-dimension-system | Open | BG portals → shared worlds. World-level structure. |

### Creature selection (depends on 902)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 903 | contextual-creature-spawns | Open | Theme-appropriate monsters per zone. Blocks 903b, 904. |
| 903b | regional-creature-spawn-themes | Open | Continental themes (Eastern/Kalimdor/Outland). (was 212) |
| 903b1 | outland-demon-felorc-spawns | Open | Detail spec for 903b. (was 212) |
| 904 | embedding-based-creature-selection | Open | Semantic similarity for thematic consistency. Depends on 903. |

### Narrative agents (the storytellers)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 909 | gutenberg-text-library | Open | Public domain literature. Blocks 910. |
| 910 | wandering-narrator-system | Open | Core storytelling NPCs. Depends on 909, Phase 5 traveler pattern. |
| 908 | narrator-audience-facing | Open | Sit with seated audience. Social-mirroring extension of 504. |
| 911 | shepherd-flock-system | Open | Immortality-lore NPCs (shepherds with critter flocks). |
| 912 | automated-lore-generation | Open | LLM-generated stories. Depends on 915 Ollama integration. |
| 914 | custom-chat-data-sources | Open | Where narrators draw their content. Blocks 910 enrichment. (was 330) |
| 915 | ollama-conversation-flow | Open (Experimental) | LLM conversation flow for 912. (was 331) |

### Social systems
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 907 | language-barrier-system | Open | Racial languages only. Creates social puzzles. |
| 901 | rebellious-attitudes-freedom-of-affairs | Open | Placeholder concept. |

### Polish
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 906 | randomized-login-screen-freddi-fish | Open | Visual polish. Standalone. |

### Infrastructure
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 913 | clustered-worldserver | Open | Horizontal scaling. Spans phases. |

## Completed: 0/17 (1 Experimental)

---

## Completion Criteria

### World Structure
- [ ] Dungeons have room detection and contextual spawns
- [ ] Embedding-based creature selection for thematic consistency
- [ ] Battleground portals become shared dimension gates
- [ ] Faction rules for portal access (Horde/Alliance/Neutral)
- [ ] Dynamic aperture randomization when areas empty

### Narrative Systems
- [ ] Narrators wander reading from Gutenberg library
- [ ] Narrators stop and sit when players sit nearby
- [ ] Rumors propagate through narrator network (telephone game)
- [ ] Shepherds wander with critter flocks
- [ ] Automated lore generation via Ollama

### Social Systems
- [ ] Language barriers require learned languages
- [ ] Language tomes craftable via inscription
- [ ] Cross-faction communication through shared languages

---

## Key Files

- `src/lua/travel.lua` - Narrator base movement (reuse travelers)
- `docs/rmail-integration.md` - rmail setup instructions
- `docs/patches/` - C++ modifications for hooks

---

## Dependencies

- Phase 1 (foundation) - ALE, AIO must work
- Phase 5 (travelers) - Narrators reuse traveler patterns
- Phase 6 (bots) - Narrators may be playerbots
- Phase 8 (progression) - Shepherds explain immortality

---

## Narrator System (310)

### Core Identity

Wandering narrators are playerbots that:
- Wander like travelers (walking speed)
- Stop when player/bot sits within 5 yards
- Read sentences from Gutenberg library
- Share and propagate rumors via PM

### Movement Patterns

| Pattern | Description |
|---------|-------------|
| Orbit | Circle seated players at 5 yards |
| Midpoint | Walk between two seated players |
| Point-to-Point | 2 steps, stop, spin, ponder, continue |
| S-Curve | Lazy sine wave at walking pace |
| Sleep | Spawn campfire, sleep 30 min, forget rumors |

### Rumor Mechanics

1. Player PMs narrator with information
2. Narrator extracts keywords, stores rumor
3. Later, different player speaks in /say nearby
4. If 20%+ keyword match → narrator shares rumor
5. Rumor told once, then forgotten
6. Creates telephone game across world

### rmail Integration

Subscribers receive narrator speech via rmail:
- Must be within 20-30 yards to "hear"
- Speech forwarded to rmail inbox
- Optional TTS audio generation
- Service address: `wow.ritzmenardi.com/narrator`

---

## Shepherd System (311)

### Blocked By: 312 (Automated Lore Generation)

Immortal shepherds wander with critter flocks:
- Big creatures (giraffes, kodo), invulnerable
- Flock avoids monsters, parts around players
- Critters walk normally, burst speed if player too close

### True Names

Each shepherd has a curated name/story:
- Names rotate periodically
- Stories generated via issue 312

### Lore Trigger

Player says 20% of story keywords in /say:
- Shepherd recognizes the match
- Reveals they're the only one who should know
- Explains immortality mechanics
- Vanishes in smoke → tradeskill nodes

### Tradeskill Nodes

Shepherd + flock transform to gathering nodes:
- Node level matches player's invisible level
- ONLY source for level 20+ materials
- Creates economy around shepherd discovery

### Permanent Transformation

Immortal player kneels before shepherd:
- Confirms "are you sure?"
- Player becomes critter forever
- No input, chat is gibberish
- Hidden from /who, unselectable
- True ending for those who want peace

---

## Portal Dimension System (129)

### Battleground Portals → Shared Gates

```
CURRENT:  Portal → Queue → Instance → Isolated BG
INTENDED: Portal → Teleport → Shared World → Open PvP/RP
```

- BG maps become persistent shared zones
- No instancing - everyone sees everyone
- Horde and Alliance occupy same space

### Faction Rules

| Portal Type | Access |
|-------------|--------|
| Horde | Horde only |
| Alliance | Alliance only |
| Neutral | Either faction |

Neutral portals lead to secret dimensions (GM Island, etc.).

### Dynamic Aperture

When portal area empties:
1. Timer starts (5 minutes)
2. On expiry: randomize destination
3. Next player gets new destination
4. Creates exploration mystery

---

## Language Barrier System (302)

### Current: Everyone speaks Common/Orcish

### Intended:
- Remove Common/Orcish as defaults
- Each race knows only racial language
- Inscription creates language tomes
- Tome fragility: vendor/mail destroys them
- Cross-faction via shared learned languages

Creates social puzzles:
- Find someone who speaks your language
- Learn languages to expand communication
- Narrators can translate (know all languages)

---

## Dungeon Room System (126, 127, 128)

### Room Detection (126)

Dungeons divided into logical rooms:
- Intersection detection (radial height sampling)
- Room boundaries at chokepoints
- Each room has type (entry, corridor, chamber, boss)

### Contextual Spawns (127)

Spawn appropriate creatures per room:
- Entry rooms: weaker guards
- Corridors: patrols
- Chambers: groups
- Boss rooms: single powerful creature

### Embedding Selection (128)

Use semantic embeddings for creature selection:
- Each creature has embedding vector
- Zone/room has theme embedding
- Select creatures by cosine similarity
- diversity_factor controls variety (0.0-1.0)

Creates thematically consistent dungeons without manual curation.

---

## rmail Integration (Reference)

Phase 9 systems (especially narrators) depend on rmail for external communication.
This section provides context. See **Phase 10** for the full treatment with
implementation details and design philosophy.

### Service Architecture

| Service | Port | Purpose | Phase |
|---------|------|---------|-------|
| accounts | 4562 | Account creation | 10 |
| classes | 4662 | Custom class submission | 7 |
| mail | 4762 | Game mail bridge | 10 |
| narrator | 4862 | Speech subscription | 9/10 |
| feedback | 4962 | Player feedback | 10 |

Port pattern: 4x62 where x increments per service.

### How Narrators Use rmail

Players subscribe to narrator speech via rmail:

```
to: wow.ritzmenardi.com/narrator
subject: subscribe

McGee
```

When narrator McGee speaks within 30 yards of any player:
1. ALE captures the speech event
2. Speech queued for all subscribers
3. on_send hook drains queue to outbox
4. Subscribers receive speech in rmail inbox
5. Optional TTS generates audio attachment

### Key Concepts (Preview)

**DNS-Style Addresses**: `wow.ritzmenardi.com/narrator` instead of `narrator:4862`
- Self-documenting, organized, discoverable

**Login Flush Hook**: Player login triggers pending message delivery
- Primes the pump for queued messages

**on_send Chain**: Successful delivery triggers check for more
- Self-draining queue, no polling daemon needed

For the WHY behind these decisions, see Phase 10's "Thoughts" sections.

---

## Clustered Worldserver (316)

### Long-Term Scaling

Distribute worldserver across machines:
- Each node owns specific zones
- Players transfer between nodes at zone boundaries
- Coordinator handles cross-node routing
- Global services (guilds, auction, mail) centralized

Not needed for v1.0, but documented for future growth.

---

## Notes

### Phase 9 Scope

Phase 9 focuses on in-game narrative and world structure:
- World Structure (portals, dungeons, zones)
- Narrative Systems (narrators, shepherds, lore generation)
- Social Systems (language barriers)
- Infrastructure (clustered worldserver)

External integration (rmail) has been moved to Phase 10.

---

## Related Phases

- **Phase 5** - Narrators reuse traveler movement
- **Phase 6** - Narrators may be playerbots
- **Phase 8** - Shepherds explain immortality
- **Phase 10** - rmail integration (narrator subscriptions, external bridge)
