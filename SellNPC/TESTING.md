# SellNPC — TESTING.md

## Current Development Status — November 1, 2026 (first live observations, America/Chicago)

- **Branch / code under live review:** `rerorriM-Mirrorer/Icydeath-ffxi-addons` / `sellnpc/batch-verified-sales-2026-11-01`; initial Beta 2 implementation commit `da7c6d1d4c3777f77b867ad474fabea0ad028277`; target-guard adjustment commit `00fca3e392a80646b8682fcb695a75cbf7fd1b0d`. No SellNPC code change made in this log-analysis update.
- **Live evidence:** User reported "it seems to be working awesome", supplied `Cioara_2026.11.01.log`, and tested on Cioara at NPC merchant **Rhimonne** (Lower Jeuno). This is first actual FFXI usage evidence, unlike the previous simulation-only checkpoint. The transcript has **no final completion summary** for the second batch.
- **First batch:** `preview junk` reported **219 units / 48 stacks**: Inventory 0, Satchel 0, Sack 2 units / 2 stacks, Case 217 units / 46 stacks. `batch junk` started with those values, then logged **"Stopped: target changed during vendor batch: moved 11 stacks, confirmed sold 0 items (0 stacks)."** The target-change guard may be stricter than necessary, but no packet trace yet establishes why the target changed.
- **Legacy behavior after stop:** An old-style `junk` queue was loaded; chat recorded "Selling 70 items" and vendor sale messages. Distinguish these from the subsequent batch's verified activity. An earlier old-style sale logged "Selling 47 items."
- **Second batch:** `batch junk` began with **149 units / 36 stacks**. Subsequently the chat log recorded **12 vendor sale messages**, representing **29 units** (Yagudo feathers, cloth, beehive chips, black tiger fang, wolf hide, wild onion, sheepskins, copper ore, ice crystals, grass thread, bone chip). These are user-observed FFXI chat sales, not proof of completion or an audited Gil total. File ended immediately after the bone chip sale; no batch completion, status, or stop message appears.
- **Profile warnings:** Four entries are reported NPC-unsellable: `Goblin Mail`, `Goblin Mask`, `Dhalmel Saliva`, `Goblin Helm`. Do not automatically revise the user's original profile without review.
- **Assessment:** **Partial live success observed** — real bag retrieval was reported (11 stacks) and real vendor sales were observed during the second batch. Full unattended multi-pass completion **not yet verified**. The target-mismatch stop is a specific issue to investigate before calling this stable.
- **Next:** Request/capture `//sellnpc status` during and after a run, and a follow-up log showing final completion or interruption. Correlate an unexpected target change with shop-open state. Avoid editing or reloading an actively selling client; isolate any target-guard adjustment in a subsequent test build.

### 2026-11-01 — User live log review and findings

- **Evidence:** `Cioara_2026.11.01.log` lines ~26274–26327, provided in ChatGPT conversation after first Beta 2 test.
- **No new code edits, runtime simulations, or live game tests performed by the assistant** during this review. Reviewed log text and the published `SellNPC.lua` target guard.
- **Previous "Windower / FFXI not tested" status below is historical and now superseded in part** by the user's actual in-game observations above. Packet semantics, sale-ack matching, inventory delta confirmation, full completion, and NPCMirror interaction remain unverified individually.

---

## Previous Development Status — November 1, 2026 (Beta 2 before live testing, America/Chicago)

- **Repository / branch:** `rerorriM-Mirrorer/Icydeath-ffxi-addons` / `sellnpc/batch-verified-sales-2026-11-01`. Working branch branched from `sellnpc/junk-profile-inventory-2026-11-01`; `master` untouched.
- **Source baseline:** existing `SellNPC/SellNPC.lua` blob `1fc7e771e987c5f999d65b41588afc37c6c6d346` (Ivaar v2.0.0.0), existing 263-name `junk` profile blob `a718748692dc62db90e0d2b48b0db0712a539f64`.
- **Scope:** one-character optional profile or single-item batch, preview/status/stop, Satchel/Sack/Case retrieval into Inventory via `windower.ffxi.move_item`, guarded NPC interaction and sequential vendor sale with acknowledgement and Inventory-change checks. Legacy single-shot queue unchanged in intent; no NPCMirror IPC added.
- **Runtime:** Windower 4 / FFXI **not tested** on actual clients. Companion Itemizer/NPCMirror runtime versions **not required** for this beta; their code was consulted. Real shop availability and automatic repeated pass behavior still need acceptance testing.
- **Offline static/simulation:** source parsed under `texlua --luaonly` (Lua 5.3 engine, not a Lua 5.1-specific parse); `tests/batch_sim.lua` passed simulated multi-pass move/sell, preview, single-item scope, legacy queue, timeouts for no move/no sale/no shop, stop, zoning, and target guards. Windower APIs and server packets were mocked, so these are not in-game outcomes.
- **Known uncertainties:** Whether moving items while a shop menu is open succeeds; how a vendor menu behaves after an individual `0x085`; how target state behaves on all merchant types; whether each live `0x03D` sale response consistently matches the parsed inventory index. If not, this code should stop instead of blindly retrying.
- **Safety/compatibility:** SellNPC batch includes only main Inventory and portable Satchel(5), Sack(6), Case(7); never Wardrobes or GearSwap equip bags. Reserves two free Inventory slots, limits to twelve retrieved stacks per pass. Only one move/sale in flight. On timeout, zoning, target change, logout, or stop it cancels new actions but cannot reverse packets already sent. Existing junk profile still contains crystals and older choices.
- **Next live step:** Target one ordinary merchant while idle and run `//sellnpc preview Animal Glue`, then `//sellnpc batch Animal Glue` with one small stack. Verify sale response/inventory change, then two storage stacks and multiple passes. Do not start with the entire `junk` profile.

### Beta 2 live acceptance checklist (not yet performed)

1. Load the exact working-branch files and check no addon load error or unrelated gear movement.
2. `//sellnpc preview Animal Glue`: confirms Inventory/Satchel/Sack/Case totals, no packets or inventory movement.
3. Put one small stack in Inventory, target a nearby vendor, run `//sellnpc batch Animal Glue`: verify one sale confirmation and expected Gil/item changes.
4. Put a second Animal Glue stack into Satchel; run the same batch and confirm the transfer actually completes before sale.
5. Repeat with two or more stored stacks and fewer than twelve free Inventory slots; observe the shop lifecycle between passes.
6. Try `//sellnpc stop` while waiting to sell/move; confirm no new requests are started. Test wrong target, zoning, and NPC not responding.
7. With MogMover and GearSwap enabled, confirm no item bouncing or unrelated storage transfers; disable conflicting mappings for initial tests.
8. Only then consider `//sellnpc batch junk`; remember it includes all pre-existing 263 eligible profile types, some of which can be valuable elsewhere.

### 2026-11-01 — Batch controller development (offline verified)

- `SellNPC/SellNPC.lua`: state machine for one move/sale at a time, valid merchant identity/zone, shop entry, timeouts, and server sale acknowledgement before continuing.
- `SellNPC/tests/batch_sim.lua`: deterministic Lua simulation with mocked packet and inventory APIs.
- `SellNPC/README.md`: current commands, storage scope, live test precautions.
- `SellNPC/docs/PACKETS.md`: protocol references and unverified assumptions.
- **Not performed:** in-game FFXI testing, actual storage transfers or Gil sales, NPCMirror multi-character orchestration.

---


## Previous Development Status — November 1, 2026 (inventory-curation batch)

- **Repository / working branch:** `rerorriM-Mirrorer/Icydeath-ffxi-addons` / `sellnpc/junk-profile-inventory-2026-11-01`.
- **Source baseline:** `master`, `SellNPC/profiles.lua` blob `06f3d8d3ebea069c482bfea011b7aafbb89bc702`. The original `master` branch has not been modified for this batch.
- **Batch:** Extend the `junk` profile with 40 common/replaceable item names from the four inventory exports. Preserve the existing `furrow` and `junk` selections. Remove one existing duplicate `Matamata Shell` entry.
- **Static verification:** Parsed the boundaries and quoted entry lines of `profiles['junk']`; checked that all 40 new names were absent before adding and present afterward; checked no duplicate literal item names remain. Result: 223 unique original names → 263 unique names. This is a structural/static check, **not a Lua 5.1 runtime test**.
- **Inventory evidence:** `Cioara.csv`, `Clairvaux.csv`, `Killala.csv`, `Myrr.csv` (FindAll exports provided in conversation). The 40 names collectively represented 470 units at export time, spread across different storage bags. Counts are not a prediction of actual NPC-sales quantity.
- **Runtime behavior reviewed from source:** `SellNPC.lua` queues item IDs via `//sellnpc junk` and injects sale packets when the shop window opens. It examines **main inventory only**, and skips non-vendorable items and non-idle inventory statuses. It has **no dry-run or review confirmation**.
- **In-game testing:** **Not performed**. Nothing has been sold or moved by this development batch.
- **Outstanding risks:** The existing 223-name profile already includes crystals and other items chosen previously. Queuing `junk` may sell those too if present in main inventory. Some names may be unsellable to NPCs or have better auction-house value. Avoid treating the profile as a safe delete-all list.
- **Next:** Test a single item using `//sellnpc Animal Glue` followed by opening a merchant's shop. Then review the entire `junk` list before attempting `//sellnpc junk` on a character. Itemizer and NPCMirror integration is **out of scope** for this batch.

---

## Current testing checklist (pending live FFXI)

1. Load or reload SellNPC using the working-branch files; confirm there is no Lua load error.
2. Inspect the curated and pre-existing `junk` entries against materials actually intended for sale.
3. Put one harmless test item in **main inventory** (e.g., Animal Glue), type `//sellnpc Animal Glue`, then open an NPC vendor's shop; verify only that item sold and observe chat errors.
4. Confirm a similarly named item in Case or Safe was not sold (SellNPC does not access those bags).
5. Only after the broader list has been checked, queue `//sellnpc junk` and open a shop on one character; observe queued-item behavior and non-vendorable skips.
6. Verify the four character exports remain a useful planning snapshot; **do not** assume the export includes only current inventories or that every item is NPC-sellable.
7. Revalidate the complete list before any later automatic NPCMirror or Itemizer batch integration.

## Cumulative history

### 2026-11-01 — Inventory-based junk profile curation (untested)

- 40 new names added; old entries preserved; one existing duplicate removed.
- The selection favors ordinary drops, crafting ingredients and common food over theoretical future needs.
- Intentionally **not added** in this batch: mission items (e.g., Seedspall Lux), possible quest-specific objects (e.g., Damp Envelope and Muddy Bar Tab), equipment, scrolls, special currencies, Beastmen's Seals, Copper Vouchers, Mog Pells, and Yagudo Necklaces (not NPC-vendorable).
- No in-game testing or actual sale occurred.

## Delivery register

| Date | Batch | Files | Verification | Commit |
| --- | --- | --- | --- | --- |
| 2026-11-01 | Inventory curation | `SellNPC/profiles.lua` | Structural item-list checks only; no live FFXI run | `6f05d671614456a928007d3f4400f2e76b8018db` |
| 2026-11-01 | Process adoption | `SellNPC/WORKFLOW.md` and this record | Documentation only | See GitHub working-branch history |

## User-provided materials and requests

- 2026-11-01: Four FindAll CSV inventory exports for Cioara, Clairvaux, Killala and Myrr.
- 2026-11-01: Preference for selling readily replaceable drops and crafting junk without keeping everything merely for hypothetical future quests.
- Future possibility: Itemizer get/put batching and coordinated SellNPC/NPCMirror shop interactions. No implementation authorized in this batch.

## Repository policy adoption still outstanding

This multi-addon repository lacked root `AGENTS.md`, `WORKFLOW.md` and `TESTING.md` at the reviewed source baseline. The canonical NPCMirror workflow has been copied into `SellNPC/WORKFLOW.md` so this addon has clear local guidance. If/when this larger repository is developed more broadly, decide separately whether to adopt root-level standards without changing unrelated addons.
