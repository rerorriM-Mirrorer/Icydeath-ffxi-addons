# finalAlert

Author: Godchain. Version `1.4-edit-mode` builds on the tested `1.3-draggable` update.

Displays a banner when the selected NPC begins a TP move or spell, or its action is interrupted. If the selected target is not an NPC, the addon uses the battle target when available. Ability, magic, interrupt, and emphasized alerts retain their existing textures and sounds.

## Installation

Copy the complete `finalAlert` folder into Windower's `addons` folder, keeping `images` and `sounds`. Load with `//lua load finalAlert`. Existing settings in `data/settings.xml` remain compatible; do not replace your settings with another player's file.

## Commands

Both `//fa` and `//finalAlert` are accepted. Command arguments below are lowercase.

| Command | Behavior |
| --- | --- |
| `//fa help` | Show command help. |
| `//fa edit` | Toggle a silent, persistent positioning preview. |
| `//fa edit on` / `//fa edit off` | Explicitly enable/disable the preview. Repeating either command keeps the requested state. |
| `//fa test ws` | Show a Self-Destruct TP-move test. |
| `//fa test ma` | Show a Tornado II magic test. |
| `//fa test int` | Show an interruption test. |
| `//fa pos 960 200` | Set and save the banner's horizontal center and top Y position. |
| `//fa lock` / `//fa unlock` | Disable/enable normal-alert mouse dragging and save the setting. Edit mode always permits dragging. |
| `//fa size` | Toggle small/regular background textures and save the setting. |
| `//fa size small` / `//fa size regular` | Select and save the background texture size. |
| `//fa duration 5` | Set a positive display duration in seconds for the current session. This command does not save immediately. |
| `//fa sounds` | Toggle ordinary alert sounds on/off and save the setting. |
| `//fa sounds on` / `//fa sounds off` | Set and save ordinary alert sounds. Emphasized alerts still play their sound. |
| `//fa emphasize Firaga VI` | Toggle and save emphasis for a name; matching ignores whitespace and case. |

## Dragging and saved settings

Dragging is enabled by default. While an alert is visible, press the left mouse button over its banner, move it, and release. All four backgrounds follow the saved center/top coordinates; the caption follows during rendering. Release saves `x_position` and `y_position` and prints `Position saved: X, Y`.

Use `//fa edit` to show `EDITING MODE - Exit with //fa edit`. Drag the banner, then use `//fa edit` again or `//fa edit off` to finish. The preview stays visible indefinitely without changing alert duration. It plays no sound, and combat alerts and `//fa test` cannot replace it while editing. Size and position commands update the preview immediately.

Edit mode temporarily allows dragging even when locked; the saved lock setting still applies to normal alerts afterward. Exiting hides the preview, and the next normal alert works as usual. Edit mode is not saved, so reloading always returns to normal operation. If you exit while dragging, the current position is saved before the preview closes.

Hidden alerts cannot start a drag. The mouse hit area remains 500 × 90 pixels for both texture sizes, matching the tested draggable implementation.

Defaults are horizontal screen center, Y=100, regular textures, three-second duration, ordinary sounds on, no emphasized names, and dragging enabled. Settings are managed by Windower's config library. Duration remains in memory until reload unless another setting-save operation persists it.

## Scope and verification

The fork includes draggable positioning, release-to-save confirmation, and lock/unlock from the tested 1.3 update. Version 1.4 adds temporary edit mode and no-argument size/sound toggles. Normal targeting, alert timing, textures, sounds, and emphasis behavior are retained.

Background alpha/off, font, stroke, theme, and other visual enhancements are not implemented here. Earlier discussion deferred further enhancements after draggable positioning.

Offline checks cover Lua parsing and mocked Windower behavior for existing alert types, targeting, emphasis/sounds, auto-hide, dragging, saved coordinates, and lock/unlock, plus persistent/silent edit mode, explicit and toggle commands, preview resizing/repositioning, exit/reload behavior, and invalid arguments. Actual rendering and sound playback require an in-game check.
