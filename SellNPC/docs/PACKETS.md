# SellNPC vendor protocol notes — November 1, 2026

These are Windower field definitions and existing code observations, **not live captures from this Beta 2 batch**. Source: Windower `Lua/addons/libs/packets/fields.lua` and `Itemizer/itemizer.lua`, and Ivaar's existing SellNPC `SellNPC.lua`.

| Direction | ID | Known purpose | Used in this batch |
| --- | --- | --- | --- |
| outgoing | `0x01A` | NPC action/interact; Target, Target Index, Category=0 | Request selected vendor's shop |
| incoming | `0x03C` | Shop inventory listing | First observed packet triggers batch sale phase |
| outgoing | `0x084` | NPC vendor price query, Count, Item, Inventory Index | First half of one sale |
| outgoing | `0x085` | NPC vendor sale confirmation | Second half of one sale |
| incoming | `0x03D` | Price/sale response; Type=1 signals finalized sale, Inventory Index & Count | Require Type=1 matching slot *and* observed inventory reduction before next sale |
| outgoing | `0x029` | Move item, source/destination bags | Sent internally through Windower's `ffxi.move_item` API |
| incoming | `0x01E`/`0x01F`/`0x020` | Inventory quantity, assignments and full updates | Observed indirectly by polling Windower inventory snapshot; not parsed manually |

## Assumptions and risks to capture in-game

- A normal NPC merchant may send more than one `0x03C` packet. Opening a merchant shop was not tested here.
- A shop interaction may close or change after `0x085`; it is unverified whether the same menu context supports another sale packet.
- Inventory moves between Satchel/Sack/Case and Inventory while a vendor menu is open may be blocked; the batch stops on absence of movement confirmation instead of retrying.
- The server's `0x03D` Type=1 with matching slot is expected for sales. The simulator can generate that event, but no actual packet capture verifies it on this client.
- No packets that buy items or traverse arbitrary NPC choice menus are intentionally sent.
- The automatic interaction sends `0x01A` to the user-selected NPC and waits for the shop packet. If a quest NPC is targeted instead, it may enter a non-shop event and stop on timeout; always target an ordinary merchant.
- If a profile contains another item stack with a matching resource ID while outside Inventory, the move API can move it, but no attempt is made to retrieve from Wardrobes, Safe, or Locker.
- Avoid simultaneous automatic item relocation (e.g. MogMover/automatic GearSwap cleanup) for these test items.
- On timeout, no retried sell or move packet is injected; in-flight server actions may still complete even after stop.

## Planned capture template

| Scenario | Direction/packet | Observed fields | Actual client behavior | Result/remaining uncertainty |
| --- | --- | --- | --- | --- |
| Single Animal Glue sale | pending | pending | pending | Confirm `0x03D` field interpretation |
| Single stack Case → Inventory | pending | pending | pending | Confirm `ffxi.move_item` result and inventory delta |
| Two consecutive sale stacks | pending | pending | pending | Confirm shop remains usable |
| Next storage batch with shop open | pending | pending | pending | Confirm move and menu state |
