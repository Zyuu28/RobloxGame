# STEAL A MYSTERY BOX! — Project README (Agent Entry Point)

> Roblox multiplayer simulator · PC & Mobile · Luau · Server-authoritative
> Source of truth: `Steal_a_Mystery_Box_GDD_v2_0` (6 Nov 2026). This README is a condensed, agent-oriented mirror of that GDD. If this file and the GDD ever disagree, the GDD wins. Raise the conflict in `DECISION_LOG.md` instead of silently choosing.

---

## 0. READ THIS FIRST (Rules for the AI coding agent)

### 0.1 Authority tags
| Tag | Meaning | What you do |
|---|---|---|
| `[LOCKED]` | Agreed concept. | Do NOT change without explicit design approval from the user. |
| `[PROPOSED]` | Engineering default. | Implement as a **configurable** prototype value (config module, never hardcoded). The designer may tune it later. |
| `[POST-MVP]` | Planned later. | Do NOT build it into the MVP. Do not silently add it. |

### 0.2 Operating rules
1. Treat the GDD/README as a contract. Implement **MVP scope only** unless the user approves an expansion.
2. If a needed detail is unspecified: use the documented `[PROPOSED]` default, record it in `DECISION_LOG.md`, and never invent a mechanic that conflicts with a `[LOCKED]` rule.
3. Work **feature by feature** (one module/service at a time). No monolithic scripts. **Always keep the place playable.**
4. **Before writing code:** summarize your assumptions, cross-check dependencies, and list any spec conflicts.
5. Build the **authoritative server transaction path first**, UI polish later.
6. **Never** let the client choose rarity, item, money amount, ownership, carry state, or save data.
7. No values buried in gameplay code. Everything tunable lives in config tables.
8. Use only assets/code the team has rights to use. "Steal an Egg!" is a high-level map/progression inspiration only. Do NOT copy its assets or level geometry.
9. Do not fabricate finished assets. Do not claim a feature works unless it was tested in Roblox Studio. If you could not test it, say so.

### 0.3 Per-module deliverable checklist
For every module you deliver, report:
- Source path
- Public API
- Remote interface (if any)
- Security checks
- Test instructions
- Configuration knobs

### 0.4 After every phase, report
- Files built
- Known bugs
- Acceptance Criteria (AC-xx) passed
- Deferred features

Also include automated/unit-style tests where practical, plus a **two-player manual regression scenario**.

---

## 1. Product Summary

| Item | Value |
|---|---|
| Title `[LOCKED]` | Steal a Mystery Box! |
| Genre `[LOCKED]` | Multiplayer exploration + collection + unboxing + base tycoon |
| Audience `[LOCKED]` | Casual / all ages |
| Platforms `[LOCKED]` | Roblox desktop and mobile |
| Player fantasy | "I spotted a rare box far from home, escaped with it, opened it in my plot, and earned a collectible I can proudly display." |

### Design pillars (use as design tests)
1. **Visible discovery**: boxes are spotted from a readable distance and found by exploration, never purchased.
2. **Risk & return**: farther biomes take longer to reach; getting a box home matters.
3. **Surprise & collection**: unboxing reveals biome-themed items with meaningful rarity and visual identity.
4. **Home progression**: displayed collectibles generate Bucks; upgrades improve capacity and convenience.
5. **Short-session clarity**: a new player understands the hunt → return → open → display loop without a tutorial wall.

---

## 2. Core Loop `[LOCKED]`

```
EXPLORE → FIND → PICK UP ("steal" from world) → CARRY HOME → UNBOX → COLLECT → DISPLAY → EARN BUCKS → UPGRADE → REPEAT
```

- "Steal" is the title/fantasy. **MVP:** players pick up **shared, world-spawned** Mystery Boxes. **Stealing a box held by another player is NOT implemented.** Player-to-player theft needs a separate approved PvP design.
- Safezone protects carried boxes.

### 2.1 Target first 10 minutes
| Time | Event |
|---|---|
| 00:00 | Spawn at an assigned empty plot; concise tutorial prompt. |
| 00:30 | Walk into Urban; notice visible Common boxes. |
| 01:00 | Pick up one box (one at a time), carry it home. |
| 02:00 | Plot interaction starts a short unboxing reveal; grants one item. |
| 02:30 | Place the item on a display stand; passive income begins. |
| 03:00+ | Claim Bucks at Money Collector, learn first upgrade, explore farther. |

---

## 3. World Map

### 3.1 Linear layout `[LOCKED]`
`SAFEZONE → URBAN → SLUMS → MOUNTAIN → OCEAN → SPACE`

One traversable main corridor links all areas, with local detours, secrets, and landmarks inside each biome. Travel back to the Safezone must always be possible.

| Zone | Visual theme | Traversal hook | Box theme | Release |
|---|---|---|---|---|
| Safezone | Bright landscaped plaza; 8 player plots, services | Protected hub; central spawn | No world boxes | **MVP** |
| Urban | Modern buildings, roads, rooftops | Open streets and alleys | Neon city | **MVP** |
| Slums | Colorful backstreets, workshop, junkyard | Tight alleys and scrap piles | Patchwork metal | **MVP** |
| Mountain | Pine slopes, crystal mine, caves | Cliffs, ramps, cave paths | Stone and crystal | Post-MVP |
| Ocean | Docks, coral, shipwrecks | Boardwalk + shallow/underwater route | Shell and coral | Post-MVP |
| Space | Asteroids, station, cosmic islands | Safe platforms/portals | Purple starfield | Post-MVP |

Schematic: `[PLOTS/SHOPS/SPAWN] ==> [CITY] ==> [BACKSTREETS] ==> [HIGHLANDS] ==> [DEEP BLUE] ==> [GALAXY]`

### 3.2 Initial sizes `[PROPOSED]` (studs)
Safezone 300×220 · Urban 250×220 · Slums 250×220 · Mountain 275×220 · Ocean 275×220 · Space 250×220.
The world may be curved/offset for sightlines but must keep **one clear progression axis**. **Walk-test traversal times, not dimensions, are the acceptance standard.**

### 3.3 Navigation rules
- Keep the main route legible: signage, color transitions, directional props, view corridors.
- **No compulsory biome unlock gates in MVP.** Distant areas are expansion-only until built.
- Do not teleport players into the next biome by default. Space portals are local traversal aids only.
- One Mystery Box carried at a time. Walking/jumping supported; **no mandatory obby precision while carrying.**
- Safezone is a **no-theft / no-combat** region; world boxes never spawn there.
- Spawn points must be accessible: no inaccessible rooftops, buried geometry, or unsafe zones.

---

## 4. Safezone & Player Plots

| Object | MVP behavior |
|---|---|
| Player Spawn | Spawn inside Safezone; assign one vacant plot on join. |
| 8 Player Plots | One per active player (server cap = 8 `[PROPOSED]`). Plot belongs to session user; saved layout reloads. |
| Unboxing Area / Pad | Interact with / place the carried Mystery Box to open it. |
| Display Stands | Show placed collectibles; generate passive Bucks. |
| Money Collector | Player explicitly claims accrued display earnings. |
| General Shop | Future or minimal flavor. **No mystery-box vending or purchase.** |
| Upgrade Shop | Buy inventory-capacity and display-slot upgrades. |
| Collection Center | `[POST-MVP]` full Collection Book. MVP may show a simple discovered count. |

`[PROPOSED]` First plot layout: spawn entrance, unboxing pad, **3 free stands**, one Money Collector, build/upgrade access. Other players may **visit and view** plots but **cannot modify** them.

---

## 5. Mystery Box System

### 5.1 Box data
`[LOCKED]` **Box rarity and collectible rarity are separate.** Every box has: biome, box tier, unique world-spawn ID, visual asset, loot-table ID, and state.

Tiers: `Common, Uncommon, Rare, Epic, Legendary, Secret`.

### 5.2 State machine
| State | Definition | Allowed transition |
|---|---|---|
| `AVAILABLE` | Anchored at a valid spawn point | → `CARRIED` |
| `CARRIED` | Attached to a single player avatar | → `UNBOXED` or `RETURN_PENDING` |
| `RETURN_PENDING` | Carrier reset/death/disconnect; world object cleared | → `AVAILABLE` after respawn cooldown |
| `UNBOXED` | Reward transaction completed **once** | → `DESPAWNED` |
| `DESPAWNED` | No longer visible/interactable | → new instance at scheduled spawn |

### 5.3 Carry & pickup `[PROPOSED]`
- One box per player.
- Interaction via `ProximityPrompt` (desktop **E** / touch prompt), **8-stud server-validated range**, **0.4 s hold**.
- Carry movement speed = **80%** of normal walk speed.
- Box visually offsets in front of the avatar, **collisionless**, **no drop button in MVP**.
- If the player dies, resets, teleports unexpectedly, leaves, or disconnects while carrying → box is removed from the avatar and returns to its spawn point after cooldown.
- If the player reaches their **assigned plot**, only the plot owner can unbox it.

### 5.4 Spawn scheduler (server only) `[PROPOSED]`
- Each biome has spawn points tagged by biome, weight, and allowed tiers.
- MVP distribution: **Urban 12 points / max 6 active boxes; Slums 12 points / max 6 active boxes.**
- An occupied point cannot spawn another box.
- After successful pickup or cleanup: randomized cooldown **25–45 s**.
- No boxes inside player plots or the Safezone.
- All random rolls and spawn ownership are server-controlled.
- Send lightweight spawn state to clients; render visuals at a safe distance with performance limits.

### 5.5 Box tier weights per biome `[PROPOSED]` (illustrative, not final balance)
| Biome | Common | Uncommon | Rare | Epic | Legendary | Secret |
|---|---|---|---|---|---|---|
| Urban | 45% | 27% | 17% | 8% | 2.5% | 0.5% |
| Slums | 40% | 28% | 19% | 9% | 3% | 1% |
| Mountain | 35% | 27% | 21% | 11% | 5% | 1% |
| Ocean | 30% | 27% | 22% | 13% | 6% | 2% |
| Space | 25% | 25% | 23% | 15% | 9% | 3% |

Each row sums to 100%. Reconcile with traversal distance during testing.
**These are BOX-SPAWN tier probabilities. NEVER use them as collectible-drop probabilities.**

---

## 6. Unboxing & Reward Generation

Flow (only at the owner's plot):
`Interact with Unboxing Pad → server confirms valid carried box + owner plot → server atomically marks box consumed and awards ONE eligible collectible from the (biome, boxTier) loot table → client plays 2–4 s reveal → item appears in inventory → box destroyed.`

**Critical rule:** a Legendary Mystery Box is **NOT guaranteed** to give a Legendary collectible. Lower-tier items may appear. **All rewards are rolled on the server, never locally.**

| Step | Server-side check | Client feedback |
|---|---|---|
| Start | Owner plot, carried valid box, not already consumed | Unboxing progress; locked controls |
| Roll | Secure weighted random pick from the correct loot table | Suspense animation (cosmetic only) |
| Commit | Unique reward instance saved in session; box removed once | Rarity reveal, item name and image |
| Inventory | Capacity and overflow policy applied | Inventory updated or reward notice |
| Fail | No duplicate grant; box retained on retryable fault | Clear error / retry prompt |

`[PROPOSED]` **Inventory full:** block unboxing **BEFORE** consuming the box and show an "Inventory Full" UI. Never silently discard rewards. Double-clicks, lagged remote calls, and disconnects must not duplicate grants.

### 6.1 Loot tables `[PROPOSED]`
- Explicit per `(biome, boxTier)`.
- Each row: `itemId`, positive integer `weight`, optional unlock rule, `rarity`.
- A prototype may use broader shared pools within a biome but **may not contradict the separate-tier rule.**
- The full 6×5 tables must be authored in **data files**. (Currently not fully defined. See Decision Log.)

---

## 7. Collectibles

`[LOCKED]` Hybrid style: living objects, creatures, robots, artifacts, decorations, optional wearable accessories.

Every collectible has: `ID, biome, rarity, model, icon, incomePerSecond, tags (Displayable/Wearable), optional FX, Collection Book entry`.

### 7.1 Concept catalog (7 initial names per biome)
| Biome | Common | Uncommon | Rare | Epic | Legendary | Secret |
|---|---|---|---|---|---|---|
| Urban | Traffic Buddy / Soda Can | Mini Skyscraper | Street Bot | Golden Taxi | Cyberpunk DJ | City Guardian |
| Slums | Cardboard Buddy / Rusty Can | Tire Monster | Scrap Robot | Junkyard King | Street Phantom | Scrap Titan |
| Mountain | Pebble Pal / Mountain Goat | Crystal Bug | Eagle Scout | Crystal Golem | Baby Yeti | Ancient Mountain Beast |
| Ocean | Bubble Buddy / Baby Crab | Octo Pal | Treasure Chest Mimic | Coral Guardian | Abyssal Whale | Leviathan |
| Space | Baby Alien / Moon Buddy | Mini Satellite | Astro Bot | Nebula Slime | Cosmic Dragon | Galaxy Devourer |

These are concept catalogs, **not** the final 10 items/biome. **MVP requires at least 7 Urban + 7 Slums models** with unique visual identities (14 total). More items are added data-first.

### 7.2 Items and copies
- Each reward creates a unique collectible `instanceId`. Duplicates of the same `itemId` are allowed.
- Inventory stores owned **instance IDs**.
- A placed instance cannot be placed on another stand, nor sold/used simultaneously.
- Display stands reference `instanceId`, not just `itemId`. Server validates ownership on place/remove.
- `[POST-MVP]` Wearables (need documented equip + avatar compatibility rules), shiny variants, full Collection Book, collection-completion rewards, seasonal items.

---

## 8. Economy, Passive Income & Upgrades

`[LOCKED]` Primary currency = **Bucks ($)**. Earnings come from displayed collectibles and are **manually collected** at a Money Collector.

| System | MVP default `[PROPOSED]` |
|---|---|
| Free display stands | 3 per plot |
| Base inventory capacity | 20 instances |
| Base Bucks | 0 (first collectible is free to obtain) |
| Common income example | 2 Bucks/s |
| Rare income example | 15 Bucks/s |
| Legendary income example | 100 Bucks/s |
| Money Collector | Claim pending earnings on interaction |
| Tick calculation | Compute from server elapsed time; update HUD at low frequency |
| Offline income | **OFF** in MVP |
| Sell/discard | **OFF** in MVP unless an explicit safe replacement is approved |

Income values are **illustrative placeholders**. The economy designer sets each collectible's real `incomePerSecond`.

Pending earnings are stored in session **and saved persistently** so a reconnect does not erase legitimately accrued currency. Only **online elapsed** income accrues.

### 8.1 Upgrades `[PROPOSED]`
| Upgrade | Level 0 | Level 1 | Level 2 | Level 3 |
|---|---|---|---|---|
| Inventory capacity | 20 | 30 / $150 | 45 / $500 | 65 / $1,500 |
| Display stand capacity | 3 | 4 / $250 | 5 / $850 | 6 / $2,500 |

Purchase requires enough Bucks and level below cap. Server deducts currency and bumps the level **exactly once**. Upgrades persist across sessions and re-instantiate on plot load.

---

## 9. UX / UI / Accessibility

| Screen | Content | Trigger |
|---|---|---|
| HUD | Bucks available, Bucks pending, carried-box indicator, inventory button | Always visible |
| Box Prompt | "Pick up [Tier] [Biome] Mystery Box" | Near an available box |
| Unboxing UI | Box identity, opening sequence, item rarity reveal | Owner plot unbox |
| Inventory | Grid, filters by biome/rarity, capacity, place action | HUD button |
| Plot Mode | Stand select, place/remove item, current income | At owned plot |
| Upgrade Shop | Current level, next benefit, price, purchase button | Near shop / UI |
| Feedback | Full inventory, invalid interaction, success/failure | On relevant events |

- Mobile: touch targets **≥ 44 logical px** where feasible; **no keyboard-only interactions**; prompts use Roblox-supported input UI.
- UI readability beats animation. Avoid flashing effects; offer reduced FX where possible.
- Tier is shown by glow + emblem + audio + readable text. **Never rely on color alone.**

---

## 10. Onboarding & Session Progression
- Three-step guide: **Find a box → Bring it home → Open & Display.**
- A guide arrow points to the nearest Urban box initially. The tutorial must **not** spawn duplicate rewards.
- Completion is checked on the server, persisted, and must not repeat after rejoin.
- MVP has **no Level/XP and no area unlock gates.** `[POST-MVP]` levels and area access are separate systems.

---

## 11. Multiplayer Rules `[PROPOSED]`
- **8 players per server, 8 plots.** Plot assignment is one-to-one and stable within a session. Free plots are reclaimed when players leave. At capacity, rely on the server player cap, never overlapping assignments.
- Two players on the same box: **first server-authorized pickup wins**; the loser gets "already taken" feedback.
- Visitors cannot unbox, move, claim earnings, or upgrade on someone else's plot.
- **No PvP combat, no stealing a held box, no griefing in MVP.**
- Plot/stand ownership is never inferred from client-visible labels.
- On leave: transient world box resets; permanent data is saved; display layout persists to next login.

---

## 12. Technical Architecture (Roblox / Luau)

Server-authoritative services + ModuleScripts. **No client authority** over rewards, money, ownership, rare drops, carry state, or saves. Shared data definitions live in `ReplicatedStorage`; trusted mutation logic lives in `ServerScriptService`.

### 12.1 Suggested structure
| Location | Modules / objects |
|---|---|
| `ReplicatedStorage/Shared` | `Configs/Biomes.lua`, `Boxes.lua`, `Collectibles.lua`, `Economy.lua`, `Upgrades.lua`; `Remotes` |
| `ServerScriptService/Services` | `PlotService`, `SpawnService`, `CarryService`, `UnboxService`, `InventoryService`, `DisplayService`, `EconomyService`, `DataService` |
| `ServerStorage/Assets` | `MysteryBoxModels`, `CollectibleModels`, `PlotPrefabs` |
| `StarterPlayerScripts/Controllers` | `InteractionController`, `InventoryController`, `UnboxController`, `HUDController` |
| `Workspace/World` | `Safezone`, `Biomes/Urban`, `Biomes/Slums`, `Tags/SpawnPoints`, `PlayerPlots` |

Use `CollectionService` tags (or equivalent metadata) for spawn points, display stands, and interaction pads. Use central authoritative validation functions; do not duplicate security logic.

### 12.2 Remote interface (names are suggestions)
| Remote (direction) | Input | Server contract |
|---|---|---|
| `RequestPickup` (C→S) | `worldBoxId` | Validate box exists, is free, player in range, player not already carrying |
| `RequestUnbox` (C→S) | `plotId` | Validate assigned owner + held box + inventory capacity; **single grant** |
| `RequestDisplay` (C→S) | `instanceId, standId` | Validate item ownership, stand ownership, no duplicate placement |
| `RequestUndisplay` (C→S) | `standId` | Validate owner; return instance to inventory |
| `RequestClaim` (C→S) | `plotId` | Validate owner; transfer pending → wallet **once** |
| `RequestUpgrade` (C→S) | `upgradeId` | Validate price, level, wallet; commit **once** |
| `StateUpdate` (S→C) | filtered state delta | Read-only status, balances, inventory, FX triggers |

UI must never directly alter replicated values as a source of truth. Include **rate limits, type validation, distance/ownership checks, monotonic transaction IDs, and replay protection.**

### 12.3 Data schema v1 (illustrative)
```lua
PlayerProfile = {
  schemaVersion = 1,
  bucks = 0,
  pendingBucks = 0,
  inventoryCapacityLevel = 0,
  displayCapacityLevel = 0,
  inventory = { [instanceId] = { itemId, obtainedAt, variant } },
  displaySlots = { [slotId] = instanceId },
  discoveries = { [itemId] = true },
  tutorial = { ... },
  lastSavedAt = timestamp,
}

-- Session-only (do NOT persist; a carried world box is never saved)
SessionState = {
  assignedPlotId, carryingWorldBoxId,
  interactionCooldowns, lastEconomyTick, pendingTransactions,
}
```
Use `DataStoreService`; wrap in `pcall` + retry; use `UpdateAsync` where appropriate; provide schema migration; **never overwrite good data after a failed load.**

### 12.4 Security, performance, resilience
- Server controls weighted rolls, box claims, economy calculation, upgrades, and persistence.
- `ProximityPrompt`/`RemoteEvent` triggers must be validated server-side. Client-visible distance or prompt settings alone are insufficient.
- **Unbox is an idempotent server transaction:** one carried box creates at most one collectible instance.
- Bounded retries on save. On failed profile load, **block mutations** and show a retry/leave message. Do not create disposable data.
- Do not save every second. Batch timed/meaningful saves; save on leave and shutdown within platform limits.
- Prefer anchored models, simple collisions, client-side VFX. Run streaming/performance tests on low-end mobile.
- Instrument: pickup failures, unbox failures, save failures, dupes, earning anomalies, server tick time.

---

## 13. Content & Art Direction

Stylized, colorful, **low-poly** Roblox aesthetic. The box stays an instantly recognizable **cube**.

| Biome | Box pattern |
|---|---|
| Urban | Neon / blue |
| Slums | Patched orange metal |
| Mountain | Rock / crystal green |
| Ocean | Blue shell / coral |
| Space | Purple nebula / starfield |

| Asset type | MVP minimum | Definition of done |
|---|---|---|
| World geometry | Safezone + Urban + Slums | Playable traversal, clear landmarks, no inaccessible spawn spots |
| Mystery box models | 2 biome variants × 6 tier skins (may share a base mesh) | Consistent pivot, prompt attachment, LOD/readability |
| Collectible models | 14 named unique items (7/biome) | Readable silhouettes, stand-compatible, icons present |
| Plot kit | 1 plot model repeated ×8 | Spawn, unbox pad, 3 starting stands, money collector |
| UI | HUD, Inventory, Reveal, Shop, Errors | Desktop/mobile tested |
| Sound/VFX | Pickup, reveal, rarity sting, claim | No copyrighted borrowed media; optimized |

---

## 14. Monetization & Responsible Design `[POST-MVP]`
- Optional: cosmetic passes, special effects, plot decoration, event cosmetics. Temporary boosts only after balance and purchase validation.
- Do not sell basic usability. Do not use misleading loot odds.
- If paid randomized rewards are ever introduced, re-evaluate Roblox platform policy and disclosure requirements. **Not part of this MVP.**

---

## 15. Build Plan (Phases)

| Phase | Deliverables | Exit condition |
|---|---|---|
| **P0 Foundation** | Place structure, configs, data schema, service stubs, test harness | Game starts with 8 unique plots, no runtime errors |
| **P1 World & spawning** | Safezone + Urban/Slums; spawn scheduler; 2 box designs | Server spawns eligible boxes; pickup race is safe |
| **P2 Loop** | Carry to plot; secure unbox; inventory; 14 collectibles | New player can obtain and retain an item |
| **P3 Economy** | Place/remove on stands, passive generation, collector, upgrades | Income and balances consistent and persistent |
| **P4 UX, save & polish** | UI, tutorial, effects, error handling, DataStore, mobile | All acceptance tests pass with multiple players |
| **P5 Expansion** | Mountain, Ocean, Space, additional catalogs | Separate release scope and playtest |

Current target: **P0 → P4 (MVP). P5 is out of scope until approved.**

---

## 16. MVP Acceptance Criteria (ALL must pass)

| ID | Criterion |
|---|---|
| AC-01 | 8 simultaneous players get distinct plots; a 9th does not overlap a plot (server cap = 8). |
| AC-02 | No Mystery Box spawns in the Safezone or inside a plot. |
| AC-03 | Urban and Slums boxes spawn per configured points and weights, with no overlapping claim state. |
| AC-04 | Two concurrent pickup requests for one box yield exactly one carrier. |
| AC-05 | A carrier has at most one box; death/disconnect/reset clears carry and eventually restores availability. |
| AC-06 | Another player cannot unbox a box on an unowned plot or take actions in someone else's plot. |
| AC-07 | Unboxing one box grants exactly one correct-pool item; repeated remote calls do not duplicate rewards. |
| AC-08 | At full inventory, unboxing cannot consume a box or silently delete its reward. |
| AC-09 | A collectible can be displayed on only one owned stand at a time and removed without losing ownership. |
| AC-10 | Income accrues only from eligible displayed items during active online time; repeated claim calls cannot mint extra Bucks. |
| AC-11 | Upgrade purchases verify wallet/caps and persist; insufficient funds change nothing. |
| AC-12 | Bucks, inventory, display layout, and upgrades survive leave/rejoin and multiple-server handoff tests. |
| AC-13 | On failed persistent-data load, progression transactions are disabled (no silent overwrite of the saved profile). |
| AC-14 | Hunt/unbox/display/claim/upgrade flow is usable on keyboard-mouse and touchscreen. |
| AC-15 | No vending machine or gacha machine appears in the game or UI. |
| AC-16 | With 8 players exploring: no recurring script errors, lost item transactions, or severe mobile frame drops. |

---

## 17. Scope Summary

**IN (MVP):** Safezone, Urban, Slums · 8 plots · box pickup/carry · server spawn scheduler · secure unboxing · inventory · 14 collectibles · display stands · passive income · Money Collector · inventory + stand upgrades · HUD/tutorial/UI · DataStore persistence · desktop + mobile.

**OUT (MVP):** Mountain/Ocean/Space (P5) · vending machines · gacha/purchase machines · player-to-player trading · PvP/held-box stealing · selling/discarding items · offline income · wearables · shiny variants · full Collection Book · XP/levels/area gates · monetization · seasonal items.

---

## 18. Decision Log (initial state)

| Decision | Current working position | Owner / trigger |
|---|---|---|
| Meaning of "Steal" | World pickup; no player-held-item theft in MVP | Designer approval to add PvP |
| MVP active biome count | Urban + Slums | Expand after core loop works |
| Server players | 8 | Performance/playtest |
| Rarity odds | Per-biome box weights (section 5.5) | Balance testing |
| Per-tier reward loot tables | Data-driven; **not yet fully defined** | Content/balance author before final release |
| Economy rates & upgrade prices | Illustrative placeholders | Economy playtest |
| Inventory-full behavior | Block unbox before consume | QA edge-case verification |
| Item selling/deleting | Not in MVP | Economy/inventory product decision |
| Offline earnings | Not in MVP | Retention analysis |
| Player-to-player trading | Not in MVP | Security and abuse review |

Keep the live version in `DECISION_LOG.md`. Append every new assumption you make.

---

## 19. Open Questions the GDD Does Not Answer (agent: flag, don't guess silently)

> This section is NOT from the GDD. It lists gaps noticed while converting it. Pick the safest configurable default, log it, and ask the user when it blocks you.

1. **Does a displayed (placed) item count toward inventory capacity?** The GDD says inventory stores owned instance IDs and a placed instance is locked, but never states whether placed items occupy inventory slots. Make this a config flag.
2. **Starter loot tables** do not exist yet. Create clearly marked **placeholder** tables (data files, per `(biome, boxTier)`), and keep the separate-tier rule (a Legendary box can drop lower-rarity items).
3. **Item `incomePerSecond` per collectible** is only given as 3 example values (Common 2 / Rare 15 / Legendary 100). Uncommon, Epic, Secret values are undefined. Use configurable placeholders.
4. **Box tier ↔ spawn point `allowedTiers`**: the mapping of which tiers can appear at which points is not specified. Default: all tiers allowed, weighted by section 5.5.
5. **Pickup race vs. respawn cooldown:** `RETURN_PENDING` says "after respawn cooldown" while the scheduler gives 25–45 s after pickup/cleanup. Reuse the same configurable cooldown range unless told otherwise.
6. **Multi-server handoff (AC-12)** requires protection against two servers writing the same profile (session locking). The GDD names the requirement but not the mechanism. Propose one and log it.
7. **Money Collector capacity:** no cap on pending Bucks is specified. Default: uncapped, but expose a config knob.
8. **"Secret" tier** has no special rules beyond rarity. Treat it as the top tier with its own weights, skin, and emblem.

---

## 20. Appendix A — Starter Data Contracts
```text
BiomeConfig:           {id, displayName, worldOrder, unlockedForMVP, boundsTag, spawnPointTag,
                        maxActiveBoxes, respawnCooldownRange, tierWeights, environmentAssetId}
BoxDefinition:         {boxTypeId, biomeId, tier, modelKey, iconKey, lootTableKey, carryPresentationKey}
CollectibleDefinition: {itemId, name, biomeId, rarity, category, modelKey, iconKey,
                        incomePerSecond, displayable, wearable=false, vfxKey}
UpgradeDefinition:     {upgradeId, level, costBucks, newCapacity, prerequisites}
SpawnPoint:            {spawnId, biomeId, allowedTiers, weight, cooldownUntil, activeWorldBoxId}
```

## 21. Appendix B — References
- Securing the client-server boundary: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Data stores: https://create.roblox.com/docs/cloud-services/data-stores
- Data store best practices: https://create.roblox.com/docs/cloud-services/data-stores/best-practices

These support architecture/security guidance only. Items, gameplay, and balance are original design requirements.

---

## 22. Suggested First Task for the Agent

```
Start P0 (Foundation). Do NOT write gameplay logic yet.
1. Read this README fully and summarize your assumptions, dependencies, and any spec conflicts.
2. Propose the folder/module layout (section 12.1) as a Rojo-friendly tree.
3. Create config module stubs (Biomes, Boxes, Collectibles, Economy, Upgrades) using the contracts in Appendix A.
4. Create service stubs (Plot, Spawn, Carry, Unbox, Inventory, Display, Economy, Data).
5. Implement PlotService: 8 unique plots, assign on join, reclaim on leave (AC-01).
6. Create DECISION_LOG.md and log every assumption.
7. Report per section 0.3 / 0.4 before moving to P1.
``` 