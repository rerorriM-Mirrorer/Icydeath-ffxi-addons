# SellNPC

## Beta 3: readable progress and remembered merchant (current development build)

The optional batch now explains every step in **BattleMod-style colored game chat**: `[Move]` before and after each storage retrieval, `[Shop]` when opening/receiving the merchant shop, `[Sell]` before one stack's sale request, `[Sold]` after its confirmed sale, and `[Batch]` when transitioning between passes. Help and status use the project's shared chat colors and `SellNPC ->` prefix. It still waits for each sale confirmation and Inventory reduction before proceeding.

The batch **remembers the merchant selected at the start**. Clearing or changing the player's current target no longer interrupts a batch. The remembered NPC must still exist with the same ID and index in the same zone, and remain within interaction range. SellNPC never adopts a new target during a run. Be sure to target an ordinary vendor when starting.

**Bags remain strictly Inventory, Satchel, Sack, Case**. No Wardrobes, Safe, Storage or Locker retrieval. `junk` now contains **266 unique names**, including newly selected `Papaka Grass`, `Shell Bug`, and `Silk Thread`. Those items can have quest/crafting uses, but are deliberately in this personal selling profile.

For a cautious live test, make sure a prior batch is finished, reload SellNPC, then run:

```text
//sellnpc preview Animal Glue
//sellnpc batch Animal Glue
//sellnpc status
```

The code passes offline Lua simulations including target changes and action-by-action messages; **this revision has not yet been verified in live FFXI**. The previous Beta 2 showed real sales, but a target-change interruption. See [TESTING.md](TESTING.md) for cumulative results. Do not reload while a batch is active or interfere with another item's automatic transfers.


### Command Usage:
```
sellnpc <item_name>	-- add item_name to sales queue. quotes not needed, accepts auto-translate. 
sellnpc <profile_name> 	-- load a group of items from profiles.lua into the sales queue
```
Sales are now triggered by opening a shop window, you will need to queue items prior to this.

Items are removed from queue once selling has completed.

Will not try to sell items equipped, in bazaar or that can not be sold to NPC vendors.

##### If there has been a mainenance or update to the game make sure windowers resource files have been updated to reflect new items added.

### Curated junk profile (inventory pass, 2026-11-01)

`//sellnpc junk` queues every matching type in `profiles.lua` (including the original list). **Opening an NPC shop then triggers immediate sales from main inventory**, without a dry-run or confirmation prompt. It does not sell items directly out of Case, Sack, Satchel, Safe, or Wardrobes.

For a safer initial live check, try `//sellnpc Animal Glue`, then open a shop and verify the result before queuing the entire profile.

The current `junk` list combines the previously maintained items with 40 common, replaceable items identified in FindAll exports for Cioara, Clairvaux, Killala, and Myrr. Equipment, spells, special currencies and identifiable progression items were excluded from the *new* selections. Some items can be worth more on the Auction House or serve optional quests; review the complete profile before using it.

**Development status:** See [TESTING.md](TESTING.md) for what was checked and what still requires a live FFXI test.

### Beta 2: sequential batch retrieval and selling (not live-tested)

The optional batch commands work **on one character** and use the item names in your existing `profiles.lua`. They do not require Itemizer or NPCMirror to be loaded: SellNPC uses the same Windower `move_item` API as Itemizer. It moves items only from **Satchel, Sack, and Case** (plus items already in Inventory). It deliberately excludes Wardrobes, Safe, Storage, Safe 2, and Locker to avoid conflict with GearSwap and remote storage limitations.

```text
//sellnpc preview junk         -- list eligible item quantities by bag; no changes
//sellnpc preview Animal Glue  -- safely preview one item type
//sellnpc batch Animal Glue    -- first live test: just one item type
//sellnpc batch junk           -- start selling all eligible profile entries
//sellnpc status               -- show current stage and confirmed sales
//sellnpc stop                 -- stop additional transfers and sales
```

Target a **nearby ordinary NPC merchant** first, then run `//sellnpc batch <profile or item>` while idle and outside menus. The addon remembers that NPC, retrieves eligible stacks (up to 12 per pass, retaining two empty Inventory slots), interacts with the targeted merchant, and sends one sale at a time. It checks the NPC sale response (`0x03D`) **and** the Inventory change before proceeding. It attempts subsequent passes using the same shop context. Automatic shop reopening and bag movement while the menu is open are **not yet confirmed in FFXI**; the run stops rather than repeatedly guessing if an interaction or move times out.

This is real, irreversible selling — **`batch` is not a dry-run**. Unlike `preview`, it moves items and can sell them immediately. Its `stop` command prevents new requests, but cannot undo an already-sent move or sale. `//sellnpc junk` without `batch` still uses the original immediate-on-next-shop behavior. During the first live tests, disable any MogMover mapping that would move the same items; do not run competing automated NPC sessions with NPCMirror.

**Start with `//sellnpc preview Animal Glue`, then `//sellnpc batch Animal Glue`**, and check the real results before using the entire junk profile. See `TESTING.md` for live acceptance checks and known limits.

### Changelog

- **2026-11-01 (Beta 3 working branch, live test pending):** Action-by-action colored chat, stable saved-merchant guard, and Papaka Grass, Shell Bug, Silk Thread in `junk`. No changes to sequential sale pacing or accessible bags.

- **2026-11-01 (Beta 2 development branch; live testing pending):** Added preview, batch, status, stop, confirmation-driven sales, guarded Satchel/Sack/Case pulls, NPC target validation, and isolated Lua simulator; legacy sale commands remain available.

- **2026-11-01 (working branch, not yet FFXI-tested):** Added 40 everyday items to `junk`, removed one duplicate, kept existing profile choices intact. No auto-sell or Itemizer/NPCMirror behavior was changed.
