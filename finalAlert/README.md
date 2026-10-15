# finalAlert

Godchain's Windower alert banner, developed with A. Version **1.5.0-test3**.

Shows the selected NPC's spell and ability preparations, interruptions, and—optionally—execution events. If the selected target is not an NPC, the battle target is used when available.

## Install this test batch

Copy the `finalAlert` folder into `Windower/addons`, merging with your existing folder. Keep your own `data/settings.xml`: this package deliberately supplies no saved settings. Reload with `//lua reload finalAlert`.

New installations default to fixed timing, sounds off, regular size, scale 1, unlocked dragging, and a banner centered in the current UI viewport. Saved coordinates and explicit sound preferences are preserved. On an existing installation use `//fa pos reset` and `//fa sounds off` to select those defaults yourself.

On load/reload, a silent grey banner reads **Final Alert** for six seconds, independently of the saved alert duration. A real alert or edit preview can replace it immediately. It does not enable edit mode or change any saved setting.

## Timing

- `//fa timing fixed` preserves the original start-triggered alert: bare action name for the fixed duration. Finish events do not extend that duration.
- `//fa timing lifecycle` shows `Casting: <spell>` or `Readying: <ability>` until a matching execution event. It then shows the bare name briefly. An interruption displays `Interrupted` on the original grey frame.
- Lifecycle preparation has a separate fallback timeout. Expiry only hides the banner; it never claims the action completed. Completion events mean execution/resolution was reported, not that damage landed or an animation finished.

Defaults: fixed duration **3 seconds**, completion/interruption display **1 second**, preparation timeout **30 seconds**. Durations accept positive finite values, including fractions; there are no arbitrary upper caps. Changes are saved. Changing a duration affects subsequent alerts, not a currently running deadline.

Preparation uses a muted grey-pink frame for magic and a muted grey-blue frame for abilities, tinting the original neutral artwork. Execution restores the original brighter magic/ability artwork, without a tint. Fixed-duration alerts and single tests also retain the original bright artwork. Interruption remains untinted grey. Text stays white; emphasized names retain their extra highlight.

## Edit and preview

**Bare `//fa` displays help and toggles the edit preview.** This is a deliberate primary action. `//fa help` only shows help.

The silent preview cycles every 1.5 seconds:

1. `Casting: Edit Mode` — grey-pink magic frame.
2. `Edit Mode` — original brighter magic frame.
3. `Readying: Edit Mode` — grey-blue ability frame.
4. `Edit Mode` — original brighter ability frame.
5. `Edit Mode` — grey interruption frame.

Drag either the frame or its caption. The cycle pauses while held; release saves the banner position and resumes the cycle after a full preview interval. `//fa edit`, `//fa edit on`, and `//fa edit off` also control the preview. Repeating explicit `on`/`off` commands is safe.

Editing overrides the saved drag lock without changing it. Combat events cannot replace the preview. Exiting hides it; the next gameplay event works normally. Preview state is temporary and is cleared by restart, reload, logout, or zoning. A separate guide explains how to exit without changing the requested preview captions.

The caption and guide have Windower's built-in text dragging disabled. One banner handler moves the text and artwork together, handles a blocked release after taking ownership of a drag, and saves on release. Hit areas follow the actual frame size and scale. Hidden alerts never capture a press.

## Commands

Aliases: `//fa` and `//finalAlert`. Command words and enum arguments are case-insensitive; action names retain their entered spelling. `<required>` arguments must be supplied; `[optional]` arguments can be omitted. Invalid commands/arguments show help without changing settings.

| Command | Behavior |
| --- | --- |
| `//fa` | Show help and toggle the cycling edit preview. |
| `//fa help` | Show chat-only command help. |
| `//fa edit [on|off]` | Toggle/set the preview. |
| `//fa timing [fixed|lifecycle]` | Report/set the timing mode. |
| `//fa duration [seconds]` | Report/set fixed duration; default 3. |
| `//fa finish [seconds]` | Report/set lifecycle result duration; default 1. |
| `//fa timeout [seconds]` | Report/set lifecycle preparation fallback; default 30. |
| `//fa pos [<x> <y>|reset]` | Report position, move, or reset to screen center. X is the banner center; Y is its top. Positions are kept reachable. |
| `//fa size [small|regular]` | Toggle/set frame size. Native frames are 500×25 or 500×40. |
| `//fa scale [number]` | Report/set a positive finite scale. Text scales too, with a one-pixel minimum font size. |
| `//fa sounds [on|off]` | Toggle/set all alert sounds; off includes emphasis sounds. Preview is always silent. |
| `//fa emphasize <action name>` | Toggle saved emphasis. Matching ignores whitespace and case and uses the underlying action name, excluding prefixes. |
| `//fa lock` / `//fa unlock` | Save normal-alert dragging locked/unlocked. |
| `//fa test <ws|ma|int>` | Show a single fixed-duration test, unless editing. |
| `//fa status` | Report version, settings, position and tracked phase/actor. |
| `//fa restart` | Briefly fade visible content, clean up and reload saved settings. |
| `//fa unload` | Briefly fade visible content, clean up and unload. |

Sounds are opt-in. When enabled, emphasis changes the warning sound as before, but execution does not replay a preparation warning. Gameplay alerts use restrained 0.12-second fades within their display interval. Restart/unload dispatch once even if requested repeatedly. No keybinds are installed.

## Development and testing

See repository-root `TESTING.md` for this batch's installation, checks and historical record, and `WORKFLOW.md` for shared conventions. `docs/PACKETS.md` distinguishes source-confirmed packet interpretation from still-needed live observations.

The suite under `tests/` exercises the addon against mocked Windower APIs. Run from this repository's root with Lua 5.1 or newer:

```text
lua finalAlert/tests/test_finalalert.lua
```

Automated verification is not live FFXI testing. Confirm the palette, smooth dragging, actual monster finish/interruption events, and low-resolution layout in game before promoting the working branch. Some actions may not emit every expected event; fallback and finish-without-start handling address that uncertainty without inventing completion.

## Cumulative changelog

### 1.5.0-test3

- Restore original untinted magic/ability textures for execution, fixed-duration alerts and single tests. Keep the subdued pink/blue neutral frames during preparation.
- Make preview entries explicit preparation/execution states so they use the same artwork selection as gameplay. The interrupted preview and six-second startup remain grey.
- Verify texture selection and tint reset across preview cycles and live-event simulations, including size/scale refresh.

### 1.5.0-test2

- Show a silent `Final Alert` startup banner for six seconds on load/reload. Real alerts and edit mode take priority; saved duration is unchanged.
- Check both preparation frames in the edit cycle. Test 1 already changed both preparation and execution to the same neutral artwork with subdued pink/blue tints; the original saturated magic/ability textures remain supplied but are not used by these states. This batch does not change that palette or restore the old artwork.

### 1.5.0-test1

- Add selectable lifecycle timing; keep fixed timing as the default.
- Show preparation prefixes, a brief bare-name execution state, and grey interruption state; clear missing finishes after an independent timeout.
- Match actor, action ID and resource family; ignore mismatched/duplicate transitions. Clear lifecycle tracking on target loss/change, death, zoning and logout.
- Add subdued grey-pink/grey-blue runtime frame tints with identical preparation/execution colors.
- Default fresh settings to sounds off and a centered banner. Preserve existing saved preferences. Off now silences emphasis too.
- Fix competing text/banner drag handlers; move text/frame together, pause the preview while dragging and recover positions after resolution changes.
- Add the five-stage preview; bare `//fa` now shows help and toggles it.
- Adopt fragment-colored chat help, invalid-command help, status, scale, center recovery, and graceful restart/unload.
- Save duration changes, unlike 1.4's session-only duration command. Completion and fallback settings are independently configurable.
- Keep stable rendering cached during long preparations; avoid repeating identical engine updates across clients.
- Add regression checks, packet notes, cumulative testing records and the shared workflow.

### 1.4-edit-mode

- Add a persistent silent edit preview, explicit edit on/off, and no-argument size/sound toggles.
- Keep combat events from replacing the preview; maintain saved lock state outside editing.
- Published at `fcbe6f332d960734ae990b106efe645bd07f6436`. This conversation did not record a subsequent live-test result for that revision.

### 1.3-draggable

- Add dragging, release-to-save confirmation and lock/unlock to the user's working attachment.
- Preserved in commit `590831eddca23e73993b4f61148f6389ca5fe056`. User supplied the attachment as working.

### 1.2

- Existing fork baseline: start-triggered ability/magic and interruption banners, emphasis, sounds, sizes, coordinates and fixed duration.
