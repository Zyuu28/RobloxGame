# STEAL A MYSTERY BOX!
## GAME DESIGN DOCUMENT | Production Specification v2.0
Roblox Multiplayer Simulator PC & Mobile

**Purpose:** implementation-ready reference for AI coding agents, vibe game engineers, environment builders, UI designers, and QA. Drafted from the agreed gameplay and linear-map concepts; proposed engineering defaults are explicitly identified.

| Control | Value |
| :--- | :--- |
| **Document owner** | Game design/engineering team |
| **Source of truth** | This GDD for MVP; changes require versioned design decisions |
| **Confirmed concept** | Mystery Box hunt, carry to plot, unbox, collect, display, earn, upgrade; five biomes; linear world |
| **Proposed defaults** | Player capacity, timers, numerical economy, loot odds, distances, upgrades |
| **Out of scope** | Vending machines, gacha purchase machines, trading in MVP |

### 0. Reading rules & design authority
*   **[LOCKED]** = agreed concept from the previous discussion. Do not change without explicit design approval.
*   **[PROPOSED]** = implement as configurable prototype default; game designer may adjust after testing.
*   **[POST-MVP]** = planned feature; do not silently build into the MVP.
*   If an unspecified detail is required to proceed, use the documented default, add it to Decision Log, and do not invent an incompatible core mechanic.
*   Use assets and code that the team has rights to use; inspiration from Steal an Egg! is a high-level map/progression reference, not permission to copy its assets or level geometry.

### 1. Product vision & game pillars
**[LOCKED]** Title: Steal a Mystery Box! Genre: multiplayer exploration + collection + unboxing + base tycoon. Target: casual / all ages. Platforms: Roblox desktop and mobile.
Player fantasy: "I spotted a rare box far from home, escaped with it, opened it in my plot, and earned a collectible I can proudly display."

| Pillar | Practical design test |
| :--- | :--- |
| **Visible discovery** | Boxes can be spotted from readable distance and found through exploration, not purchase. |
| **Risk & return** | Further biomes take longer to reach; returning with a box matters. |
| **Surprise & collection** | Unboxing reveals biome-themed items with meaningful rarity and visual identity. |
| **Home progression** | Displayed collectibles generate Bucks; upgrades improve capacity and convenience. |
| **Short-session clarity** | A new player understands the hunt-return-open-display loop without a tutorial wall. |

### 2. Locked gameplay loop
`EXPLORE (FASTER) → FIND → PICK UP ("STEAL" FROM WORLD) → ESCAPE BIOME MONSTERS → ENTER SAFEZONE → UNBOX → COLLECT (WEAR FOR SPEED BOOST & DISPLAY) → EARN BUCKS → UPGRADE (CAPACITY & SPEED) → REPEAT`

"Steal" is the game fantasy/title: picking up a Mystery Box in the biomes alerts Biome Monsters (Urban Security Drone, Scrap Junkyard Beast) who chase the carrier! The carrier must escape back to the Safezone. Monsters cannot cross the Safezone barrier. Inside the Safezone, the player is protected and can safely unbox their stolen Mystery Box. Stealing held boxes from other players is not implemented in MVP.

#### 2.1 First 10 minutes target experience
*   **00:00:** player spawns at assigned empty plot inside the protected Safezone.
*   **00:30:** player walks out into Urban and notices visible Mystery Boxes and patrolling Biome Monsters.
*   **01:00:** player picks up ("steals") a box, triggering monster pursuit; player sprints back to the Safezone.
*   **01:30:** player crosses the Safezone barrier; monsters disengage; player reaches plot safely.
*   **02:00:** plot interaction starts a short unboxing reveal and grants one collectible accessory.
*   **02:30:** player equips the accessory for an instant WalkSpeed boost, and places copies on display stands for Bucks.
*   **03:00+:** player claims Bucks at Money Collector, buys upgrades (Capacity & Speed), and explores farther with high speed.

### 3. World map: linear progression
**[LOCKED]** Layout order: SAFEZONE → URBAN → SLUMS → MOUNTAIN → OCEAN → SPACE. One traversable main corridor links all areas, with local detours, secrets, and landmarks inside each biome. All travel back to the Safezone remains possible.

| Zone | Visual theme | Traversal hook | Box theme | Release |
| :--- | :--- | :--- | :--- | :--- |
| **Safezone** | Bright landscaped plaza; 8 player plots, services | Protected hub; central spawn | No world boxes | MVP |
| **Urban** | Modern buildings, roads, rooftops | Open streets and alleys | Neon city | MVP |
| **Slums** | Colorful backstreets, workshop, junkyard | Tight alleys and scrap piles | Patchwork metal | MVP |
| **Mountain** | Pine slopes, crystal mine, caves | Cliffs, ramps, cave paths | Stone and crystal | Post-MVP |
| **Ocean** | Docks, coral, shipwrecks | Boardwalk + shallow/underwater route | Shell and coral | Post-MVP |
| **Space** | Asteroids, station, cosmic islands | Safe platforms/portals | Purple starfield | Post-MVP |

#### 3.1 Top-down route (schematic)
`[PLOTS/SHOPS/SPAWN] ==> [CITY] ==> [BACKSTREETS] ==> [HIGHLANDS] ==> [DEEP BLUE] ==> [GALAXY]`
**[PROPOSED]** Initial sizes (studs): Safezone 300x220; Urban 250x220; Slums 250x220; Mountain 275x220; Ocean 275x220; Space 250x220. World may be curved/offset for sightlines but must retain single clear progression axis. Walk-test traversal times, not dimensions, are the acceptance standard.

#### 3.2 World navigation rules
*   Main route remains legible using signage, color transitions, directional props, and view corridors.
*   No compulsory biome unlock gates in MVP; distant areas are expansion-only until built.
*   Do not teleport players into the next biome by default; Space portals are local traversal affordances only.
*   Players can carry one Mystery Box at a time. Jumping/walking is supported; no mandatory obby precision while carrying.
*   **Safezone Boundary & Forcefield:** The Safezone is a protected circular sanctuary (radius 85 studs from center). Biome Monsters cannot penetrate the Safezone perimeter.
*   **Steal & Pursuit Mechanic:** Stealing/carrying a Mystery Box outside the Safezone aggroes biome patrol monsters (Urban Security Drones, Scrap Junkyard Beasts). Monsters pursue the player; reaching the Safezone causes monsters to disengage. If caught, the carried box is dropped.
*   **Unboxing Deposit Rule:** Carried Mystery Boxes can ONLY be safely deposited and unboxed once the player has successfully entered the Safezone at their plot.
*   Biome-specific box spawning points must stay accessible and avoid inaccessible rooftops, buried geometry, or unsafe zones.

### 4. Safezone & player plots
| Object | MVP behavior |
| :--- | :--- |
| **Player Spawn** | Spawn inside Safezone; assign one vacant plot on join. |
| **8 Player Plots** | One per active player (proposed server cap = 8). Plot belongs to session user; saved layout reloads. |
| **Unboxing Area** | Place or interact with carried Mystery Box to open it. |
| **Display Stands** | Visible placed collectibles; passive Bucks generation. |
| **Money Collector** | Player explicitly claims accrued display earnings. |
| **General Shop** | Future or minimal flavor; no mystery-box vending/purchase. |
| **Upgrade Shop** | Buy inventory capacity, display-slot capacity, and **Walk Speed upgrades**. |
| **Collection Center** | [POST-MVP] full Collection Book; MVP may include simple discovered count. |

**[PROPOSED]** First plot layout: spawn entrance, unboxing pad, 3 free stands, one Money Collector and build/upgrade access. Plots are visited for viewing but cannot be modified by another player.

### 5. Mystery Box system

#### 5.1 Box types, tiers, and lifecycle
**[LOCKED]** Box rarity and collectible rarity are separate. Every box has biome, box tier, unique world-spawn ID, visual asset, loot-table ID, and state.

| State | Definition | Allowed transition |
| :--- | :--- | :--- |
| **AVAILABLE** | Anchored at valid spawn point | → CARRIED |
| **CARRIED** | Attached to a single player avatar | → UNBOXED or RETURN_PENDING |
| **RETURN_PENDING**| Carrier reset/death/disconnect; world object cleared | → AVAILABLE after respawn cooldown |
| **UNBOXED** | Reward transaction completed once | → DESPAWNED |
| **DESPAWNED** | No longer visible/interactable | → new instance at scheduled spawn |

**[PROPOSED]** One box per player; interaction via Proximity Prompt (desktop E / touch prompt) with 8-stud server-validated range and 0.4-second hold; carrying movement at **80% of current upgraded walk speed**; carrying box visually offsets in front of avatar, collisionless, non-droppable by button in MVP.
If a player dies, resets, teleports unexpectedly, leaves, or disconnects while carrying, the box is removed from their avatar and returned to its spawn point after cooldown. If the player reaches their assigned plot, only the plot owner can unbox it.

#### 5.2 Spawn scheduler
**[PROPOSED]** Each biome has spawn points tagged by biome, weights, and allowed tiers; scheduler operates on server. First MVP distribution: Urban 12 spawn points / max 6 boxes active; Slums 12 points / max 6 active.
**[PROPOSED]** At an occupied point no further box can spawn. After successful pickup or cleanup, cooldown 25-45 seconds randomized. No boxes spawn inside player plots or Safezone. All random rolls and spawn ownership are server-controlled. Server sends lightweight spawn state to clients; visuals render at safe distance with performance limits.

#### 5.3 Proposed box tier weights by biome
| Biome | Common | Uncommon | Rare | Epic | Legendary | Secret |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Urban** | 45% | 27% | 17% | 8% | 2.5% | 0.5% |
| **Slums** | 40% | 28% | 19% | 9% | 3% | 1% |
| **Mountain**| 35% | 27% | 21% | 11% | 5% | 1% |
| **Ocean** | 30% | 27% | 22% | 13% | 6% | 2% |
| **Space** | 25% | 25% | 23% | 15% | 9% | 3% |

*These are illustrative box-spawn tier probabilities taken from the design conversation, not final balancing. Sum to 100% in each biome. Reconcile actual availability with traversal distance during testing.*

### 6. Unboxing & reward generation
Only at the owner plot: interact with Unboxing Pad → server confirms valid carried box and owner plot → marks box as consumed and awards ONE eligible collectible according to box biome/tier loot table → server atomically saves → client displays 2-4 second reveal animation → item appears in inventory → box is destroyed.

Critical design rule: Legendary Mystery Box is NOT guaranteed to give a Legendary collectible. Lower-tier items may appear. All rewards are rolled on server, not locally.

| Step | Server-side check | Client feedback |
| :--- | :--- | :--- |
| **Start** | Owner plot, carried valid box, not already consumed | Unboxing progress and locked controls |
| **Roll** | Secure random weighted item entry from correct loot table | Suspense animation (cosmetic only) |
| **Commit** | Unique reward instance saved in session; box removed once | Rarity reveal, item name and image |
| **Inventory**| Capacity and overflow policy applied | Inventory updated or reward notice |
| **Fail** | No duplicate grant; box retained on retryable fault | Clear error/retry prompt |

**[PROPOSED]** Inventory full: unboxing blocked BEFORE consuming box, with "Inventory Full" UI. Do not silently discard rewards. Double-clicks, lagged remote calls, or disconnects must not duplicate grants.

#### 6.1 Loot table design
**[PROPOSED]** Loot table format is explicit per (biome, boxTier). Each row has itemId, positive integer weight, optional unlock rule, and rarity. Prototype may use broader shared pools within a biome but may not contradict the separate-tier rule. The full 6x5 tables must be authored in data files; NEVER use the biome spawn-tier percentages as collectible-drop probabilities.

### 7. Collectibles: identity and functionality
**[LOCKED]** Hybrid style: living objects, creatures, robots, artifacts, decorations, optional wearable accessories. Every collectible has ID, biome, rarity, model, icon, incomePerSecond, tags (Displayable/Wearable), optional FX, and Collection Book entry.

| Biome | Common | Uncommon | Rare | Epic | Legendary | Secret |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Urban** | Traffic Buddy / Soda Can | Mini Skyscraper | Street Bot | Golden Taxi | Cyberpunk DJ | City Guardian |
| **Slums** | Cardboard Buddy / Rusty Can| Tire Monster | Scrap Robot | Junkyard King | Street Phantom| Scrap Titan |
| **Mountain**| Pebble Pal / Mountain Goat| Crystal Bug | Eagle Scout | Crystal Golem | Baby Yeti | Ancient Mountain Beast|
| **Ocean** | Bubble Buddy / Baby Crab | Octo Pal | Treasure Chest Mimic| Coral Guardian| Abyssal Whale | Leviathan |
| **Space** | Baby Alien / Moon Buddy | Mini Satellite | Astro Bot | Nebula Slime | Cosmic Dragon | Galaxy Devourer |

The above lists are concept catalogs: 7 initial names per biome, including two Common examples, not the final 10 items/biome. MVP requires at least 7 Urban and 7 Slums collectible models with unique visual identities. Further items can be added data-first.

#### 7.1 Items and copies
*   Each reward creates a unique collectible instanceId; multiple duplicates of same itemId are allowed.
*   Inventory stores owned instance IDs. A placed instance cannot also be placed on another stand or sold/used simultaneously.
*   Display stand references instanceId, not just itemId. Server validates ownership at placement/removal.
*   **Equippable Wearables with Speed Boost:** All collectibles function as wearable accessories (`wearable = true`). Equipping an item grants an immediate **Walk Speed boost** based on rarity: Common (+2), Uncommon (+4), Rare (+7), Epic (+12), Legendary (+18), Secret (+25 studs/s). Equipping and unequipping is controlled directly from the Inventory UI.
*   [POST-MVP] Shiny variants, full Collection Book, collection completion rewards, seasonal items.

### 8. Economy, passive income, and upgrades
**[LOCKED]** Primary currency = Bucks ($); earnings generated by displayed collectibles and manually collected at a Money Collector.

| System | Proposed MVP default |
| :--- | :--- |
| **Free display stands** | 3 per plot |
| **Base inventory capacity** | 20 instances |
| **Base Bucks** | 0 (first collectible is free to obtain) |
| **Common income example** | 2 Bucks/s |
| **Rare income example** | 15 Bucks/s |
| **Legendary income example** | 100 Bucks/s |
| **Money Collector** | Claim pending earnings on interaction |
| **Tick calculation** | Calculate via server elapsed time; update HUD at low frequency |
| **Offline income** | OFF in MVP |
| **Sell/discard** | OFF in MVP unless an explicit safe replacement is approved |

Income values are illustrative, not a balanced economy. Economy designer must set each collectible's actual income value. Money Collector pending earnings are stored in session and saved persistently so reconnect does not erase legitimate accrued currency; only online elapsed income accrues.

#### 8.1 Proposed upgrades
| Upgrade | Level 0 (Base) | Level 1 | Level 2 | Level 3 |
| :--- | :--- | :--- | :--- | :--- |
| **Inventory capacity** | 20 | 30 / $150 | 45 / $500 | 65 / $1,500 |
| **Display stand capacity**| 3 | 4 / $250 | 5 / $850 | 6 / $2,500 |
| **Walk Speed (NEW)** | 16 (Roblox Default)| 24 / $200 | 35 / $750 | 50 / $2,000 |

Prices and capacity are [PROPOSED]. Purchase requires sufficient Bucks and level below cap. Server deducts currency and updates upgrade level exactly once. Upgrades persist across sessions and reinstantiate on plot load. Walk speed is applied directly to the character's Humanoid.

### 9. Player UX, UI and accessibility (PROGRAMMATIC UI GENERATION REQUIRED)
**[CRITICAL INSTRUCTION FOR AI AGENT]:** We do NOT have pre-made `.rbxm` or `.rbxmx` UI files. You **MUST** generate all UI elements programmatically using `Instance.new("ScreenGui")`, `Instance.new("Frame")`, `Instance.new("TextLabel")`, `Instance.new("TextButton")`, etc., inside the client controllers. The UI must auto-parent to `Player.PlayerGui` when the client boots.

| Screen / UI | Content | Trigger |
| :--- | :--- | :--- |
| **HUD** | Bucks available, pending Bucks, carried indicator, inventory button, **Speedometer (WalkSpeed stat)** | Always visible |
| **Box Prompt** | "Pick up [Tier] [Biome] Mystery Box" | Near available box |
| **Unboxing UI** | Box identity, opening sequence, item rarity reveal | Owner plot unbox |
| **Inventory** | Grid, filters by biome/rarity, capacity, place action | HUD button |
| **Plot Mode** | Stand select, place/remove item, current income | At owned plot |
| **Upgrade Shop**| Current level, next benefit, price, purchase button (Includes **Speed Upgrades**) | Near shop / UI |
| **Feedback** | Full inventory, invalid interaction, success/failure | On relevant events |

**Mobile & Controls Support:**
*   **Movement (Joystick):** Do NOT script a custom joystick; rely entirely on Roblox's built-in Dynamic Thumbstick for mobile movement.
*   **Touch Targets:** Generate mobile-friendly UI with 44+ logical-pixel-like touch targets where feasible.
*   **Inputs:** Interaction prompts must use Roblox-supported input UI (e.g., `ProximityPrompt` which automatically supports mobile tap).
*   **Accessibility:** No keyboard-only interactions; every action must have an on-screen button. UI readability takes priority over animation. Avoid flashing effects and allow reduced FX where possible.

### 10. Player onboarding & session progression
*   New user sees a three-step guided instruction: Find a box → Bring it home → Open & Display.
*   Guide arrow points to nearest Urban box initially; tutorial does not spawn duplicate rewards.
*   Completion checks happen on server, are persisted, and should not repeat after rejoin.
*   MVP does not require Level/XP or area unlock gates. [POST-MVP] levels and area access can be implemented as separate systems.

### 11. Multiplayer and game rules
*   **[PROPOSED]** 8 players per server, eight plots. Plot assignment is one-to-one and stable within a session; reclaim free plots when players leave. If plot capacity reached, rely on server player cap rather than overlapping assignments.
*   Two players interacting with the same box: first server-authorized pickup wins; loser receives already-taken feedback.
*   Other players can tour plots but cannot unbox, move, claim earnings, or upgrade the owner plot.
*   No PvP combat, player-held-box stealing, or griefing in MVP.
*   Plot/stand data ownership is never inferred from visual client labels.
*   When a player leaves, their transient world box resets; permanent player data is saved; display layout persists for next login.

### 12. Roblox technical architecture
Recommended architecture: Luau + server-authoritative services and ModuleScripts. No client authority over rewards, money, ownership, rare drops, carry state, or saves. Reusable data definitions should reside in ReplicatedStorage; secrets or trusted mutation logic in ServerScriptService.

| Location | Suggested modules / objects |
| :--- | :--- |
| **ReplicatedStorage/Shared** | Configs/Biomes.lua, Boxes.lua, Collectibles.lua, Economy.lua, Upgrades.lua; Remotes |
| **ServerScriptService/Services**| PlotService, SpawnService, CarryService, UnboxService, InventoryService, DisplayService, EconomyService, DataService, SpeedService, MonsterService |
| **ServerStorage/Assets** | MysteryBoxModels, CollectibleModels, PlotPrefabs |
| **StarterPlayerScripts/Controllers**| InteractionController, InventoryController, UnboxController, HUDController |
| **Workspace/World** | Safezone, Biomes/Urban, Biomes/Slums, Tags/SpawnPoints, PlayerPlots |

Use CollectionService tags or equivalent metadata for spawn points, display stands, and interaction pads. Use central authoritative validation functions to avoid duplicating security logic.

#### 12.1 Proposed remote interface
| Remote (direction) | Input | Server contract |
| :--- | :--- | :--- |
| **RequestPickup** (C→S) | worldBoxId | Validate world instance exists, free, player distance, not carrying |
| **RequestUnbox** (C→S) | plotId | Validate assigned owner and held box, inventory capacity, safezone boundary; single grant |
| **RequestDisplay** (C→S)| instanceId, standId | Validate item ownership, stand ownership, no duplicate placement |
| **RequestUndisplay** (C→S)| standId | Validate owner; return instance to inventory |
| **RequestEquip** (C→S)  | instanceId | Validate item ownership, wearable tag, equip accessory, and apply Speed Boost |
| **RequestUnequip** (C→S)| instanceId | Validate item ownership, unequip accessory, and reset Speed Boost |
| **RequestClaim** (C→S) | plotId | Validate owner, transfer pending to wallet once |
| **RequestUpgrade** (C→S)| upgradeId | Validate price, level, wallet; commit once **(Updates WalkSpeed dynamically if applicable)** |
| **StateUpdate** (S→C) | filtered state delta | Read-only status, balances, inventory, FX triggers, **current WalkSpeed** |

Names are suggestions; UI must not directly alter replicated values as a source of truth. Include rate limits, type validation, distance/ownership checks, monotonic transaction IDs, and replay protection.

#### 12.2 Data schema v1 (illustrative)
`PlayerProfile = {schemaVersion=1, bucks=0, pendingBucks=0, inventoryCapacityLevel=0, displayCapacityLevel=0, walkSpeedLevel=0, inventory={[instanceId]={itemId, obtainedAt, variant}}, displaySlots={[slotId]=instanceId}, discoveries={[itemId]=true}, tutorial={...}, lastSavedAt=timestamp}`

Temporary session-only state = `{assignedPlotId, carryingWorldBoxId, interactionCooldowns, lastEconomyTick, pendingTransactions}`; do not persist a carried world box.

Use DataStoreService for persistence; protect operations with pcall/retry and UpdateAsync where appropriate. Provide schema migration; avoid overwriting good data after failed loads.

#### 12.3 Security, performance, resilience
*   Authoritative server controls weighted rolls, world box claims, economy calculation, upgrades, and persistence.
*   ProximityPrompt/RemoteEvent triggers must be validated server-side: client-visible distances or prompt settings alone are insufficient.
*   Unbox is an idempotent server transaction: one carried box creates at most one collectible instance.
*   Persist using bounded retries; on failed profile load block mutations and show a retry/leave message rather than creating disposable data.
*   Do not save every second: batch timed/meaningful saves, saving on leave and shutdown within platform constraints.
*   Prefer anchored models, simple collisions, and client-side VFX; apply streaming/performance tests on low-end mobile.
*   Instrument errors and metrics: pickup failures, unbox failures, save failures, dupes, earning anomalies, and server tick time.

### 13. Content production & art direction
Stylized colorful low-poly Roblox aesthetics. Box shape remains immediately recognizable as a cube; distinctive biome patterns: Urban neon/blue, Slums patched orange metal, Mountain rock/crystal green, Ocean blue shell/coral, Space purple nebula/starfield. Tier is signaled through glow, emblem, audio, and readable text; never rely on color alone.

| Asset type | MVP minimum | Definition of done |
| :--- | :--- | :--- |
| **World geometry** | Safezone + Urban + Slums | Playable traversal, clear landmarks, no inaccessible spawn spots |
| **Mystery box models**| 2 biome variants x 6 tier skins | Consistent pivot, prompt attachment, LOD/readability |
| **Collectible models**| 14 named unique items (7/biome) | Readable silhouettes, stand compatible, icons present |
| **Plot kit** | 1 plot model repeated x 8 | Spawn, unbox pad, 3 starting stands, money collector |
| **UI** | HUD, Inventory, Reveal, Shop, Errors | Desktop/mobile tested |
| **Sound/VFX** | Pickup, reveal, rarity sting, claim | No copyrighted borrowed media; optimized |

### 14. Monetization and responsible design
**[POST-MVP]** Optional cosmetic passes, special effects, plot decoration, event cosmetics; temporary boosts only after balance and purchase validation. Do not sell basic usability or introduce misleading loot odds. If paid randomized rewards are later introduced, re-evaluate platform policy and disclosure requirements; not part of this MVP.

### 15. Build plan and milestone deliverables
| Phase | Deliverables | Exit condition |
| :--- | :--- | :--- |
| **P0: Foundation** | Place structure, configs, data schema, service stubs, test harness | Game starts with 8 unique plots and no runtime errors |
| **P1: World & spawning**| Safezone + Urban/Slums; spawn scheduler, 2 box designs | Server spawns eligible boxes; pickup race is safe |
| **P2: Loop** | Carry to plot; secure unbox; inventory x 14 collectibles | New player can obtain and retain an item |
| **P3: Economy & Speed**| Place/removal on stands, passive generation, collector, upgrades (Capacity & Speed) | Income, balances, and player WalkSpeed consistent and persistent |
| **P4: UX, save & polish**| UI, tutorial, effects, error handling, DataStore, mobile | All acceptance tests pass with multiple players |
| **P5: Expansion** | Mountain, Ocean, Space and additional catalogs | Separate release scope and playtest |

### 16. MVP acceptance criteria (must all pass)
*   **AC-01:** Eight simultaneous players receive distinct plots; ninth does not overlap a plot (server cap = 8).
*   **AC-02:** No Mystery Box spawns in Safezone or inside a plot.
*   **AC-03:** Urban and Slums boxes spawn according to configured points and weights, with no overlapping claim state.
*   **AC-04:** Two concurrent pickup requests for one box yield exactly one carrier.
*   **AC-05:** A carrier has at most one box; death/disconnect/reset clears carry and restores availability. Carrying speed is reduced to 80% of current WalkSpeed.
*   **AC-06:** Another player cannot unbox a box on an unowned plot or take actions in someone else's plot.
*   **AC-07:** Unboxing one box grants exactly one correct-pool item; repeated remote calls do not duplicate rewards.
*   **AC-08:** At full inventory, unboxing cannot consume a box or silently delete its reward.
*   **AC-09:** A collectible can be displayed on only one owned stand at a time and removed without losing ownership.
*   **AC-10:** Income accrues only from eligible displayed items during active online time; repeated claim calls cannot mint extra Bucks.
*   **AC-11:** Upgrade purchases (including Speed) verify wallet/caps, apply dynamically, and persist; insufficient funds do not change balances.
*   **AC-12:** Bucks, inventory, display layout and upgrades survive leave/rejoin and multiple-server handoff tests.
*   **AC-13:** On failed persistent-data load, progression transactions are disabled (no silent overwrite of saved profile).
*   **AC-14:** Basic hunt/unbox/display/claim/upgrade flow is usable on keyboard-mouse and touchscreen.
*   **AC-15:** No vending machine or gacha machine appears in game or UI.
*   **AC-16:** With 8 players actively exploring, there are no recurring script errors, lost item transactions, or severe mobile frame drops.
*   **AC-17:** Speedometer HUD accurately reflects the player's current WalkSpeed.

### 17. AI / vibe engineering instructions
**Instruction to execution agent:** Treat this GDD as the contract. Implement only MVP scope unless an explicit change request approves expansion. Work feature-by-feature, not all systems in one monolithic script. Always keep the place playable.

*   **UI CREATION RULE:** Immediately create a `UIManager` or update `HUDController.luau` to script the visual UI elements from scratch using `Instance.new()`. Do not wait for `.rbxm` files. Apply stylized colorful aesthetics (colors, padding, CornerRadius, UIStroke) directly in the Luau code.
*   Before writing code: summarize assumptions; cross-check dependencies; identify any spec conflicts.
*   Create modular Luau files and configuration tables; ensure no hardcoded values buried inside gameplay controllers.
*   For every module deliver: source path, public API, remote interface, security checks, test instructions, and configuration knobs.
*   Implement authoritative server transaction paths before UI polish. Never let the client choose the rarity, item, or money amount.
*   Include automated/unit-like tests where practical and a two-player manual regression scenario.
*   Do not fabricate completed assets or claim features are functional without testing them in Roblox Studio.
*   After each phase: report built files, known bugs, acceptance criteria passed, and deferred features.
*   If source constraints are ambiguous, use [PROPOSED] values and surface them in a decision log.

### 18. Open design decisions / decision log
| Decision | Current working position | Owner/trigger |
| :--- | :--- | :--- |
| **Meaning of "Steal"** | World pickup; no player-held-item theft in MVP | Designer approval to add PvP |
| **MVP active biome count**| Urban + Slums | Expand after core loop works |
| **Server players** | 8 | Performance/playtest |
| **Rarity odds** | Per-biome box weights listed above | Balance testing |
| **Per-tier reward loot tables**| Data-driven; not yet fully defined | Content/balance author before final release |
| **Economy rates and upgrade prices**| Illustrative placeholders | Economy playtest |
| **Inventory full behavior** | Block unbox before consume | QA edge-case verification |
| **Item selling/deleting** | Not in MVP | Economy/inventory product decision |
| **Offline earnings** | Not in MVP | Retention analysis |
| **Player-to-player trading**| Not in MVP | Security and abuse review |

### APPENDIX A. Machine-readable starter data contracts
*   **BiomeConfig:** `{id, displayName, worldOrder, unlockedForMVP, boundsTag, spawnPointTag, maxActiveBoxes, respawnCooldownRange, tierWeights, environmentAssetId}`
*   **BoxDefinition:** `{boxTypeId, biomeId, tier, modelKey, iconKey, lootTableKey, carryPresentationKey}`
*   **CollectibleDefinition:** `{itemId, name, biomeId, rarity, category, modelKey, iconKey, incomePerSecond, displayable, wearable=false, vfxKey}`
*   **UpgradeDefinition:** `{upgradeId, level, costBucks, newCapacity, prerequisites}`
*   **SpawnPoint:** `{spawnId, biomeId, allowedTiers, weight, cooldownUntil, activeWorldBoxId}`

### APPENDIX B. External technical references
*   Roblox Creator Hub
*   Securing the client-server boundary: https://create.roblox.com/docs/scripting/security/client-server-boundary
*   Roblox Creator Hub
*   Roblox Creator Hub
*   Data stores: https://create.roblox.com/docs/cloud-services/data-stores
*   Data store best practices: https://create.roblox.com/docs/cloud-services/data-stores/best-practices

Note: technical references support architecture and security guidance; item lists, gameplay, and balancing are original design requirements, not claims sourced from these documentation links.