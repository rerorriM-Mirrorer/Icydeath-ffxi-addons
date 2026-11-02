# SellNPC

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

### Changelog

- **2026-11-01 (working branch, not yet FFXI-tested):** Added 40 everyday items to `junk`, removed one duplicate, kept existing profile choices intact. No auto-sell or Itemizer/NPCMirror behavior was changed.
