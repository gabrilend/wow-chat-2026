# Everland Ghostsong - Phase 3 Progress: World Immersion and Hazards

## Goal
Introduce environmental hazards, storytelling NPCs, and progression mechanics that create a living, dangerous world beyond level 20.

## Status: Planning

## Issues

### Environmental Hazards
| ID | Title | Status |
|----|-------|--------|
| 301 | ocean-shark-hazard | Open |

### Social Systems
| ID | Title | Status |
|----|-------|--------|
| 302 | language-barrier-system | Open |

### Treasure System
| ID | Title | Status |
|----|-------|--------|
| 303 | chest-bound-hearthstones | Open |
| 305 | zero-value-treasure-duplicates | Open |

### Custom Classes
| ID | Title | Status |
|----|-------|--------|
| 304 | conditional-class-selector-spawn | Open |

### External Integration
| ID | Title | Status |
|----|-------|--------|
| 306 | rmail-ingame-bridge | Open |
| 313 | rmail-dns-style-addresses | Open |
| 314 | rmail-feedback-mailbox | Open |
| 315 | rmail-login-flush-hook | Open |
| 317 | rmail-account-creation | Open |

### NPC Behaviors
| ID | Title | Status |
|----|-------|--------|
| 307 | narrator-audience-facing | Open |
| 310 | wandering-narrator-system | Open |
| 311 | shepherd-flock-system | Blocked (312) |

### Content Systems
| ID | Title | Status |
|----|-------|--------|
| 308 | gutenberg-text-library | Open |
| 312 | automated-lore-generation | Open |

### Progression Systems
| ID | Title | Status |
|----|-------|--------|
| 309 | invisible-level-progression | Open |
| 345 | custom-talent-interface | Open |

### Documentation Tooling
| ID | Title | Status |
|----|-------|--------|
| 327 | html-source-tree-export | Open |
| 328 | wimmelbilder-embedding-artwork | Open (depends 327) |

### Build Infrastructure
| ID | Title | Status |
|----|-------|--------|
| 334 | patch-system-improvements | Complete |
| 408 | release-profile-build-fixes | Complete |
| 409 | manual-patch-application-command | Complete |

## Phase Milestones

### Environmental Hazards
- [ ] Sharks spawn in open water after time threshold
- [ ] Players discouraged from water travel without purpose

### Social Systems
- [ ] Common/Orcish removed as default languages
- [ ] Language tomes craftable via inscription
- [ ] Tome fragility mechanics working (vendor/mail destroys)
- [ ] Cross-faction communication via shared languages

### Treasure System
- [ ] Blue and Red hearthstones circulating in chest pool
- [ ] Stones bind to chest location when looted
- [ ] Teleport returns player to discovery location
- [ ] Pool items have 0 sell value (gold flows once)
- [ ] Enchantments preserved through redistribution cycle

### Custom Classes
- [ ] Selector NPC only spawns when custom classes exist for base class
- [ ] Empty custom-class-json/ directory = no selector NPCs

### External Integration
- [ ] Game mail forwarded to rmail inbox
- [ ] Item attachments rendered as PNG icons
- [ ] rmail outbox can send to in-game characters
- [ ] Public subscription model (anyone can subscribe)
- [ ] DNS-style addresses supported (wow.ritzmenardi.com/service)
- [ ] Feedback mailbox collecting player messages
- [ ] Login flush hook triggers pending message delivery
- [ ] Guest accounts with public credentials
- [ ] rmail accounts with bi-directional deletion lifecycle

### NPC Behaviors
- [ ] Narrators sit when audience is seated
- [ ] Narrators face to maximize seated players in front cone
- [ ] Narrators are playerbots (followable)
- [ ] Stop moving when player/bot sits within 5 yards
- [ ] Read one sentence at a time from Gutenberg library
- [ ] Rumor storage and keyword association
- [ ] Pattern matching triggers rumor sharing (20% threshold)
- [ ] Rumors told once then forgotten
- [ ] Cross-instance rumor propagation (telephone game)
- [ ] Interruption detection switches to rumor mode
- [ ] Multiple pacing patterns (orbit, midpoint, point-to-point, S-curve)
- [ ] Sleep mode (cozy fire, 30 min, forgets rumors)
- [ ] Shepherds wander with critter flocks (invulnerable)
- [ ] Flock avoids monsters, parts around players
- [ ] Critters walk normally, burst 100% speed if player too close
- [ ] True names rotate periodically (configurable)
- [ ] Shepherds seed rumors to narrators (no players nearby)
- [ ] Story keyword match (20%) triggers lore dialogue
- [ ] Shepherd + flock transform to tradeskill nodes
- [ ] Node level matches invisible level (only source for 20+ mats)
- [ ] Ulduar boss spawns every 80 immortals (centroid position)
- [ ] Immortal kneel → permanent critter transformation

### Content Systems
- [ ] Gutenberg scraper downloads and parses texts
- [ ] Sentence splitter (periods, not commas)
- [ ] Curated book list (~20-50 titles)
- [ ] Library API for narrator sentence retrieval
- [ ] Automated lore generation pipeline (no human curation)
- [ ] Ollama integration for story generation
- [ ] Validation layer (length, forbidden words, theme presence)
- [ ] Self-evaluation prompt for quality filtering
- [ ] Content pool management and rotation
- [ ] Keyword extraction from generated stories

### Progression Systems
- [ ] Custom talent interface functional
- [ ] Invisible XP tracking after level 20
- [ ] Monster level scales with invisible level (20 + invisible)
- [ ] Monster damage scaled down to level 20
- [ ] No spawn cap for invisible-level players (mandatory grouping)
- [ ] Permadeath: death with no equipment = character deleted
- [ ] Immortality at invisible level 60: gold coin, no more spawns

### Documentation Tooling
- [ ] Script exports project to static HTML directory tree
- [ ] Source code syntax highlighted
- [ ] Issues directory navigable as build journal
- [ ] Phase progress files structure the narrative
- [ ] LLM transcripts included as appendix
- [ ] Gitignored files excluded from output
- [ ] (327 complete) Embedding-based margin artwork
- [ ] (327 complete) Infinite canvas pan/zoom
- [ ] (327 complete) i-spy elements per file

## Dependencies

Phase 3 depends on:
- Phase 2 completion (behaviors, treasure system, custom classes)
- Stable ambush spawn system
- Travel system functional

## Notes

### 2026-04-06 - Invisible Level Progression (309)
- Post-20 endgame: invisible XP stored in database
- XP thresholds match normal leveling curve (21, 22, 23...)
- Monsters spawn at level 20 + invisible level
- Damage scaled to level 20, HP stays full = tanky long fights
- Better loot with no level requirements
- **No spawn cap:** Monsters pile up endlessly, solo play impossible
  - Must group up to survive - mandatory social gameplay
- **Permadeath:** Die with no equipment = character deleted
- **Immortality:** Reach invisible level 60 (effective 80)
  - Gold coin in mail, monsters stop spawning forever

### 2026-04-06 - Gutenberg Text Library (308)
- Scraper/parser for Project Gutenberg public domain texts
- Downloads texts, strips headers/footers, cleans content
- Splits into sentences (on periods, not commas)
- Stores one sentence per line for narrator consumption
- Curated list of ~20-50 fantasy/adventure/mythology books
- **Per-instance state:** Each spawn GUID has independent book/position/mode
  - Story position never shared; rumors ARE shared (telephone game)
- **rmail distribution:** Forward what you heard in person to rmail
  - Must be within ~20-30 yards to receive speech (not remote listening)
  - Get permanent copy to review later or share with others
  - Optional TTS: generate mp3 with narrator's speaking rhythm

### 2026-04-06 - Automated Lore Generation (312)
- **Goal:** Generate shepherd stories without human curation
- **Blocks:** Issue 311 (shepherd-flock-system)
- **Open questions (many):**
  - Quality metrics: what makes "good enough"?
  - Tone consistency: how ensure same-world feel?
  - Content safety: prevent inappropriate generation?
  - Keyword extraction: automatic or generated alongside?
  - Self-evaluation: can LLM rate its own output reliably?
  - Generation frequency: on demand vs scheduled?
  - Which Ollama model: llama3, mistral, mixtral?
- **Pipeline concept:**
  - World context + shepherd identity + themes → Ollama
  - Validation checks (length, forbidden words, theme presence)
  - Self-eval prompt for quality score
  - Pass → content pool, Fail → retry/log
- **Speculative config:**
  - Pool size: 20-50 stories
  - Self-eval threshold: 6/10 minimum
  - Max retries: 3 per generation attempt
- Requires research and experimentation before implementation

### 2026-04-06 - Shepherd and Flock System (311) - BLOCKED BY 312
- Immortal shepherds wander with critter flocks
- Big creatures (giraffes, kodo) scattered everywhere, unkillable
- **Flock dynamics:**
  - Walk at walking speed normally, stay near shepherd
  - Avoid monsters, part around players like flowing water
  - Burst 100% speed if player gets too close (player only has 80%)
- **True names:** Shepherds have curated names/stories that rotate periodically
- **Rumor seeding:** Shepherds whisper to narrators when no players nearby
  - Creates discovery chain: narrator → player → shepherd
- **Story generation:** See issue 312 (automated-lore-generation)
- **Lore trigger:** Player says 20% of story keywords in /say
  - Shepherd reveals they're the only one who should know it
  - Explains immortality mechanics (issue 309)
  - Vanishes in puff of smoke → tradeskill nodes
- **Tradeskill nodes:** ONLY source for level 20+ materials
  - Each critter becomes a node too
  - Node level matches player's invisible exp level
- **Ulduar boss:** Every 80 immortals → boss spawns at continent centroid
  - Never despawns until slain
  - High HP, balanced abilities
- **Permanent critter transformation:**
  - Immortal player kneels before shepherd
  - Confirms "are you sure?" → player becomes flock critter forever
  - No input, chat appears as gibberish (knows no languages)
  - Hidden from /who, unselectable
  - On login: spawn shepherd at logout pos (shepherd always exists for player-critter)
  - Shepherd won't despawn while player-critters in flock

### 2026-04-06 - Wandering Narrator System (310)
- Core storytelling NPC system using playerbots
- Wander like travelers, stop when player sits within 5 yards
- Read one sentence at a time from Gutenberg library (issue 308)
- **Rumor mechanics:** PM narrator to share info, stores with keyword associations
- Pattern match player /say against stored rumors (20% threshold)
- Share matching rumors once only, then forget
- **Telephone game:** Rumors propagate across instances
  - Player A tells rumor to McGee in Elwynn
  - Player B hears it from McGee in Northrend
- Interruption detection: too much /say → switch to rumors mode
- **Movement patterns:**
  - Orbit: circle seated players at 5 yards
  - Midpoint: walk between two seated players
  - Point-to-point: 2 steps, stop, spin, ponder, continue
  - S-curve: lazy sine wave at full walking pace
- Sleep mode: spawn cozy campfire, 30 minutes, forgets rumors
- Rate limit: 1 PM per second per narrator instance
- TTS via rmail subscription (must be within 20-30 yards)

### 2026-04-06 - Narrator Audience Facing (307)
- Narrator behavior: sit and face seated audience
- Check 30 yard radius: more sitting than standing → sit down
- Calculate optimal facing to maximize seated players in front cone
- Creates natural storytelling circles
- Releases when audience disperses or stands up

### 2026-04-07 - rmail Account Creation (317)
- Two-pathway account system: guest and rmail accounts
- 24 permanent guest accounts with public credentials (filament, verbose, clock, etc.)
- rmail accounts created via message (username on line 1, password on line 2)
- Bi-directional deletion: delete outbox message → account deleted
- Protected list prevents guest accounts from accidental deletion
- Port 4562, address: wow.ritzmenardi.com/accounts

### 2026-04-07 - rmail Login Flush Hook (315)
- ALE hook triggers queue flushing when player logs in
- Primes the pump for pending rmail deliveries
- Each service (mail, narrator) has pending files flushed to outbox
- One message per subscriber written to outbox on login
- Triggers on_send chains for self-draining delivery

### 2026-04-07 - rmail Feedback Mailbox (314)
- Simple feedback collection via rmail
- No automation, no hooks - messages accumulate for manual review
- Port 4962, address: wow.ritzmenardi.com/feedback
- Public token so anyone can send feedback
- Optional notification hook for desktop alerts

### 2026-04-07 - rmail DNS-Style Addresses (313)
- DNS-style contact names: wow.ritzmenardi.com/accounts
- Self-documenting, organized, discoverable addresses
- Port allocation pattern: 4x62 (accounts=4562, classes=4662, mail=4762, narrator=4862, feedback=4962)
- Backwards compatible with simple contact names
- Parser update: split on .ip/.port/.token suffixes, not first dot

### 2026-04-06 - rmail In-Game Bridge (306)
- Bridge between WoW mailbox and external rmail system
- Game mail forwarded to rmail with text preserved
- Item attachments become PNG icons of the item
- Can send mail to characters via rmail outbox
- Public subscriptions: anyone can subscribe to any character's mail
- Creates information economy and spy gameplay

### 2026-04-06 - Zero-Value Treasure Duplicates (305)
- Items entering treasure pool become 0 sell value duplicates
- Prevents infinite gold generation through vendor→chest→vendor cycle
- Gold enters economy once (original vendor sale), then item circulates forever
- Enchantments preserved: enchanted items keep enchants through all cycles
- Free enchanted gear from chests = valuable finds

### 2026-04-06 - Conditional Class Selector Spawn (304)
- Selector NPC only spawns if custom classes exist for player's base class
- Scan custom-class-json/ directory for valid definitions
- Cache base classes with customs on startup
- No customs for base class = no NPC, player uses base class as-is

### 2026-04-06 - Chest-Bound Hearthstones (303)
- Two unique hearthstones (blue/red) circulate through treasure chests
- When looted, stone binds to that chest's location
- Using stone teleports player back to discovery spot
- Stone immediately respawns into treasure pool when taken
- Players can have both colors = two custom return points
- No inns exist, so these are the only teleport options

### 2026-04-06 - Language Barrier System (302)
- Remove Common/Orcish as default languages
- Each race only knows their racial language
- Inscription creates language tomes for learning
- Tome fragility: vendoring/mailing destroys them
- Cross-faction communication through shared learned languages
- NPCs understand all languages, narrators can translate

### 2026-04-06 - Phase 3 Initialized
- Created phase progress file
- First issue: 301-ocean-shark-hazard (environmental hazard)
- Migrated 345-custom-talent-interface from pre-existing issue

### 2026-04-08 - HTML Source Tree Export (327)
- Script to export project as static HTML site
- Directory tree navigation, syntax-highlighted source
- Issues presented as "build journal" narrative
- Phase progress files structure chapters
- LLM transcripts as appendix ("here's the transcript if you don't believe me")
- Respects .gitignore, excludes config/build/secrets
- **User feedback requested:**
  - Single-page app vs multi-page static?
  - Hosting target (rmail, offline, CDN)?
  - Narrative priority (issues-first vs source-first)?
  - Transcript integration (full vs excerpts vs line refs)?

### 2026-04-08 - Wimmelbilder Embedding Artwork (328)
- Depends on 327 completion
- AI-generated i-spy artwork in HTML page margins
- Artwork seeded from word embeddings of file contents
- Files about similar topics → similar art palettes
- **Visual features:**
  - Infinite canvas scrolling (JavaScript)
  - Zoom coherence: artwork scales to fill viewport
  - Pre-generated for common aspect ratios
  - i-spy elements themed to code domain
- **User feedback requested:**
  - Embedding source (word2vec, code2vec, bag-of-words)?
  - Art style (pixel, illustrated, abstract)?
  - Generation pipeline (pre-gen, on-demand, hybrid)?
  - i-spy integration (decorative vs actual game)?

### 2026-04-14 - Manual Patch Application Command (409)
- New CLI command: `./scripts/azerothcore apply-patches`
- Allows manual application of PHASE_BEGIN and PHASE_END patches
- Options: --begin, --end, --all, --target shadow|main, --revert, --dry-run
- Useful for testing patches, re-applying after corruption, applying to main after promotion
- Incremental compilation supported: cmake/make only rebuilds affected files

## Related Files
- src/lua/ambush.lua - Spawn system patterns to follow
- src/lua/movement.lua - Water detection helpers
- src/lua/treasure.lua - Chest redistribution queue
- src/lua/custom-classes.lua - Custom class selector system
- scripts/azerothcore - Build orchestration, patch application
- patches/patches.sh - Profile-specific patch lists and orchestration
