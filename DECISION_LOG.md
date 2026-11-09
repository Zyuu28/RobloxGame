# DECISION LOG — Steal a Mystery Box!

> **Purpose:** Record every assumption, design default, and spec-conflict resolution made during development. Each entry is immutable once written; superseded decisions are marked but never deleted.
>
> **Rule:** If the GDD and this log disagree, the GDD wins. If neither covers a case, the most recent ACTIVE decision here is the working default until the designer overrides it.

---

## Format

| Field | Description |
|---|---|
| **ID** | `D-XXX` (sequential) or `D-OQn` (Open Question resolution) |
| **Date** | ISO 8601 |
| **Decision** | What was decided |
| **Rationale** | Why this default was chosen |
| **Status** | `ACTIVE` / `SUPERSEDED by D-XXX` |

---

## GDD §18 — Initial Decisions (imported)

| ID | Date | Decision | Rationale | Status |
|---|---|---|---|---|
| D-001 | 2026-11-07 | "Steal" = world pickup only; no player-held-item theft in MVP | GDD §2 [LOCKED]. PvP needs separate approved design. | ACTIVE |
| D-002 | 2026-11-07 | MVP active biomes = Urban + Slums only | GDD §3.1 table. Expand after core loop proven. | ACTIVE |
| D-003 | 2026-11-07 | Server player cap = 8 | GDD §11 [PROPOSED]. Matches 8 plots. | ACTIVE |
| D-004 | 2026-11-07 | Box spawn tier weights per GDD §5.5 | [PROPOSED] illustrative values. Subject to balance testing. | ACTIVE |
| D-005 | 2026-11-07 | Per-tier reward loot tables = data-driven, not yet fully defined | Placeholder tables created; content author fills before release. | ACTIVE |
| D-006 | 2026-11-07 | Economy rates & upgrade prices = illustrative placeholders | GDD §8 [PROPOSED]. Economy playtest will tune. | ACTIVE |
| D-007 | 2026-11-07 | Inventory-full behavior: block unbox BEFORE consuming the box | GDD §6 [PROPOSED]. Never silently discard rewards. | ACTIVE |
| D-008 | 2026-11-07 | Item selling/deleting = NOT in MVP | GDD §8 explicit exclusion. | ACTIVE |
| D-009 | 2026-11-07 | Offline earnings = NOT in MVP | GDD §8 [LOCKED OFF]. | ACTIVE |
| D-010 | 2026-11-07 | Player-to-player trading = NOT in MVP | GDD §17 OUT scope. Security and abuse review needed. | ACTIVE |

---

## GDD §19 — Open Question Resolutions

| ID | Date | Decision | Rationale | Status |
|---|---|---|---|---|
| D-OQ1 | 2026-11-07 | Displayed (placed) items do NOT count toward inventory capacity. Config flag `displayedCountsAsInventory = false` in EconomyConfig. | Safer default: placing items on stands should feel like a reward, not a penalty. Easily toggled if designer prefers otherwise. | ACTIVE |
| D-OQ2 | 2026-11-07 | Starter loot tables created as placeholder data files per (biome, boxTier). Clearly marked `[PLACEHOLDER]`. All tiers can drop lower-rarity items per the separate-tier rule. | GDD §6.1 requires explicit tables. Placeholder structure lets gameplay work while content author fills real values. | ACTIVE |
| D-OQ3 | 2026-11-07 | Income per second by rarity: Common=2, Uncommon=5, Rare=15, Epic=40, Legendary=100, Secret=250. Stored in EconomyConfig.defaultIncomeByRarity and per-item in CollectiblesConfig. | Interpolated from GDD §8 examples (Common=2, Rare=15, Legendary=100). Uncommon/Epic/Secret values fill the geometric-ish progression. | ACTIVE |
| D-OQ4 | 2026-11-07 | All spawn points allow all tiers, weighted by BiomesConfig.tierWeights per biome. No per-point tier restriction in MVP. | GDD does not specify per-point restrictions. Simplest correct default; can add point-level filtering later. | ACTIVE |
| D-OQ5 | 2026-11-07 | RETURN_PENDING cooldown reuses the same configurable respawnCooldownRange (25–45s) from the spawn scheduler. | GDD §5.2 says "after respawn cooldown" and §5.4 gives 25–45s. Same concept, same config knob avoids confusion. | ACTIVE |
| D-OQ6 | 2026-11-07 | Multi-server session locking via `UpdateAsync` with a session GUID. On load, write a server-specific GUID. On save, verify the GUID matches before writing. If another server has claimed the profile, block mutations and prompt the player to rejoin. | Standard Roblox pattern for preventing dual-server overwrites. Satisfies AC-12 requirement. | ACTIVE |
| D-OQ7 | 2026-11-07 | Money Collector pending Bucks = uncapped. Config knob `pendingBucksCap = nil` in EconomyConfig. Set to a number to enable cap. | GDD specifies no cap. Exposing the knob satisfies future tuning needs without building cap logic prematurely. | ACTIVE |
| D-OQ8 | 2026-11-07 | "Secret" tier is the top tier with its own weights, skin, and emblem. No special mechanics beyond rarity. | GDD §19 item 8 confirms no special rules. Treat as highest tier in weight tables and visual hierarchy. | ACTIVE |

---

## P0 Architecture Decisions

| ID | Date | Decision | Rationale | Status |
|---|---|---|---|---|
| D-P0-01 | 2026-11-07 | Service lifecycle: two-phase Init() → Start(). Init sets up internal state; Start connects events and cross-service calls. | Prevents circular dependency during initialization. Standard pattern in Roblox service architectures. | ACTIVE |
| D-P0-02 | 2026-11-07 | Service init order: DataService → PlotService → InventoryService → SpawnService → CarryService → DisplayService → EconomyService → UnboxService. | Dependency graph: each service only depends on services initialized before it. DataService is foundation; PlotService has no deps; later services reference earlier ones. | ACTIVE |
| D-P0-03 | 2026-11-07 | PlotService uses direct function calls (not BindableEvents) for OnPlayerAdded/OnPlayerRemoving. Main server script orchestrates. | Simpler, synchronous, debuggable. BindableEvents add indirection without benefit at this scale. Can be refactored if event-driven architecture is needed later. | ACTIVE |
| D-P0-04 | 2026-11-07 | Plot IDs are string-based ("Plot_1" through "Plot_8") rather than numeric indices. | String IDs are more readable in logs and can be used as Workspace object names. Avoids off-by-one confusion. | ACTIVE |
| D-P0-05 | 2026-11-07 | PlayerPlotMap keyed by UserId (number), not Player object reference. | Player objects can become invalid after leave. UserId is stable and works with Players:GetPlayerByUserId() for reverse lookup. | ACTIVE |
| D-P0-06 | 2026-11-07 | Config modules use exported Luau types for IDE autocompletion and type checking. | `--!strict` mode + exported types catch errors at edit time. Minimal runtime cost. | ACTIVE |
| D-P0-07 | 2026-11-07 | Old `src/main.server.luau` (Rojo test script) removed. Server bootstrap moved to `src/server/main.server.luau`. | Clean project structure per GDD §12.1. The test script's purpose (Baseplate color change) is no longer needed. | ACTIVE |
| D-P0-08 | 2026-11-07 | Remotes folder created in Rojo project as an empty Folder (runtime-created RemoteEvents/RemoteFunctions). Not file-backed. | RemoteEvents must be Roblox instances, not ModuleScripts. Services will create them in Init() when needed (P1+). | ACTIVE |
| D-P0-09 | 2026-11-07 | ServerStorage/Assets subfolders (MysteryBoxModels, CollectibleModels, PlotPrefabs) are empty Rojo folders. Actual assets are placed in Roblox Studio. | Assets are .rbxm files or Studio-created models. Rojo maps the container; artists populate it in Studio. Code references assets by name/key. | ACTIVE |

---

## UI & Architecture Decisions (read2.md update)

| ID | Date | Decision | Rationale | Status |
|---|---|---|---|---|
| D-UI-01 | 2026-11-07 | Programmatic UI Generation via `UIManager.luau`. All UI elements (`ScreenGui`, `Frame`, `TextButton`, `TextLabel`, `ScrollingFrame`) are generated in Luau code using `Instance.new()`. | GDD §9, §17: No pre-made `.rbxm` files exist; code creates the entire UI automatically on player join. | ACTIVE |
| D-UI-02 | 2026-11-07 | Mobile Touch Targets >= 44x44 logical px across all interactive elements (Claim, Inventory, Shop, Upgrade, Unbox, Close). | GDD §9 requirement for mobile ergonomics and Roblox guidelines. | ACTIVE |
| D-UI-03 | 2026-11-07 | Movement & Input Accessibility: Relies exclusively on Roblox's built-in Dynamic Thumbstick for mobile; no custom joystick scripted. ProximityPrompts used for all world interactions. | GDD §9 requirement: prevents conflicting input scripts and guarantees cross-platform support. | ACTIVE |
| D-UI-04 | 2026-11-07 | Screen Safe Zones: Bottom-left (movement thumbstick) and bottom-right (jump button) kept completely free of UI buttons. | Prevents accidental UI touches during gameplay on mobile devices. | ACTIVE |
| D-UI-05 | 2026-11-07 | Sliding Toast Notification Banner at top of screen for non-blocking feedback (errors, full inventory, claims, upgrades). | Provides clear feedback without intrusive popups that block traversal. | ACTIVE |
| D-FIX-01 | 2026-11-07 | Replication Race Condition Fix: `main.client.luau` and `main.server.luau` updated to use `WaitForChild` instead of `FindFirstChild`. | Prevents fatal `attempt to require a nil value` crashes during startup replication in Studio/production. | ACTIVE |
| D-FIX-02 | 2026-11-07 | Self-Healing Network Remotes: Created `src/shared/Network.luau` which automatically initializes RemoteEvents on server and provides safe accessors on client. | Eliminates missing RemoteEvent errors and ensures typed remote access. | ACTIVE |
| D-FIX-03 | 2026-11-07 | Client Plot Attribute Replication: `PlotService` sets `player:SetAttribute("AssignedPlot", plotId)` on join/leave. | Allows client controllers and UI to reactively know their assigned plot with zero latency. | ACTIVE |
| D-FIX-04 | 2026-11-07 | Procedural Physical Plots: `PlotService` builds 8 physical 3D plots in `Workspace.World.PlayerPlots` (with Base Ground, Billboard labels, Unbox Pad, Money Collector, and 3 Display Stands). | Makes the game world physically functional and immediately testable in Roblox Studio. | ACTIVE |
| D-FIX-05 | 2026-11-07 | Procedural Biomes & World Boxes: `SpawnService` generates Urban & Slums ground areas and sample Mystery Boxes with ProximityPrompts. | Satisfies AC-02, AC-03, AC-04; allows testing the complete hunt-carry-unbox-collect loop. | ACTIVE |
| D-UI-06 | 2026-11-07 | Desktop Keyboard Shortcuts & Visual Keybind Badges: [E] or [B]/[I]/[Tab] toggles Inventory, [U] toggles Upgrade Shop, [C] claims Bucks, [ESC] closes modals. | User request for PC/Laptop keyboard shortcuts. | ACTIVE |
| D-UI-07 | 2026-11-07 | Key Disambiguation (Separation of In-World Interacts vs Menus): Unbox Pad and Box Pickups use [F] (`KeyboardKeyCode = Enum.KeyCode.F`), while Inventory exclusively uses [E]. Eliminates any key overlap or ambiguity between unboxing and opening inventory. | User request to differentiate shared/clashing keys at the unboxing pad. | ACTIVE |
| D-UI-08 | 2026-11-07 | Hub-and-Spoke Interactive World Map Modal (`[M]` keybind & button): Programmatic UI modal directly mirroring `WorldMapV1.png` with central circular Safezone (8 plot indicators + "Track My Plot") and 5 radial biome sector nodes (Urban, Slums, Mountain, Space, Ocean). | Implements WorldMapV1.png visual navigation structure per user creative directive. | ACTIVE |
| D-UI-09 | 2026-11-07 | Real-time Biome & Waypoint Radar Bar on HUD: Live sector tracking (`SAFEZONE`, `URBAN`, `SLUMS`) and distance display to active waypoints. Automatically guides the carrier back to their assigned plot when holding a mystery box. | GDD §10 onboarding and navigation clarity. | ACTIVE |
| D-MAP-01 | 2026-11-07 | 3D World Geometry Hub-and-Spoke Realignment: Plots in `PlotService.luau` repositioned in a radial circle around the central Player Spawn Plaza (`R = 64 studs`), with radiating roads leading out to the 5 biomes. | Matches WorldMapV1.png hub-and-spoke layout. | ACTIVE |
| D-FIX-06 | 2026-11-07 | CarryService Character Hook Fix: Hooked `CharacterAdded` and `Humanoid.Died` for existing players present before service start, preventing dropped death cleanup in Studio. | Prevents ghost carried box instances on player reset. | ACTIVE |
| D-FIX-07 | 2026-11-07 | DisplayService Cleanup on Player Leave: Added `DisplayService.OnPlayerRemoving(player)` to clear `plotStands` and visual preview models when a player disconnects. | Prevents old player items from persisting on reclaimed plots. | ACTIVE |
| D-FIX-08 | 2026-11-07 | UnboxService Distance Exploitation Guard: Added server-side check verifying player is within 22 studs of their plot's UnboxPad before processing unbox. | Security check per GDD §12.1. | ACTIVE |
| D-BOX-01 | 2026-11-07 | Single Mystery Box per Biome Architecture: Each biome contains exactly ONE type of Mystery Box (e.g. "Urban Mystery Box", "Slums Mystery Box") spawned in the world. Box tier rarities are NOT spawned as separate world boxes; instead, the random chance roll for item rarities (Common to Secret) occurs inside the box when unboxed on the player's plot pad via LootTablesConfig. | User clarification: eliminates separate tier boxes in the world, restores true mystery box excitement where any box from a biome can roll Common through Secret. | ACTIVE |
| D-SPEED-01 | 2026-11-08 | Authoritative Walk Speed Upgrades & Speedometer HUD: Implemented `SpeedService.luau` handling 4 walk speed tiers (16, 24, 35, 50 studs/s) and dynamic 80% slowdown when carrying boxes (`baseSpeed * 0.80`). Added bottom-center Speedometer gauge HUD and Walk Speed upgrade card in Upgrade Shop modal. Satisfies AC-05, AC-11, and AC-17. | read2.md update for Simulator game loop (UPGRADE CAPACITY & SPEED). | ACTIVE |
| D-FIX-09 | 2026-11-08 | Fixed Hardcoded WalkSpeed Bug in CarryService: `CarryService.luau` previously set `humanoid.WalkSpeed = 16 * 0.80` and `humanoid.WalkSpeed = 16` unconditionally, breaking upgraded speeds. Replaced with authoritative calls to `SpeedService.ApplySpeed(player)`. | Bug fix for upgrade persistence and dynamic carry speed calculation. | ACTIVE |
| D-SAFEZONE-01 | 2026-11-08 | Safezone Barrier & Biome Monster Pursuit System: Created `MonsterService.luau` managing a protected Safezone forcefield perimeter (`R = 85 studs`) and patrolling Biome Monsters (Urban Security Drones & Scrap Junkyard Beasts). Picking up a Mystery Box in a biome triggers high-aggro pursuit; monsters chase carriers but CANNOT cross into the Safezone. Unboxing requires being inside the Safezone; being caught outside knocks the player back and drops the box. | User requirement: creates the thrill of "Steal & Escape to the Safezone". | ACTIVE |
| D-ACCESSORY-01 | 2026-11-08 | Wearable Collectible Accessories with Speed Boost: All collectibles configured as wearable accessories (`wearable = true`) with direct Walk Speed boosts (`speedBoost`) scaling from +2 (Common) to +25 (Secret). Integrated into `InventoryService.luau`, `SpeedService.luau`, and Inventory UI with dual action buttons (`EQUIP / UNEQUIP` and `STAND / REMOVE`). | User requirement: unboxed gacha collectibles provide usable speed advantages to outrun monsters. | ACTIVE |
| D-UI-10 | 2026-11-08 | Minimal Modern Simulator HUD Redesign: Redesigned HUD layout to match modern Roblox simulators (Steal an Egg! reference). 1) Left Edge: Vertical stack of action pills (`[🛒 Shop [U]]`, `[🎒 Bag [E]]`, `[🗺️ Map [M]]`). 2) Right Edge: Quick square action buttons (`[📦 Bag]`, `[🧭 Map]`). 3) Bottom-Left: Compact stats panel (Speedometer `⚡ 16.0 studs/s` + mini level bar, `💵 $0 Bucks`, pending earnings, `[CLAIM]` button, and plot badge). 4) Center Viewport: 100% clean and unobstructed. Top bar clutter eliminated; `Box: None` badge removed; carried box banner is dynamic and ONLY visible when holding a stolen box (`Visible = false` when idle). 5) Compact toast notifications. | User request: eliminates HUD clutter and overlap, delivers clean modern simulator UI/UX. | ACTIVE |
| D-ROBUX-01 | 2026-11-08 | Robux Exclusive Store & Button Differentiation: 1) Replaced redundant inventory button on the right edge with a dedicated Robux Store button (`[💎]`) positioned directly above the Track Biome compass button (`[🧭]`). 2) Created programmatic `RobuxShopModal` containing 6 Robux-exclusive items (VIP Gamepass, Super Speed Coil, 2x Bucks Multiplier, +50 Inventory Slots, 2,500 Bucks Bundle, 10,000 Bucks Mega-Bundle) with `MarketplaceService` prompt integration. 3) Renamed left menu button to `[⬆️ Upgrades]` to clearly separate in-game Bucks upgrades from Robux purchases. | User requirement: differentiate left/right menus and add dedicated Robux-only store above track biome. | ACTIVE |

---

*Last updated: 2026-11-08 (Robux Exclusive Store Integration)*


## D-SAFEZONE-02: Enlarge Safezone Radius (85 → 120 studs)
- **Date:** 2026-11-08
- **Rationale:** Previous radius (85 studs) was too tight against plot borders (plots at R=64). Enlarged to 120 studs for comfortable margin.
- **Files:** `MonsterService.luau` (SAFEZONE_RADIUS constant), barrier ring segments increased from 16 to 24 for smoother circle.

## D-MONSTER-02: Per-Player Chase Monster (No Patrol)
- **Date:** 2026-11-08
- **Rationale:** Previous system spawned multiple patrol monsters at game start. New design: 1 monster per player, spawns ONLY when player picks up a Mystery Box from a single fixed point per biome. Monster despawns when: player enters Safezone, player drops box, or player is caught.
- **Files:** `MonsterService.luau` (complete rewrite), `CarryService.luau` (integrated SpawnChaseMonster/DespawnMonster calls).

## D-DROPBOX-01: Drop Box Feature ([Q] Key / Button)
- **Date:** 2026-11-08
- **Rationale:** Players need ability to voluntarily drop carried Mystery Box to escape monsters. Dropped box appears on ground for 15 seconds (visible to all), then despawns.
- **Files:** `Network.luau` (added RequestDropBox event), `CarryService.luau` (added DropBox function), `main.server.luau` (wired remote event), `HUDController.luau` (added [Q] hotkey), `UIManager.luau` (added DROP button in carried box alert banner).

## D-MONSTER-03: Guardian Monsters on Standby, Chase on Theft, Return or Retarget
- **Date:** 2026-11-08
- **Rationale:** User requested monsters be physically stationed on standby at 1 fixed point per biome. When a Mystery Box is stolen, the guardian wakes up and chases the carrier. When the box is dropped or the carrier enters Safezone, the monster checks if another player is carrying a box outside Safezone (retargets to them); if not, it smoothly walks back (RETURNING) to its standby post and resumes guarding.
- **Files:** `src/server/services/MonsterService.luau` (full autonomous FSM: STANDBY -> CHASING -> RETURNING -> STANDBY).

## D-DROPBOX-02: Interactive World Dropped Boxes with Re-pickup & Prompt
- **Date:** 2026-11-08
- **Rationale:** Dropped boxes now spawn as interactive world instances with `ProximityPrompt` (`[F]` Pick Up Dropped Box). Any player can pick it up. Upon pickup, the monster immediately resumes pursuit. If not picked up within 60 seconds, it cleanly auto-despawns.
- **Files:** `src/server/services/SpawnService.luau` (`SpawnDroppedBox` & atomic pickup claim without respawn), `src/server/services/CarryService.luau` (`DropBox` integration).
