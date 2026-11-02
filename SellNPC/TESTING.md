# SellNPC — TESTING.md

## Current Development Status — November 1, 2026 (America/Chicago)

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
