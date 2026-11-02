-- No Windower/FFXI is contacted. Miniature deterministic API simulation.
local PATH = 'SellNPC.lua'
local fake_time = 1000
os.time = function() return fake_time end
local function scenario(label, data, opts)
    opts = opts or {}
    local events, queued, messages, moves, sales, channels = {}, {}, {}, {}, {}, {}
    local char = {status=0}
    local zone=100
    local mob={id=12345,index=110,name='Test Vendor',distance=5}
    local target=mob
    local pending_slot
    local base = {[0]=data.inv or {},[5]=data.satchel or {},[6]=data.sack or {},[7]=data.case or {}}
    local max={ [0]=opts.max_inv or 6,[5]=80,[6]=80,[7]=80 }
    local function count(bag)
        local n=0 for i=1,max[bag] do if base[bag][i] and base[bag][i].id~=0 then n=n+1 end end return n
    end
    local function invoke(name,...)
        for _,fn in ipairs(events[name] or {}) do fn(...) end
    end
    local function schedule(fn,time) queued[#queued+1]=fn end
    coroutine.schedule=schedule
    _G._addon={}
    _G.windower={
        addon_path='/tmp/test/',
        add_to_chat=function(ch,s) channels[#channels+1]=ch; messages[#messages+1]=s end,
        convert_auto_trans=function(s) return s end,
        register_event=function(ev,fn)
            if type(ev)~='string' then error('bad event') end
            events[ev]=events[ev] or {};table.insert(events[ev],fn)
        end,
        ffxi={
            get_player=function() return char end,
            get_info=function() return {logged_in=true,zone=zone} end,
            get_mob_by_id=function(id) return id==mob.id and mob or nil end,
            get_mob_by_target=function(which) return which=='t' and target or nil end,
            get_items=function(bag,slot)
                if slot then return (base[bag] or {})[slot] end
                return base[bag]
            end,
            get_bag_info=function(bag)
                if max[bag] then return {enabled=true,max=max[bag],count=count(bag)} end
            end,
            move_item=function(src,dst,slot,amount)
                moves[#moves+1]={src=src,slot=slot,count=amount}
                if opts.no_move then return true end
                local item=base[src][slot];assert(item and item.count==amount)
                local free
                for i=1,max[dst] do if not base[dst][i] then free=i;break end end
                assert(free,'inventory full in fake move')
                base[dst][free]={id=item.id,count=item.count,status=0}
                base[src][slot]=nil
                return true
            end,
        },
        packets={inject_outgoing=function(id,bytes)
            if id==0x084 then
                pending_slot=bytes:byte(11)
            elseif id==0x085 then
                local item=base[0][pending_slot]
                assert(item and item.count>0,'sale requested for missing item')
                sales[#sales+1]={slot=pending_slot,id=item.id,count=item.count}
                if not opts.no_ack then
                    local slot=pending_slot
                    invoke('incoming chunk',0x03D,'',nil,false,false)
                    base[0][slot]=nil
                end
            end
        end}
    }
    package.loaded['resources']=nil;package.loaded['profiles']=nil;package.loaded['packets']=nil;package.loaded['sets']=nil;package.loaded['chat']=nil
    package.preload['sets']=function() return {} end
    package.preload['chat']=function() string.color=function(s,col) return ('<%d>%s</>'):format(col,s) end;return {} end
    package.preload['resources']=function()return {items={
        [1]={id=1,en='Animal Glue',enl='Animal Glue',flags={}},
        [2]={id=2,en='Bat Wing',enl='Bat Wing',flags={}},
        [3]={id=3,en='Bird Feather',enl='Bird Feather',flags={}},
        [4]={id=4,en='Forbidden',enl='Forbidden',flags={['No NPC Sale']=true}}}}
    end
    package.preload['profiles']=function()return {junk={['Animal Glue']=true,['Bat Wing']=true,['Bird Feather']=true,['Forbidden']=true}} end
    package.preload['packets']=function()return {
        new=function(direction,id,fields) assert(id==0x01A); assert(fields.Target==mob.id);return fields end,
        inject=function(fields) if not opts.no_shop then invoke('incoming chunk',0x03C,'',nil,false,false) end end,
        parse=function(direction,bytes) return {Type=1,['Inventory Index']=pending_slot} end
    } end
    assert(loadfile(PATH))()
    local function cmd(...) invoke('addon command',...) end
    local function pump(limit)
        for i=1,(limit or 200) do
            if #queued==0 then break end
            local fn=table.remove(queued,1);fn()
        end
    end
    local function advance(sec) fake_time=fake_time+sec end
    return {cmd=cmd,pump=pump,advance=advance,base=base,moves=moves,sales=sales,messages=messages,channels=channels,
        shop=function()invoke('incoming chunk',0x03C,'',nil,false,false) end,
        get_target=function()return target end,set_target=function(m)target=m end,
        set_zone=function(z)zone=z;invoke('zone change') end,
        set_distance=function(dist)mob.distance=dist end}
end
local function contains(lines,needle)
 for _,s in ipairs(lines) do if s:find(needle,1,true) then return true end end
 return false
end
local a=scenario('many passes',{inv={{id=2,count=2,status=0}},satchel={
 {id=1,count=5,status=0},{id=1,count=8,status=0},
 {id=2,count=9,status=0},{id=3,count=6,status=0},
 {id=3,count=3,status=0}}},{max_inv=4})
a.cmd('preview','junk')
assert(#a.moves==0 and #a.sales==0)
assert(contains(a.messages,'33 items in 6 stacks'))
a.cmd('batch','junk');a.pump(300)
assert(#a.sales==6, 'expected 6 sales, got '..#a.sales)
assert(#a.moves==5,'expected 5 retrievals')
assert(contains(a.messages,"Completed: moved 5 stacks, confirmed sold 33 items (6 stacks)."))
assert(contains(a.messages,'Retrieving 5 x Animal Glue from Satchel'))
assert(contains(a.messages,'Retrieved 5 x Animal Glue from Satchel'))
assert(contains(a.messages,'Opening shop with Test Vendor'))
assert(contains(a.messages,'Shop response received from Test Vendor'))
assert(contains(a.messages,'Selling 2 x Bat Wing to Test Vendor'))
assert(contains(a.messages,'Confirmed 2 x Bat Wing sold to Test Vendor'))
assert(contains(a.messages,'Checking storage for more.'))
assert(contains(a.messages,'<167>SellNPC</>') and contains(a.messages,'<200>-></>'), 'color formatting missing')
for _,channel in ipairs(a.channels) do assert(channel==0, 'messages must use chat mode 0') end
local menu=scenario('help',{inv={{id=1,count=2,status=0}}})
menu.cmd('help')
assert(contains(menu.messages,'<140>-------- </>') and contains(menu.messages,'<200>//sellnpc</>'))
local b=scenario('no ack',{inv={{id=1,count=4,status=0}}},{no_ack=true})
b.cmd('batch','junk');b.pump(12);b.advance(10);b.pump(40)
assert(contains(b.messages,'Stopped: NPC sale confirmation or inventory update missing'))
assert(#b.sales==1,'must never double sell without confirmation')
local c=scenario('no shop',{inv={{id=1,count=3,status=0}}},{no_shop=true})
c.cmd('batch','junk');c.pump(10);c.advance(11);c.pump(20)
assert(#c.sales==0 and contains(c.messages,'no shop response'))
local d=scenario('legacy',{inv={{id=1,count=3,status=0}}})
d.cmd('Animal','Glue');d.pump(1)
assert(#d.sales==0)
d.shop();assert(#d.sales==1, 'legacy mode should sell on shop open')
local e=scenario('cancel',{satchel={{id=1,count=5,status=0}}})
e.cmd('batch','junk');e.cmd('stop');e.pump(50)
assert(#e.moves==0 and #e.sales==0)
local f=scenario('move never completes',{satchel={{id=1,count=3,status=0}}},{no_move=true})
f.cmd('batch','Animal','Glue');f.pump(10);f.advance(9);f.pump(30)
assert(contains(f.messages,'storage move not confirmed'))
assert(#f.sales==0 and #f.moves==1)
local g=scenario('zone cancel',{satchel={{id=1,count=3,status=0}}})
g.cmd('batch','junk');g.set_zone(200);g.pump(30)
assert(#g.sales==0 and #g.moves==0)
local h=scenario('unknown target',{inv={{id=1,count=3,status=0}}})
h.set_target(nil);h.cmd('batch','junk');h.pump(10)
assert(contains(h.messages,'Target a nearby NPC vendor first.'))
local k=scenario('target changed mid-run',{satchel={{id=1,count=4,status=0}}})
k.cmd('batch','junk');k.set_target({id=999,index=111,name='Wrong Vendor',distance=5});k.pump(100)
assert(#k.moves==1 and #k.sales==1, 'target change should not cancel: saved NPC remains nearby')
assert(not contains(k.messages,'target changed during vendor batch'))
local k2=scenario('target cleared mid-run',{satchel={{id=1,count=4,status=0}}})
k2.cmd('batch','junk');k2.set_target(nil);k2.pump(100)
assert(#k2.sales==1,'target can be cleared while the original vendor remains nearby')
local k3=scenario('saved merchant out of range',{satchel={{id=1,count=4,status=0}}})
k3.cmd('batch','junk');k3.set_distance(50);k3.pump(30)
assert(#k3.moves==0 and #k3.sales==0 and contains(k3.messages,'out of range'))
local j=scenario('single-name scope',{inv={{id=1,count=3,status=0},{id=2,count=6,status=0}}})
j.cmd('batch','Animal','Glue');j.pump(100)
assert(#j.sales==1 and j.sales[1].id==1, 'batch item should not sell bat wing')
print('SIMULATION PASS: BattleMod chat, per-stack progress, help, preview, multi-pass move/sell, legacy, single-name, timeouts, stop, zone and saved-vendor guards')
