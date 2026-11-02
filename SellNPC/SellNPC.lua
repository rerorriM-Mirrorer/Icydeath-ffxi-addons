-- SellNPC: original single-shot selling retained; optional, confirmation-driven
-- batches retrieve profile items from portable storage before each shop pass.
_addon.command = 'SellNPC'
_addon.version = '2.1.0-beta.1'
_addon.author = 'Ivaar (batch extensions by A)'
_addon.name = 'SellNPC'

require('sets')
local packets = require('packets')
local resources = require('resources')
local profiles = require('profiles')
local res_items = resources.items

-- Legacy item/profile commands still queue an immediate sale on the next 0x03C.
local sales_que = {}
local batch = nil
local serial = 0
local SOURCE_BAGS = {5, 6, 7} -- Satchel, Sack, Case. No wardrobe/Mog Safe access.
local BAG_NAMES = {[0]='Inventory', [5]='Satchel', [6]='Sack', [7]='Case'}
local MAX_PULLS_PER_PASS = 12
local FREE_SLOTS_RESERVED = 2
local MOVE_TIMEOUT = 8
local SALE_TIMEOUT = 8
local SHOP_TIMEOUT = 10

local function say(msg)
    windower.add_to_chat(207, 'SellNPC: ' .. msg)
end

local function now()
    return os.time()
end

local function get_item_res(name)
    name = name:lower()
    for _, item in pairs(res_items) do
        if (item.en and item.en:lower() == name) or
           (item.enl and item.enl:lower() == name) then
            return item
        end
    end
end

local function vendor_sellable(item)
    return item and item.id and not (item.flags and item.flags['No NPC Sale'])
end

local function allowed_items(profile)
    local allowed, invalid, unvendable = {}, 0, 0
    for name in pairs(profile) do
        local item = get_item_res(name)
        if vendor_sellable(item) then
            allowed[item.id] = true
        elseif item then
            unvendable = unvendable + 1
        else
            invalid = invalid + 1
        end
    end
    return allowed, invalid, unvendable
end

local function bag_enabled(id)
    local info = windower.ffxi.get_bag_info(id)
    return info and info.enabled and info.max and info.max > 0 and info or nil
end

local function slots(id)
    local info = bag_enabled(id)
    if not info then return {} end
    return windower.ffxi.get_items(id) or {}
end

local function total_in_bag(id, item_id)
    local sum = 0
    for _, item in pairs(slots(id)) do
        if type(item) == 'table' and item.id == item_id and item.count then
            sum = sum + item.count
        end
    end
    return sum
end

local function free_inventory()
    local info = bag_enabled(0)
    if not info then return 0 end
    return math.max(0, info.max - (info.count or 0))
end

local function find_inventory(allowed)
    local info = bag_enabled(0)
    if not info then return nil end
    local inventory = slots(0)
    for index = 1, info.max do
        local item = inventory[index]
        if item and item.count and item.count > 0 and allowed[item.id] and item.status == 0 then
            return index, item
        end
    end
end

local function find_source(allowed)
    for _, id in ipairs(SOURCE_BAGS) do
        local info = bag_enabled(id)
        if info then
            local items = slots(id)
            for index = 1, info.max do
                local item = items[index]
                if item and item.count and item.count > 0 and allowed[item.id] and item.status == 0 then
                    return id, index, item
                end
            end
        end
    end
end

local function count_profile(allowed)
    local result = {stacks = 0, units = 0, by_bag = {}}
    for _, bag_id in ipairs({0, 5, 6, 7}) do
        local info = bag_enabled(bag_id)
        if info then
            local stats = {stacks = 0, units = 0}
            for _, item in pairs(slots(bag_id)) do
                if type(item) == 'table' and allowed[item.id] and item.status == 0 and item.count and item.count > 0 then
                    stats.stacks = stats.stacks + 1
                    stats.units = stats.units + item.count
                end
            end
            result.by_bag[bag_id] = stats
            result.stacks = result.stacks + stats.stacks
            result.units = result.units + stats.units
        end
    end
    return result
end

local function resolve_selection(selection)
    if profiles[selection] then return profiles[selection] end
    local item = selection and get_item_res(selection)
    if item then return {[item.en] = true} end
end

local function preview(profile_name)
    local profile = resolve_selection(profile_name)
    if not profile then say('Unknown profile/item "' .. tostring(profile_name) .. '".'); return end
    local allowed, invalid, unvendable = allowed_items(profile)
    local count = count_profile(allowed)
    say(('Preview "%s": %d items in %d stacks across accessible bags.'):format(profile_name, count.units, count.stacks))
    for _, id in ipairs({0, 5, 6, 7}) do
        if count.by_bag[id] then
            local stat = count.by_bag[id]
            say(('  %s: %d items / %d stacks'):format(BAG_NAMES[id], stat.units, stat.stacks))
        end
    end
    if invalid + unvendable > 0 then
        say(('Profile contains %d unknown and %d NPC-unsellable names (skipped).'):format(invalid, unvendable))
    end
    say('Preview only; no inventory moved and no items sold.')
end

local function cancel(reason)
    if not batch then return end
    local s = batch
    batch = nil -- Any delayed tick or packet callback now becomes inert.
    say(('%s: moved %d stacks, confirmed sold %d items (%d stacks).'):format(
        reason, s.moved_stacks, s.sold_units, s.sold_stacks))
end

local function valid_merchant(s)
    local info = windower.ffxi.get_info()
    if not info or not info.logged_in or info.zone ~= s.zone then
        return false, 'zone/logout changed'
    end
    local npc = windower.ffxi.get_mob_by_id(s.npc_id)
    if not npc or npc.index ~= s.npc_index or npc.distance == nil or npc.distance > 36 then
        return false, 'merchant unavailable, changed or out of range'
    end
    return true
end

local function stop_if_bad(s)
    local ok, reason = valid_merchant(s)
    if not ok then cancel('Stopped: ' .. reason); return true end
    return false
end

local function start_sale(s, index, item)
    if stop_if_bad(s) then return end
    local current = slots(0)[index]
    if not current or current.id ~= item.id or current.count ~= item.count or current.status ~= 0 then
        cancel('Stopped: inventory changed before sale')
        return
    end
    local count = current.count
    if count > 65535 then cancel('Stopped: unsupported stack size'); return end
    s.pending = {kind='sale', id=item.id, slot=index, count=count, time=now(), ack=false}
    s.phase = 'waiting_sale'
    -- Existing Ivaar sale request/confirm pair, now strictly one in flight.
    windower.packets.inject_outgoing(0x084, string.char(
        0x84, 0x06, 0, 0, count % 256, math.floor(count / 256) % 256, 0, 0,
        current.id % 256, math.floor(current.id / 256) % 256, index, 0))
    windower.packets.inject_outgoing(0x085, string.char(0x85, 0x04, 0, 0, 1, 0, 0, 0))
end

local function start_move(s, bag_id, index, item)
    if stop_if_bad(s) then return end
    local current = slots(bag_id)[index]
    if not current or current.id ~= item.id or current.count ~= item.count or current.status ~= 0 then
        cancel('Stopped: storage changed before retrieval')
        return
    end
    s.pending = {kind='move', bag=bag_id, id=item.id, count=item.count,
        from=total_in_bag(bag_id, item.id), into=total_in_bag(0, item.id), time=now()}
    s.phase = 'waiting_move'
    local ok, result = pcall(windower.ffxi.move_item, bag_id, 0, index, item.count)
    if not ok or result == false then
        cancel('Stopped: Itemizer-style inventory movement failed')
    end
end

local function ask_shop(s)
    if stop_if_bad(s) then return end
    local p = windower.ffxi.get_player()
    if not p or p.status ~= 0 then
        -- The previous shop can remain open; reuse it if we have seen 0x03C.
        if s.shop_seen then s.phase = 'selling'; return end
        cancel('Stopped: not idle to interact with merchant')
        return
    end
    local selected = windower.ffxi.get_mob_by_target('t')
    if not selected or selected.id ~= s.npc_id then
        cancel('Stopped: selected target no longer matches merchant')
        return
    end
    s.shop_seen = false
    s.phase = 'waiting_shop'
    s.shop_time = now()
    local ok = pcall(function()
        packets.inject(packets.new('outgoing', 0x01A, {
            ['Target'] = s.npc_id, ['Target Index'] = s.npc_index, ['Category'] = 0,
        }))
    end)
    if not ok then cancel('Stopped: unable to interact automatically with vendor') end
end

local function tick(s)
    if batch ~= s then return end
    if stop_if_bad(s) then return end
    if s.phase == 'waiting_move' then
        local m = s.pending
        local from = total_in_bag(m.bag, m.id)
        local into = total_in_bag(0, m.id)
        if m.from - from >= m.count and into - m.into >= m.count then
            s.moved_stacks = s.moved_stacks + 1
            s.pulls_this_pass = s.pulls_this_pass + 1
            s.pending = nil
            s.phase = 'fetching'
        elseif now() - m.time >= MOVE_TIMEOUT then
            cancel('Stopped: storage move not confirmed; will not retry blindly')
        end
        return
    end
    if s.phase == 'waiting_sale' then
        local m = s.pending
        local item = slots(0)[m.slot]
        local remaining = (item and item.id == m.id and item.count) or 0
        if m.ack and remaining < m.count then
            -- Response plus inventory delta are both required before counting a sale.
            local sold = m.count - remaining
            s.sold_units = s.sold_units + sold
            s.sold_stacks = s.sold_stacks + 1
            s.pending = nil
            s.phase = 'selling'
        elseif now() - m.time >= SALE_TIMEOUT then
            cancel('Stopped: NPC sale confirmation or inventory update missing')
        end
        return
    end
    if s.phase == 'waiting_shop' then
        if now() - s.shop_time >= SHOP_TIMEOUT then
            cancel('Stopped: no shop response; try opening the vendor manually')
        end
        return
    end
    if s.phase == 'fetching' then
        local b, index, item = find_source(s.allowed)
        local inv_index = find_inventory(s.allowed)
        local free = free_inventory()
        if b and free > FREE_SLOTS_RESERVED and s.pulls_this_pass < MAX_PULLS_PER_PASS then
            start_move(s, b, index, item)
        elseif inv_index then
            s.phase = 'ready_to_shop'
        elseif b then
            cancel('Stopped: need free Inventory slots to retrieve remaining junk')
        else
            cancel('Completed')
        end
        return
    end
    if s.phase == 'ready_to_shop' then
        if s.shop_seen then s.phase = 'selling'
        else ask_shop(s) end
        return
    end
    if s.phase == 'selling' then
        local index, item = find_inventory(s.allowed)
        if index then
            start_sale(s, index, item)
        else
            s.pulls_this_pass = 0
            s.phase = 'fetching'
        end
    end
end

local function drive(s)
    coroutine.schedule(function()
        if batch ~= s then return end
        tick(s)
        if batch == s then drive(s) end
    end, 0.25)
end

local function start_batch(profile_name)
    if batch then say('A batch is already running; use //sellnpc status or //sellnpc stop.'); return end
    if next(sales_que) then say('Legacy sale queue pending; open the shop for that queue first.'); return end
    local profile = resolve_selection(profile_name)
    if not profile then say('Unknown profile/item "' .. tostring(profile_name) .. '".'); return end
    local player = windower.ffxi.get_player()
    local info = windower.ffxi.get_info()
    local target = windower.ffxi.get_mob_by_target('t')
    if not player or not info or not info.logged_in or player.status ~= 0 then
        say('Start while logged in and idle (outside menus).'); return
    end
    if not target or not target.id or not target.index or target.distance == nil or target.distance > 36 then
        say('Target a nearby NPC vendor first.'); return
    end
    if not bag_enabled(0) then say('Inventory unavailable.'); return end
    local allowed, invalid, unvendable = allowed_items(profile)
    local count = count_profile(allowed)
    if count.stacks == 0 then say(('No currently accessible "%s" items to sell.'):format(profile_name)); return end
    serial = serial + 1
    batch = {serial=serial, profile=profile_name, allowed=allowed, npc_id=target.id,
        npc_index=target.index, npc_name=target.name or 'NPC', zone=info.zone,
        moved_stacks=0, sold_stacks=0, sold_units=0, phase='fetching',
        pulls_this_pass=0, shop_seen=false}
    say(('Batch "%s" started at %s (%d items across %d stacks).'):format(
        profile_name, batch.npc_name, count.units, count.stacks))
    if invalid + unvendable > 0 then
        say(('Skipped %d unrecognized and %d NPC-unsellable profile entries.'):format(invalid, unvendable))
    end
    drive(batch)
end

local function legacy_add(name, silent)
    local item = get_item_res(windower.convert_auto_trans(name))
    if not item then
        say('"' .. name .. '" not a valid item name.')
    elseif not vendor_sellable(item) then
        say('Cannot sell "' .. item.en .. '" to NPC vendors.')
    else
        sales_que[item.id] = true
        if not silent then say('"' .. item.en .. '" added to sales queue.') end
    end
end

local function legacy_sell()
    local count = 0
    for index = 1, 80 do
        local item = windower.ffxi.get_items(0, index)
        if item and sales_que[item.id] and item.status == 0 then
            windower.packets.inject_outgoing(0x084,string.char(0x084,0x06,0,0,
                item.count,0,0,0,item.id%256,math.floor(item.id/256)%256,index,0))
            windower.packets.inject_outgoing(0x085,string.char(0x085,0x04,0,0,1,0,0,0))
            count = count + item.count
        end
    end
    sales_que = {}
    if count > 0 then say(('Selling %d items.'):format(count)) end
end

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if injected or blocked then return end
    if batch then
        if id == 0x03C and batch.phase == 'waiting_shop' then
            if stop_if_bad(batch) then return end
            batch.shop_seen = true
            batch.phase = 'selling'
        elseif id == 0x03D and batch.phase == 'waiting_sale' and batch.pending then
            local ok, result = pcall(packets.parse, 'incoming', modified or original)
            if ok and result and result.Type == 1 and
               tonumber(result['Inventory Index']) == batch.pending.slot then
                batch.pending.ack = true
            end
        end
    elseif id == 0x03C and next(sales_que) then
        legacy_sell()
    end
end)

windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or 'help'
    if command == 'help' then
        say('//sellnpc preview <profile/item> | batch <profile/item> | status | stop')
        say('//sellnpc <profile/item name>  (legacy single shop-open queue)')
    elseif command == 'preview' then
        preview(#args > 0 and table.concat(args, ' '):lower() or nil)
    elseif command == 'batch' then
        start_batch(#args > 0 and table.concat(args, ' '):lower() or nil)
    elseif command == 'stop' then
        if batch then cancel('Stopped by user') else say('No active batch.') end
    elseif command == 'status' then
        if batch then
            say(('%s at %s: %s, moved %d stacks; confirmed sold %d items / %d stacks.'):format(
                batch.profile, batch.npc_name, batch.phase,
                batch.moved_stacks, batch.sold_units, batch.sold_stacks))
        else say('No active batch.') end
    elseif batch then
        say('Batch active: only status and stop are accepted until it finishes.')
    elseif profiles[command] then
        for name in pairs(profiles[command]) do legacy_add(name, true) end
        say('Loaded profile "' .. command .. '"')
    else
        legacy_add(table.concat({command, ...}, ' '))
    end
end)

windower.register_event('zone change', function() cancel('Stopped: zoning') end)
windower.register_event('logout', function() cancel('Stopped: logout') end)
windower.register_event('unload', function() cancel('Stopped: unloaded') end)
