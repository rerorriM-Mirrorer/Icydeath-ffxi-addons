# finalAlert action-event reference — lifecycle test 1

## Scope and evidence

Read-only observation of Windower's parsed `action` event. No packet injection, outgoing modifications or duplicate raw-packet parser is introduced.

Sources reviewed:

- Windower/Lua, `addons/libs/actions.lua` on `dev`: begin/finish category and resource mappings, interruption marker and action-ID field selection.
- rerorriM-Mirrorer/enemybar2, `actionTracking.lua` and `enemybar2.lua`: incoming `0x028` parsing, preparation/completion records, interrupted-record clearing, 30-second unfinished/3-second finished cleanup, and hiding completed action labels.
- finalAlert 1.4 at `fcbe6f332d960734ae990b106efe645bd07f6436`: categories 7/8, interruption marker 28787, target/battle-target policy.

These are source observations, not new captured gameplay evidence. This batch has no live packet logs. No outgoing packet is needed for this UI feature.

## Incoming action packet 0x028, exposed through `action`

| Scenario | Category | Relevant fields | Source confidence / unresolved detail |
| --- | --- | --- | --- |
| Spell preparation | 8 | actor_id; targets[1].actions[1].param is spell ID | Source-confirmed; test selected enemy spell families live. |
| Spell execution | 4 | actor_id; top-level param is spell ID | Source-confirmed; not proof that the spell hit or its animation ended. |
| TP/weapon-skill preparation | 7 | actor_id; nested action param is ID | Source-confirmed; Windower distinguishes weapon-skill IDs ≤256 from monster-ability IDs >256. |
| Monster ability execution | 11 | actor_id; top-level param is monster ability ID | Source-confirmed; verify representative monster abilities live. |
| Weapon-skill execution | 3 | actor_id; top-level param is ID | Source-confirmed; normalize the resource family consistently with preparation. |
| Preparation interruption | 7/8, top-level param 28787 | actor_id, category; nested fields may be absent/zero | Existing finalAlert and Windower mapping agree. Match a nonzero nested ID when available; a marker without an ID cannot uniquely identify an earlier same-kind attempt. |
| Missing finish | No usable terminal event | preparation deadline | Timeout only clears the banner; it never fabricates execution or interruption. |

The selected NPC remains the scope. The battle target is used when the selected target is not an NPC, matching prior finalAlert. Lifecycle rendering polls target identity/death to clear stale state. Area changes and logout reset all transient state. Fixed mode deliberately retains its start-triggered timer.

## State correlation and variations

A preparation records actor ID, normalized resource family and action ID. Matching execution replaces its caption. A different finish cannot replace a current preparation. Duplicate same-action preparation/finish events do not extend deadlines. A valid finish without a recorded preparation can display its bare name for the currently selected enemy.

There is no invented sequence number: identical rapid actions from one actor can be indistinguishable if intervening preparation was missed. Interruption markers without an action ID are likewise not perfect correlation. A timeout is a safety net, not evidence of success.

## Verification record

Mocked spell, monster ability and weapon-skill sequences passed, including missing/duplicate/mismatched events, malformed nested fields, interruption without targets, fallback, target switching and death. Live repetitions and variation observations are pending.

For live checks record: enemy name, action name, start display, result display, interruption cause if any, whether target changed, and observed delay. If a family fails consistently, collect a narrow controlled action capture before broadening event handling. Do not infer completion from unrelated damage packets.
