# STEAL A MYSTERY BOX! - UI DESIGN & PROGRAMMATIC GENERATION GUIDE
**Purpose:** This document is the strict guideline for the AI Agent responsible for creating the UI using Luau code in VS Code.

## 1. Core Rule: Zero External Assets
*   **NO `.rbxm` files.** You must generate every UI element programmatically using `Instance.new("ScreenGui")`, `Instance.new("Frame")`, `Instance.new("TextLabel")`, `Instance.new("TextButton")`, `Instance.new("UICorner")`, etc.
*   Auto-parent the `ScreenGui` to `Player.PlayerGui` inside the Client Controllers (e.g., `HUDController.luau`).

## 2. Responsive Design (Absolute Rule)
*   **NEVER use Pixels (Offset) for Size or Position.** 
*   **ALWAYS use Scale.** Example: `UDim2.new(0.1, 0, 0.05, 0)` not `UDim2.new(0, 100, 0, 50)`.
*   Use `UIAspectRatioConstraint`, `UIListLayout`, and `UIGridLayout` to keep menus clean on both Mobile and PC.

## 3. Map & Biome Themed Aesthetics
The map is a **Hub-and-Spoke** design. The UI colors and borders should reflect this. Use `UICorner` (0.1 Scale) on all panels for a modern vibe, and `UIStroke` for outlines.

| Element | Background Color (RGB) | Stroke/Text Color (RGB) | Notes |
| :--- | :--- | :--- | :--- |
| **Safezone/General UI** | Teal/Mint (167, 219, 200) | Dark Blue (20, 40, 60) | Clean, bright |
| **Urban Biome Items** | Dark Blue (30, 45, 75) | Neon Cyan (0, 255, 255) | Cyberpunk, glowing |
| **Slums Biome Items** | Rusty Brown (139, 69, 19) | Bright Orange (255, 140, 0) | Gritty, patched |
| **Mountain Biome Items**| Forest Green (34, 139, 34)| Pale Crystal (224, 255, 255)| Earthy |
| **Speed/Buff Text** | Electric Yellow (255, 255, 0)| Black (0, 0, 0) | Pop-out stat |

## 4. UI Layout Specifications

### A. Main HUD (Always Visible)
*   **Position:** Spread across the screen edges to keep the center clear for gameplay (seeing boxes and monsters).
*   **Top Center (Speedometer):** A sleek horizontal bar or text label. Format: `⚡ Speed: 26 (Base 16 + Item 10)`. Background: Translucent Black (Transparency 0.5), Text: Electric Yellow.
*   **Top Right (Economy):** Bucks Display. Format: `💵 $1,500`. Green text, white outline.
*   **Bottom Center (Status):** Carry Indicator. Only appears when carrying a box. Format: `📦 Carrying [Tier] Box! Run to Safezone!` (Blinking Red/Yellow).
*   **Middle Left (Buttons):** Column of circular or square buttons using `UIListLayout`.
    *   Button 1: `🎒 Inventory`
    *   Button 2: `⬆️ Upgrades`

### B. Inventory & Equip Menu (Popup)
*   **Position:** Centered panel, Size `UDim2.new(0.6, 0, 0.7, 0)`.
*   **Layout:**
    *   Top: Title "Inventory" and "X" Close Button.
    *   Left side (60% width): `ScrollingFrame` with `UIGridLayout` showing owned items. Each cell shows the Item Name and Rarity Color.
    *   Right side (40% width): Item details panel. Shows `incomePerSecond` (for Display) and `speedBuff` (for Equip).
    *   Action Buttons (Bottom Right): `[Equip for Speed]` and `[Display for $]`.

### C. Interaction Prompts (Proximity)
*   Do not use default `ProximityPrompt` visuals if possible; use `ProximityPrompt.Style = Enum.ProximityPromptStyle.Custom` and connect to `PromptShown` to render a custom programmatic 2D billboard UI over the box.
*   Text: `[E] Steal Box` (Desktop) / `Tap to Steal` (Mobile).

## 5. Animation (Juiciness)
*   Implement `TweenService` for interactions.
*   **Hover:** Buttons grow slightly (`Size = originalSize * 1.05`) in 0.15s.
*   **Click:** Buttons shrink slightly (`Size = originalSize * 0.95`) in 0.1s.
*   **Menu Open:** Tween position from off-screen (e.g., `Y = 1.5`) to center (`Y = 0.5`) using `Enum.EasingStyle.Back` or `Quad`.