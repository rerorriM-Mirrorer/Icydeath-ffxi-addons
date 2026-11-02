# Current Development Status — AuctionHelper short bidding (2026-11-02)

- **Repository:** `rerorriM-Mirrorer/Icydeath-ffxi-addons`
- **Working branch:** `auctionhelper/simple-bids-20261102` (unverified development branch; do not promote to `master` yet).
- **Starting trusted source checkpoint:** `master` at `fcbe6f332d960734ae990b106efe645bd07f6436`.
- **Runtime target:** Windower 4 / Lua 5.1, FFXI retail, no external companion.
- **Addon version:** `1.26.11.02-bid1` based on the fork's existing AuctionHelper implementation.
- **Most recent user-confirmed AuctionHelper live test:** none recorded in this repository; no previous results reconstructed.
- **Current automated checks:** 13 static source/structure assertions passed; 9 isolated JavaScript parser simulations passed. These do not execute the Lua addon.
- **Lua compilation / Windower smoke / live bids:** not performed. Pending user acceptance in FFXI.
- **Next step:** Install the development Lua file, verify load/help, perform a low-value test bid and manually rebid after a failure; capture the exact chat and transaction results.

## Current test batch — Short bid syntax and chat formatting (2026-11-02)

**Goal:** Support `//ah <item> <price> [1|single|12|stack]`, default stacks when the item stacks, retain the optional `//ah bid <price>` manual rebid, and use the shared BattleStations-inspired chat conventions. Preserve prior buying, selling, auction slot display, mail, and bazaar paths.

### Install / precautions

1. Keep a backup of the previously installed `AuctionHelper/AuctionHelper.lua`.
2. Replace only `Windower/addons/AuctionHelper/AuctionHelper.lua` with the file from the named development branch; keep the existing folder name and dependencies.
3. Reload with `//lua r AuctionHelper`. `//ah help` should display colored, chat-only command guidance.
4. Test with an inexpensive item and a carefully chosen price. Auction bids are real transactions and the addon uses packet injection, as the inherited upstream addon already did.
5. For any testing ZIP, place `README.md`, `WORKFLOW.md`, and `TESTING.md` **inside** the `AuctionHelper/` folder with the code.

### Required live acceptance — not yet run

| Test | Input / action | Expected |
| --- | --- | --- |
| Load / help | Load addon; `//ah help` | No Lua error; BattleStations-style colored chat help |
| Default stack | `//ah Silk Thread 5000` | One **stack** bid at 5,000g |
| Explicit single | `//ah Silk Thread 5000 single` or `//ah Silk Thread 5000 1` | One **single** bid |
| Explicit stack | `//ah Silk Thread 60000 12` or `//ah Silk Thread 60000 stack` | One stack bid; suffix 12 is a size alias, not quantity |
| Non-stackable default | `//ah <unstackable item> <bid>` | Single bid; item lookup resolves valid auctionable resource |
| Last-item rebid | Bid once, await outcome, `//ah bid <new-price>` | Reuses same item and size; manually sends one new bid |
| Legacy buy | `//ah buy Silk Thread 0 5000` / `... 1 60000` | Original 0-single, 1-stack semantics |
| Legacy unhandled | `//buy Silk Thread 0 5000` | Original command still works |
| Legacy sell | `//ah sell <item> <0|1> <price>` | Original sell handshake and slot behavior |
| Menu and display | `//ah`, `//ah show`, `//ah hide` | Original menu and display behavior preserved |
| Validation | `//ah Silk Thread 5000 15` | Clear usage guidance; no packet |
| Cooldown | Rapidly repeat a bid | Does not issue back-to-back requests during existing cooldown |
| Server feedback | Successful / unsuccessful bid | Styled acknowledgement with correct result |
| Multibox | Issue commands in different clients | Last bid remembered per loaded character only |

### Checks actually performed

- Read current AuctionHelper source on `master`; read current canonical `WORKFLOW.md` directly from NPCMirror and consulted Windower's chat library.
- Structural verification of one each of the addon dispatcher, unhandled-command dispatcher, bid function, price parser, and shorthand handler, plus required message/color and bid-memory sites: **13/13 passed**.
- Independent JavaScript model of the shorthand parser, covering default, aliases, commas, malformed inputs and duplicate numerical suffixes: **9/9 passed**. This is **simulation, not executing Lua**.
- Reviewed the branch comparison against `master` for accidental duplicate source and unrelated addon code modifications.
- **No Windower execution, in-game packets, live buys, static Lua compiler, or FFXI regression test performed.**

## Delivery register

| Date | Batch | Files | Revision |
| --- | --- | --- | --- |
| 2026-11-02 | AuctionHelper short bidding (development) | `AuctionHelper/AuctionHelper.lua`, `AuctionHelper/README.md`, root `AGENTS.md`, `WORKFLOW.md`, `TESTING.md` | GitHub branch `auctionhelper/simple-bids-20261102`; exact published branch head is reported in delivery |

## Previous checks and history

- No earlier AuctionHelper tests were present in the repository's root when this file was added.
- The baseline AuctionHelper was already capable of direct buying, selling, auction sales-status tracking, mail access, and bazaar price setting. These functions were **not** retested in this batch.

## User observations and requests

- 2026-11-02: Prefer `//ah <item> <bid> [single|stack]` without a mandatory `buy` token or separate quantity field.
- Explicit shorthand aliases: `1` for a single, `12` for a stack; omit to default to a stack when possible.
- Preserve manual quick rebidding of the last selected item.
- Format messages and help according to current BattleStations-inspired shared workflow conventions.
- Do not introduce automatic price retrieval or autonomous bidding in this initial patch.

## Corrections and retention

Keep observations and testing history cumulative. Correct future inaccuracies with dated notes rather than silently deleting previous results.
