require('lists')
require('chat')
texts = require('texts')
config = require('config')
packets = require('packets')
res_items = require('resources').items
res_zones = require('resources').zones
extdata = require 'extdata'

windower.send_command('unload bidder')

_addon.command = 'AH'
_addon.name = 'AuctionHelper'
_addon.version = '1.26.11.02-bid1'
_addon.author = 'Ivaar'

default = {
    auction_list = {
        display=true,
        timer=true,
        date=true,
        price=false,
        empty=true,
        slot=true,
    },
    display = {text = {size = 10,font = 'Consolas'},pos = {x = 390,y = 50}}
}

settings = config.load(default)
auction_list = texts.new(settings.display)

zones = {}
zones.ah = L{'Bastok Mines', 'Bastok Markets', 'Norg', 'Southern San d\'Oria', 'Port San d\'Oria', 'Rabao', 'Windurst Woods', 'Windurst Walls', 'Kazham', 'Lower Jeuno', 'Ru\'Lude Gardens', 'Port Jeuno', 'Upper Jeuno', 'Aht Urhgan Whitegate', 'Al Zahbi', 'Nashmau', 'Tavnazian Safehold', 'Western Adoulin', 'Eastern Adoulin'}
zones.mh = {}

-- A last-bid shortcut is intentionally manual; it never automatically retries.
local last_buy = nil

local function ah_message(topic, body)
    windower.add_to_chat(0, string.color('[AuctionHelper] ', 167)
        .. string.color(topic, 200) .. string.color(' -> ', 200) .. tostring(body))
end

local function ah_help()
    local function line(command, explanation)
        windower.add_to_chat(0, string.color('  //ah ', 200)
            .. string.color(command, 207) .. string.color(' -> ', 200) .. explanation)
    end
    windower.add_to_chat(0, string.color('========================================', 140))
    windower.add_to_chat(0, string.color('AuctionHelper  |  Commands', 167))
    windower.add_to_chat(0, string.color('========================================', 140))
    line('<item> <bid> [1|single|12|stack]', 'Buy; default stack if stackable.')
    line('Silk Thread 5000 1', 'Example: bid on one item.')
    line('Silk Thread 60000 12', 'Example: bid on a stack.')
    line('bid <price>', 'Rebid the previously selected item and size.')
    line('buy <item> <0|1> <price>', 'Legacy buy (0 single, 1 stack).')
    line('sell <item> <0|1> <price>', 'Legacy sell (0 single, 1 stack).')
    line('clear sold', 'Clear finished auction slots.')
    line('show | hide | save', 'Manage the sales display.')
    line('status | help | restart | unload', 'Addon commands.')
    windower.add_to_chat(0, string.color('========================================', 140))
end

local function at_auction_house()
    local info = windower.ffxi.get_info()
    return info and res_zones[info.zone] and zones.ah:contains(res_zones[info.zone].name)
end

-- Only the new shorthand treats 1 as single and 12 as stack.
-- Legacy buy/sell retain 0=single and 1=stack to prevent regressions.
local function shorthand_size(value)
    if not value then return nil end
    local key = value:lower()
    if key == '1' or key == 'single' then return 'single' end
    if key == '12' or key == 'stack' then return 'stack' end
    return nil
end

local function submit_buy(name, size, price)
    if not at_auction_house() then
        ah_message('Bid', 'Visit an Auction House zone before bidding.')
        return
    end
    if actions or (lclock and os.clock() < lclock) then
        ah_message('Bid', 'Please allow the previous action to finish.')
        return
    end
    if ah_proposal('buy', name, size, price) then
        lclock = os.clock() + 3
    end
end

local function parse_short_bid(words)
    local n = #words
    if n < 2 then return nil end
    local size = shorthand_size(words[n])
    local price_index = size and n - 1 or n
    if price_index < 2 or not words[price_index]:match('^%d[%d,.]*$') then
        return nil
    end
    return table.concat(words, ' ', 1, price_index - 1), size or 'auto', words[price_index]
end


function timef(ts)
    --return string.format('%.2d:%.2d:%.2d',ts/(60*60), ts/60%60, ts%60);
    return string.format('%d days %.2d:%.2d:%.2d',ts/(60*60*24), ts/(60*60)%24, ts/60%60, ts%60);
end;

local display_box = function()
    local outstr = '';
    for x = 0,6 do
        if (auction_box[x] ~= nil) then
            local str = '';
            if (settings.auction_list.empty == true or auction_box[x].status ~= 'Empty') then
                if (settings.auction_list.slot) == true then
                    str = str..string.format(' Slot:%s', x+1)
                end
                str = str..string.format(' %s',auction_box[x].status);
            end	
            if (auction_box[x].status ~= 'Empty') then
                local timer = auction_box[x].status == 'On auction' and auction_box[x].timestamp+829440 or auction_box[x].timestamp
                if (settings.auction_list.timer) then
                    str = str..string.format(' %s',(auction_box[x].status == 'On auction' and os.time()-timer > 0) and 'Expired' or timef(math.abs(os.time()-timer)))
                end
                if (settings.auction_list.date) then
                    str = str..string.format(' [%s]',os.date('%c', timer))
                end
                str = str..string.format(' %s ',auction_box[x].name)
                if (auction_box[x].count ~= 1) then
                    str = str..string.format('x%d ',auction_box[x].count)
                end
                if (settings.auction_list.price) then
                    str = str..string.format('[%s] ',comma_value(auction_box[x].price));
                end
            end
            if (str ~= '') then 
                outstr = outstr ~= '' and outstr .. '\n' .. str or str
            end
        end
    end
    return outstr;
end;

windower.register_event('prerender', function()
    if auction_box and settings.auction_list.display then
        auction_list:text(display_box())
        auction_list:show()
    --else
    --	auction_list:hide()
    end
end)

windower.register_event('logout', function()
    auction_box = nil
    auction_list:hide()
end)

windower.register_event('addon command', function(...)
    local words = {...}
    local action = words[1] and words[1]:lower()

    if not action then
        if at_auction_house() and (not lclock or os.clock() >= lclock) then
            lclock = os.clock() + 1
            open_menu_command()
        else
            ah_help()
        end
        return
    elseif action == 'help' then
        ah_help()
        return
    elseif action == 'status' then
        ah_message('Status', 'v' .. _addon.version .. ' | Default: stack | Last: '
            .. (last_buy and (last_buy.name .. ' (' .. last_buy.size .. ')') or 'none'))
        return
    elseif action == 'restart' or action == 'unload' then
        ah_message('Lifecycle', action == 'restart' and 'Restarting.' or 'Unloading.')
        windower.send_command(action == 'restart' and 'lua r AuctionHelper' or 'lua u AuctionHelper')
        return
    elseif action == 'bid' then
        if #words ~= 2 or not last_buy then
            ah_message('Usage', 'First use //ah <item> <price> [single|stack]; then //ah bid <price>.')
        else
            submit_buy(last_buy.name, last_buy.size, words[2])
        end
        return
    elseif action == 'buy' or action == 'sell' then
        if #words < 4 then
            ah_message('Usage', '//ah ' .. action .. ' <item> <0|1> <price>')
        elseif not at_auction_house() then
            ah_message('Auction', 'Visit an Auction House zone first.')
        elseif actions or (lclock and os.clock() < lclock) then
            ah_message('Auction', 'Please allow the previous action to finish.')
        else
            if ah_proposal(action, table.concat(words, ' ', 2, #words - 2),
                    words[#words - 1]:lower(), words[#words]) then
                lclock = os.clock() + 3
            end
        end
        return
    elseif action == 'clear' then
        if words[2] and words[2]:lower() == 'sold' and auction_box and at_auction_house() then
            remove_sold()
            ah_message('Auction', 'Clearing finished auction slots.')
        else
            ah_message('Usage', '//ah clear sold (after opening the Auction House).')
        end
        return
    elseif action == 'show' or action == 'hide' then
        local enabled = action == 'show'
        if not words[2] then
            settings.auction_list.display = enabled
            auction_list:visible(enabled)
        elseif default.auction_list[words[2]:lower()] ~= nil then
            settings.auction_list[words[2]:lower()] = enabled
        else
            ah_help()
            return
        end
        ah_message('Display', enabled and 'Shown.' or 'Hidden.')
        return
    elseif action == 'save' then
        config.save(settings, 'all')
        ah_message('Settings', 'Saved.')
        return
    elseif action == 'eval' then
        assert(loadstring(table.concat(words, ' ', 2)))()
        return
    end

    local name, size, price = parse_short_bid(words)
    if name then
        submit_buy(name, size, price)
    else
        ah_message('Usage', 'Expected //ah <item> <price> [1|single|12|stack].')
        ah_help()
    end
end)

windower.register_event('unhandled command', function(...)
    local commands = {...}
    commands[1] = commands[1]:lower()
    if commands[1] ~= 'bazaar' and commands[1] ~= 'buy' and commands[1] ~= 'sell' and commands[1] ~= 'inbox' and commands[1] ~= 'outbox' and commands[1] ~= 'ibox' and commands[1] ~= 'obox' and commands[1] ~= 'dbox' then return end
    if commands[1] == 'bazaar' and #commands >= 3 then
        bazaar_item(table.concat(commands, ' ',2,#commands-1):lower(),commands[#commands])
    end
    if actions or not zones.ah:contains(res_zones[windower.ffxi.get_info().zone].name) then return end
    local now = os.clock()
    if not lclock or lclock < now then
        if (commands[1] == 'outbox' or commands[1] == 'obox') then	
            lclock = now+3
            local obox = string.char(0x4B,0x0A,0x00,0x00,0x0D,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF)
            --print('Modified packet 0x04B: %s\n%s bytes':format(space_hex(obox:hex()),#obox))
            windower.packets.inject_incoming(0x4B,obox)
        elseif (commands[1] == 'inbox' or commands[1] == 'ibox' or commands[1] == 'dbox') then
            lclock = now+3
            local ibox = string.char(0x4B,0x0A,0x00,0x00,0x0E,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF)
            --print('Modified packet 0x04B: %s\n%s bytes':format(space_hex(ibox:hex()),#ibox))
            windower.packets.inject_incoming(0x4B,ibox)
        elseif (commands[1] == 'buy' or commands[1] == 'sell') and commands[4] then
            if ah_proposal(commands[1],table.concat(commands, ' ',2,#commands-2):lower(),commands[#commands-1]:lower(),commands[#commands]) then lclock = now+3 end
        end
    end
end)

function update_sales_status(packet)
    if auction_box and packet.Slot ~= 7 and packet['Sale status'] ~= 0x02 and packet['Sale status'] ~= 0x04 and packet['Sale status'] ~= 0x10 then
        if packet['Sale status'] == 0 then
            auction_box[packet.Slot] = {}
            auction_box[packet.Slot].status = 'Empty'	
        else
            if packet['Sale status'] == 0x03 then
                auction_box[packet.Slot].status = 'On auction'
            elseif packet['Sale status'] == 0x0A or packet['Sale status'] == 0x0C or packet['Sale status'] == 0x15 then
                auction_box[packet.Slot].status = 'Sold'	
            elseif packet['Sale status'] == 0x0B or packet['Sale status'] == 0x0D or packet['Sale status'] == 0x16 then
                auction_box[packet.Slot].status = 'Not Sold'
            end
            auction_box[packet.Slot].timestamp = packet['Timestamp']
            auction_box[packet.Slot].price = packet['Price']
            auction_box[packet.Slot].item = packet['Item']
            auction_box[packet.Slot].count = packet['Count']
            auction_box[packet.Slot].name = res_items[packet['Item']].en
            --auction_box[packet.Slot].category = packet['AH Category']
        end
    end
end	--packet['Name'])

function find_empty_slot()
    if auction_box then
        for x = 0,6 do
            if auction_box[x] and auction_box[x].status == 'Empty' then
                return x
            end
        end
    end
    return nil
end

function bazaar_item(item_name,price)
    if not windower.ffxi.get_player() then return end
    local item = get_item_res(item_name)
    if not item then 
        print('AH Error: %s not a valid item name.':format(item_name)) 
        return false
    end
    if item.flags['No PC Trade'] == true or item.flags['Linkshell'] == true then 
        print(item.flags)
        return false
    end
    price = format_price(price)
    if not price or price > 99999999 then print('AH Error: Invalid price.') return false end
    actions = true
    for ind,inv_item in ipairs(windower.ffxi.get_items(0)) do
        if inv_item and inv_item.id == item.id and (inv_item.status == 0 or inv_item.status == 25) then
            bazaar_set_price(ind,price)
        end
    end
    actions = false
end

function bazaar_set_price(index,price)   
    if bazaar then
        local set_bazaar = packets.new('outgoing', 0x10A, {['Inventory Index'] = index,['Price'] = price})
        packets.inject(set_bazaar)
        coroutine.sleep(1+math.random())
    end
end

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if id == 0x04C then
        local packet = packets.parse('incoming',original)
        if packet['Type'] == 0x04 then
            local last_4e = windower.packets.last_outgoing(0x04E)
            local slot = find_empty_slot()
            local price = last_4e:sub(9,12)
            local fee = original:byte(9)+original:byte(10)*256+original:byte(11)*256^2+original:byte(12)*256^3
            if last_4e:byte(3)+last_4e:byte(4) == 0 and slot and packet['Success'] == 1 and last_4e:byte(5) == 0x04 and original:sub(13,17) == last_4e:sub(13,17) and windower.ffxi.get_items().gil >= fee then
                local sell_confirm = string.char(0x4E,0x1E,0,0,0x0B,slot,0,0)..last_4e:sub(9,12)..original:sub(13,14)..string.char(0,0)..last_4e:sub(17)	
                coroutine.sleep(math.random())
                --print('Modified packet 0x04E: %s\n%s bytes':format(space_hex(sell_confirm:hex()),#sell_confirm))
                windower.packets.inject_outgoing(0x4E,sell_confirm)
            end	
        elseif packet['Type'] == 0x0A then
            if original:byte(7) == 1 then
                if not auction_box then auction_box = {} end
                if not auction_box[packet.Slot] then auction_box[packet.Slot] = {} end
                update_sales_status(packet)
            end
        elseif packet['Type'] == 0x0B or packet['Type'] == 0x0D then
            if original:byte(7) == 1 then
                update_sales_status(packet)
            end
        elseif packet['Type'] == 0x0C or packet['Type'] == 0x10 then
            if original:byte(7) == 1 then
                update_sales_status({['Slot']=original:byte(6),['Sale status']=0})
            end
        elseif packet['Type'] == 0x0E then
            if original:byte(7) == 1 then
                ah_message('Bid', 'Successful.')
            elseif original:byte(7) == 0xC5 then
                ah_message('Bid', 'Unsuccessful. Try //ah bid <price> with a higher amount.')
            end
        end
    end
end)


windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
    if id == 0x10B then
        bazaar = true
    elseif id == 0x109 then
        bazaar = false
    end
end)

function comma_value(n) -- credit http://richard.warburton.it
    local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function space_hex(n)
    local left,num,right = string.match(n,'^([^%x]*%x)(%x*)(.-)$')
    return left..(num:reverse():gsub('(%x%x)','%1 '):reverse())..right
end

function get_item_res(item)
    item = windower.convert_auto_trans(item)
    for k,v in pairs(res_items) do
        if v.en:lower() == item:lower() or v.enl:lower() == item:lower() then
            return v
        end
    end
    return nil
end

function find_item(item_id,item_count,max_charges)
    local items = windower.ffxi.get_items(0)
    for ind,item in ipairs(items) do
        if item and item.id == item_id and item.count >= item_count and item.status == 0 and
            (not max_charges or max_charges == extdata.decode(item).charges_remaining) then
                return ind
        end
    end
    return false
end

function open_menu_command()
    if not windower.ffxi.get_player() then return end
    local o_menu = string.char(0x4C,0x1E,0,0,0x02,0,0x01,0)..string.char(0,0,0,0,0,0,0,0)
    o_menu = o_menu..string.char(0,0,0,0,0,0,0,0)..string.char(0,0,0,0,0,0,0,0)
    o_menu = o_menu..string.char(0,0,0,0,0,0,0,0)..string.char(0,0,0,0,0,0,0,0)
    o_menu = o_menu..string.char(0,0,0,0,0,0,0,0)..string.char(0,0,0,0)
    --print('Modified packet 0x04C: %s\n%s bytes':format(space_hex(o_menu:hex()),#o_menu))
    windower.packets.inject_incoming(0x4C,o_menu)
end

function remove_sold()
   if not windower.ffxi.get_player() then return end
   actions = true
   for slot=0,6 do
       if auction_box and slot and auction_box[slot] and (auction_box[slot].status == 'Sold' or auction_box[slot].status == 'Not Sold') then
            local i_sold = string.char(0x4E,0x1E,0,0,0x10,slot,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
            --print('Modified packet 0x04E: %s\n%s bytes':format(space_hex(i_sold:hex()),#i_sold))
            windower.packets.inject_outgoing(0x4E,i_sold)

            -- local i_sold = packets.new('outgoing', 0x4E, {['Type'] = 'Item sold',['Slot'] = slot})
           -- print(packets.build(i_sold):hex())
            coroutine.sleep(1+math.random())
        end
    end
    actions = false
end

function format_price(price)
    if type(price) ~= 'string' or not price:match('^%d[%d,.]*$') then
        return nil
    end
    local numeric = tonumber(price:gsub('[,.]', ''))
    if not numeric or numeric < 1 or numeric > 4294967295 then
        return nil
    end
    return numeric
end

function stack_conv()
    local single
    if (item.stack ~= 1) and (vol == '1' or vol == 'stack') then
        single = 0
    elseif vol == '0' or vol == 'single' then
        single = 1
    else print('AH Error: Specify Stack or Single') return false end
end    

function ah_proposal(bid, item_name, vol, price)
    if not windower.ffxi.get_player() then return end
    local item = get_item_res(item_name)
    if not item then ah_message('Item', item_name .. ' was not found.') return false end
    
    if item.flags['No Auction'] == true then ah_message('Item', item.en .. ' cannot be traded on the Auction House.') return false end

    local single
    if vol == 'auto' or vol == nil then
        single = item.stack == 1 and 1 or 0
    elseif (item.stack ~= 1) and (vol == '1' or vol == 'stack') then
        single = 0
    elseif vol == '0' or vol == 'single' then
        single = 1
    else
        ah_message('Item', 'Invalid size for ' .. item.en .. '. Use single or stack.')
        return false
    end

    local trans = string.char(0x4E,0x1E,0,0)
    
    price = format_price(price)
    
    if bid == 'buy' and price and tonumber(price) <= windower.ffxi.get_items().gil then
        local slot = find_empty_slot() == nil and 0x07 or find_empty_slot()
        trans = trans..string.char(0x0E,slot,0,0, (price%256), (math.floor((price/256)%256)), (math.floor((price/65536)%256)), (math.floor((price/16777216)%256)), (item.id%256), (math.floor((item.id/256)%256)),0,0)
        --print('%s "%s" %s %s ID:%s':format(bid, item.en, comma_value(price),single == 1 and '[Single]' or '[Stack]',item.id))
    elseif bid == 'sell' and price and tonumber(price) <= 999999999 then
        if not auction_box then ah_message('Sell', 'Open the Auction House to initialize sales first.') return	end
        if not find_empty_slot() then ah_message('Sell', 'No empty sales slots available.') return end
        trans = trans.. string.char(0x04,0,0,0, (price%256), (math.floor((price/256)%256)), (math.floor((price/65536)%256)), (math.floor((price/16777216)%256)))
        local index = find_item(item.id, single == 1 and single or item.stack, item.max_charges)
        if not index then print('AH Error: %s of %s not found in inventory.':format(single == 1 and 'Single' or 'Stack',item.en)) return end
        trans = trans..string.char((index%256), (math.floor((index/256)%256)), (item.id%256), (math.floor((item.id/256)%256)))
        --print('%s "%s" %s %s ID:%s Ind:%s':format(bid, item.en, comma_value(price),single == 1 and '[Single]' or '[Stack]',item.id,index))
    else
        ah_message('Price', 'Invalid price or insufficient gil.')
        return false 
    end
    
    trans = trans..string.char(single,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    --print('Modified packet 0x04E: %s\n%s bytes':format(space_hex(trans:hex()),#trans))	
    windower.packets.inject_outgoing(0x4E,trans)
    if bid == 'buy' then
        last_buy = {name = item.en, size = single == 1 and 'single' or 'stack', price = price}
        ah_message('Bid', string.format('%s (%s) for %s gil submitted.',
            item.en, last_buy.size, comma_value(tostring(price))))
    else
        ah_message('Sell', string.format('%s (%s) for %s gil submitted.',
            item.en, single == 1 and 'single' or 'stack', comma_value(tostring(price))))
    end
    return true
end
-----------------------------------------------------------------------------------------------------
--print('AHPack buy "short or full item name" 0 10,000\n single OR 0 and stack OR 1.')
-----------------------------------------------------------------------------------------------------
