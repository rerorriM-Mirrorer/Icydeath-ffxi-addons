AuctionHelper
=============

## Simple bidding (2026-11-02 development test)

The main command is now `//ah <item name> <bid> [size]`. It submits **one**
bid at the gil price given. If size is omitted, a stack is selected whenever
the item can stack, otherwise a single is selected.

```text
//ah Silk Thread 5000           # Stack (default for stackable items)
//ah Silk Thread 5000 single    # Single
//ah Silk Thread 5000 1         # Single (shorthand)
//ah Silk Thread 60000 stack    # Stack
//ah Silk Thread 60000 12       # Stack (shorthand; NOT a quantity request)
//ah bid 65000                  # Rebid the last item and size
//ah help                       # Full BattleStations-style command list
//ah status                     # Version and remembered last item
```

The `1` and `12` suffixes mean **single** and **stack** only in the
new short form. They do not order 1 or 12 separate transactions. Use the
actual item's standard FFXI stack size.

Historical commands still work: `//ah buy Silk Thread 0 5000` means
**single**, and `//ah buy Silk Thread 1 60000` means **stack**, using
the older 0/1 semantics. `//ah sell ...`, `//buy ...`, `//sell ...`,
the auction menu, and the existing sales display are retained.

`//ah bid <price>` remembers the last **submitted** buy attempt in the
current client session. It does not query prices, bid automatically,
or retry on its own. Observe the Auction House response before rebidding.
Bids still require an Auction House zone. A short cooldown remains between
commands.

The bare `//ah` retains its original action of opening the AH menu
when available. `//ah help` gives the command list.

Auction house bidding tool - addon for Windower
-----------------------------------------------
Allows you to perform auction house actions with commands, much like bidder with additional functionality.
Displays a text object with sales information when opening ah menu (if text object is set to show).

buy [item name] [stack] [price] -- buy an item on auction house

sell [item name] [ stack] [price] -- sell an item, must open ah once after addon has loaded/players logged in.

[item name] - Accepts auto-translate, short or full item name, no quotes needed.

[Stack] - "stack" or "1" or "single" or "0"

[price] - CSV and EU decimal mark are optional. e.g. 100000 or 100,000 or 100.000

inbox / ibox	-- open delivery inbox

outbox / obox	-- open delivery outbox

bazaar [item_name] [price]-- sets bazaar prices for all instances of [item_name]. Note: bazaar window must be open.

ah		-- open AH menu

ah clear 	-- clear sold/unsold status

ah show/hide -- show or hide text object, click/drag window to move, accepts following arguments to customize displayed information, show as little or as much as you like.

	timer	-- show timer counting down/up to/from end of auction/time of sale.
	date	-- date and time the item auction ends/returned/was sold
	price	-- display your asking price
	empty	-- show/hide empty slots
	slot	-- show slot number next to item entry

ah save -- save settings related to text object


check settings file for more customization options.

##### If there has been a mainenance or update to the game make sure windowers resource files have been updated to reflect new items added.

TODO:	Expand delivery boxes beyond auction house zones (list mog house zones, other delivery areas),
	Block sell confirm window when injecting sell packet (only occurs when selling inside sell menu),
	Adjust delays.

### Development changelog

- 2026-11-02: Short `//ah <item> <price> [single|stack]` bids, default stacks,
  last-item `//ah bid <price>` rebids, BattleStations-style command/feedback
  formatting. Existing command forms remain available. This is a development
  build awaiting in-game acceptance.
