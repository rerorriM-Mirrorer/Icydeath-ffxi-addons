# finalAlert

Author: Godchain. This fork includes the tested `1.3-draggable` update.

Displays a banner when the selected NPC begins a TP move or spell, or its action is interrupted. If the selected target is not an NPC, the addon uses the battle target when available. Ability, magic, interrupt, and emphasized alerts retain their existing textures and sounds.

## Installation

Copy the complete `finalAlert` folder into Windower's `addons` folder, keeping `images` and `sounds`. Load with `//lua load finalAlert`. Existing settings in `data/settings.xml` remain compatible; do not replace your settings with another player's file.

## Commands

Both `//fa` and `//finalAlert` are accepted. Command arguments below are lowercase.

| Command | Behavior |
| --- | --- |
| `//fa help` | Show command help. |
| `//fa test ws` | Show a Self-Destruct TP-move test. |
| `//fa test ma` | Show a Tornado II magic test. |
| `//fa test int` | Show an interruption test. |
| `//fa pos 960 200` | Set and save the banner's horizontal center and top Y position. |
| `//fa lock` / `//fa unlock` | Disable/enable mouse dragging and save the setting. |
| `//fa size small` / `//fa size regular` | Select and save the background texture size. |
| `//fa duration 5` | Set a positive display duration in seconds for the current session. This command does not save immediately. |
| `//fa sounds on` / `//fa sounds off` | Set and save ordinary alert sounds. Emphasized alerts still play their sound. |
| `//fa emphasize Firaga VI` | Toggle and save emphasis for a name; matching ignores whitespace and case. |

## Dragging and saved settings

Dragging is enabled by default. While an alert is visible, press the left mouse button over its banner, move it, and release. All four backgrounds follow the saved center/top coordinates; the caption follows during rendering. Release saves `x_position` and `y_position` and prints `Position saved: X, Y`.

For a longer positioning window, use `//fa duration 10` followed by `//fa test ws`. Hidden alerts cannot start a drag. The mouse hit area remains 500 × 90 pixels for both texture sizes, matching the tested implementation.

Defaults are horizontal screen center, Y=100, regular textures, three-second duration, ordinary sounds on, no emphasized names, and dragging enabled. Settings are managed by Windower's config library. Duration remains in memory until reload unless another setting-save operation persists it.

## Scope and verification

This update preserves the tested Lua file unchanged, including original targeting, alert timing, textures, sounds, and emphasis behavior. It adds dragging, release-to-save confirmation, and lock/unlock commands to the fork's older 1.2 implementation.

Background alpha/off, font, stroke, theme, and other visual enhancements are not implemented here. Earlier discussion deferred further enhancements after draggable positioning.

Offline checks cover Lua parsing and mocked Windower behavior for alert types, targeting, emphasis/sounds, auto-hide, dragging, saved coordinates, lock/unlock, and existing commands. Actual rendering and sound playback require an in-game check.
