# finalAlert — Test 2: six-second startup

## Current batch — Test 2, 2026-10-15

Version **1.5.0-test2**, on `finalalert-lifecycle-test1`; source/package revision is in `finalAlert/REVISION.txt`. Master remains unchanged.

Merge the packaged `finalAlert` folder into the installed addon, preserve `data/settings.xml`, then run `//lua reload finalAlert`.

- [ ] On load/reload, the grey frame reads `Final Alert` for six seconds, silently, regardless of saved fixed duration or sound preference.
- [ ] A real action alert or `//fa` replaces the startup display immediately; it does not return afterward.
- [ ] `//fa` cycles through Casting: Edit Mode (pink), Edit Mode (pink), Readying: Edit Mode (blue), Edit Mode (blue), Edit Mode (grey). Check whether the reported missing backgrounds are the old saturated artwork or absent preparation frames.

Automated: Lua 5.1 parsing and mocked integration passed, including startup expiry at six seconds, silence with sounds on, gameplay priority, and both preview preparation frames. Actual live startup and the reported preview appearance still need confirmation.

User observations/request after Test 1: preparation windows look good; asked whether older magic/action windows changed and reported windows missing from the preview. Code review confirms Test 1 intentionally replaced both preparation/execution artwork with the subdued tinted neutral frame. The five preview entries select the same frames as gameplay. No original-artwork restoration or palette change is made without clarifying which appearance is wanted.

### Delivery register addition

| Batch | Revision | Status |
| --- | --- | --- |
| Test 2 | 1.5.0-test2; exact final source revision in packaged finalAlert/REVISION.txt | Startup and preview regression checks passed; live confirmation pending. |
| Test 1 published source | 1f94f733f82210ba161d1f8b6c9de02742d67b0c | User reports preparation appearance looks good; preview report retained above. |

The previous batch record is preserved below. Its references to current/pending checks describe that delivery, not a new assertion about Test 2.

---

## Current batch — 2026-10-15

Working branch: `finalalert-lifecycle-test1`. Baseline master: `fcbe6f332d960734ae990b106efe645bd07f6436` (1.4-edit-mode). Master is not changed by this test delivery.

This is a test build, **1.5.0-test1**. Automated checks passed; live FFXI verification is pending. The package's `REVISION.txt` inside the addon identifies the exact published source commit. This repository record identifies the branch and preceding commits without a circular self-commit hash.

### Install first

1. Back up your installed `finalAlert/finalAlert.lua` and `data/settings.xml`.
2. Merge the packaged `finalAlert` folder into `Windower/addons`. Keep your current `data` folder. The package contains no settings XML and changes no account/character data.
3. Run `//lua reload finalAlert` and `//fa status`; confirm version 1.5.0-test1.
4. To try the newly requested defaults on an existing installation: `//fa sounds off` and `//fa pos reset`. Existing saved sound/position preferences are intentionally retained.
5. Enable the new mode with `//fa timing lifecycle`. Fixed timing remains the saved/default option unless changed.

### Current live checklist — not yet performed here

- [ ] Bare `//fa` shows colored chat-only help and starts the preview. Bare `//fa` again shows help and exits. `//fa help` and an invalid command show help without toggling.
- [ ] Preview order: Casting: Edit Mode (grey-pink), Edit Mode (same pink), Readying: Edit Mode (grey-blue), Edit Mode (same blue), Edit Mode (grey interrupt). No sound.
- [ ] Drag by the caption and by empty frame area. Text and frame move as one; no jitter, competing capture or unexpected jumps. Cycle pauses while held; position saves on release and survives reload.
- [ ] Lock while editing; preview still drags, but normal alerts remain locked after exiting. No invisible frame captures the mouse.
- [ ] `//fa size`, `//fa size small`, `//fa scale 0.7`, and `//fa pos reset` work during preview. Try desktop and 960×540/1280×720 clients; restore desired scale with `//fa scale 1`.
- [ ] Magic preparation is grey-pink; finish is the bare name with exactly the same palette. Ability preparation/finish are both grey-blue. Interrupted stays grey. Assess whether either muted tint needs adjustment.
- [ ] Enemy spell: Casting until execution, then bare name for one second. Confirm on several spells.
- [ ] Enemy TP move: Readying until execution, then bare name for one second. Confirm on several moves, including a monster using player-style weapon skills if available.
- [ ] Interrupt a spell/ability when practical: grey Interrupted, then hide. No crash when a terminal event has sparse data.
- [ ] Switch away from the enemy while it prepares; the old lifecycle caption clears and does not attach to the new target. Verify target death, zoning and logout clear state.
- [ ] `//fa timeout 5` produces no false completion when its deadline expires. Restore `//fa timeout 30` afterward. A slow action may genuinely exceed a short test timeout.
- [ ] `//fa timing fixed` restores a bare-name start alert with the set `//fa duration`. Finish packets do not extend it. Set `//fa timing lifecycle` to continue lifecycle testing.
- [ ] Sounds off is fully quiet, including emphasized names. With sounds on, prep can sound once, emphasis matches the underlying name, and execution does not replay that sound. Restore sounds off.
- [ ] `//fa restart` and `//fa unload` fade and dispatch once, even if repeated; reload starts outside edit mode. Invalid arguments do not unload/restart.

### Automated verification completed

- Lua 5.1-aware parsing using luaparse; global references audited. Expected Windower globals: `_addon`, `windower`, `S`; all addon runtime state/helpers are local.
- API methods reviewed against Windower definitions and `texts.lua`. The default text draggable flag is true; the addon's caption and guide explicitly disable it.
- Mocked Windower integration: defaults, colored help, explicit/bare toggles, five preview stages, drag over text, blocked release, scaling/size/position, fixed and lifecycle timing, spell/monster/weapon-skill resources, interruption without nested data, duplicated/mismatched events, timeout, target/death/zone/logout cleanup, sound/emphasis handling, invalid inputs, saved-settings/reload compatibility, and once-only lifecycle commands.
- Fractional and long positive timers checked without arbitrary caps. Malformed action tables do not crash the handler.
- Stable-state rendering is cached; repeated unchanged preparation frames do not repeat identical primitive/text writes.
- Source/package consistency, asset paths and ZIP integrity checked before delivery.

The execution suite uses an available Lua 5.4 runtime with mocked Windower APIs. Syntax is separately parsed in Lua 5.1 mode; this does not replace live Windower execution.

## Delivery register

| Batch | Revision | Status |
| --- | --- | --- |
| Baseline | 1.4-edit-mode, fcbe6f332d960734ae990b106efe645bd07f6436 | Previously published to master; no subsequent live-test result is recorded in this conversation. |
| Drag repair | 7751193bb705b46e87c05678425259906652a033 | Working branch: disable independent caption dragging. |
| Test 1 | 1.5.0-test1; branch finalalert-lifecycle-test1; exact final revision in packaged finalAlert/REVISION.txt | Automated checks passed; live verification pending. |

## Historical checks and materials

- The user supplied `finalAlert(2).lua` as a working 1.3-draggable attachment. It was preserved exactly in commit 590831eddca23e73993b4f61148f6389ca5fe056, with a matching addon README.
- 1.4 added the indefinite silent edit preview plus size/sounds toggles. Earlier automated parsing and mocked behavior checks passed. Those earlier results are not evidence of live gameplay tests.
- On October 8 the optional lifecycle mode was discussed only: prefixes during preparation, a brief bare name on execution, grey interruption, fallback timeout, and fixed timing kept selectable. No implementation was authorized then.
- On October 15 implementation was authorized with grey-pink magic, grey-blue abilities, grey interruption, silent/centered defaults, drag investigation, current NPCmirror workflow, bare-command help plus edit toggle, and the exact five-stage Edit Mode preview.
- Current source, existing assets and documentation came from the fork. No new live packet captures or user settings were supplied for this batch.

## Rollback

Restore your backed-up Lua/settings, or the baseline master addon. Newly introduced config fields can remain unused by the older version. Do not replace your own data with the repository's example settings XML. Keep a copy of this testing record with your observations before requesting the next batch.
