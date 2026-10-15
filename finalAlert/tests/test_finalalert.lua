-- Mocked Windower integration checks. Run from repository root with Lua 5.1+:
-- lua finalAlert/tests/test_finalalert.lua
local source = 'finalAlert/finalAlert.lua'
if not io.open(source, 'r') then source = 'repo/' .. source end
local root = source:gsub('finalAlert.lua$', '')
local function check(value, message) assert(value, message or 'assertion failed') end
local function equal(a,b) assert(a==b, tostring(a) .. ' ~= ' .. tostring(b)) end
function S(t)
    local result={}
    for _,v in ipairs(t) do result[v]=true end
    return setmetatable(result,{__index={
        contains=function(self,k) return self[k]==true end,
        add=function(self,k) self[k]=true end,
        remove=function(self,k) self[k]=nil end,
    }})
end
local function session(saved)
    local c={time=100,events={},objects={},prims={},sounds={},messages={},commands={},saves=0,writes=0,
        viewport={x_res=1920,y_res=1080,ui_x_res=1920,ui_y_res=1080}}
    c.target={id=1001,is_npc=true,hpp=100}
    for _,module in ipairs({'config','texts','resources','chat','socket'}) do package.loaded[module]=nil end
    package.preload.config=function() return {load=function(defaults)
        for k,v in pairs(saved or {}) do defaults[k]=v end
        c.settings=defaults
        defaults.save=function() c.saves=c.saves+1 end
        return defaults
    end} end
    package.preload.texts=function() return {new=function(options)
        local t={content='',is_visible=false,x=0,y=0,font_size=12,opacity=255,
            draggable_flag=not options.flags or options.flags.draggable~=false}
        t.text=function(self,value) if value==nil then return self.content end;c.writes=c.writes+1;self.content=value end
        t.size=function(self,value) self.font_size=value end
        t.extents=function(self) return #self.content*self.font_size*0.6,self.font_size+2 end
        t.alpha=function(self,value) if value==nil then return self.opacity end;self.opacity=value end
        t.pos=function(self,x,y) self.x,self.y=x,y end
        t.show=function(self) self.is_visible=true end
        t.hide=function(self) self.is_visible=false end
        t.bg_visible=function() end
        t.bold=function() end
        t.color=function() end
        t.destroy=function(self) check(not self.destroyed,'double text destroy');self.destroyed=true end
        t.hover=function(self,x,y)
            local w,h=self:extents()
            return self.is_visible and x>=self.x and x<=self.x+w and y>=self.y and y<=self.y+h
        end
        c.objects[#c.objects+1]=t
        return t
    end} end
    package.preload.resources=function() return {
        spells={[1]={name='Fire'},[2]={name='Blizzard'}},
        monster_abilities={[300]={name='Self-Destruct'},[301]={name='Roar'}},
        weapon_skills={[42]={name='Blade: Ten'}},
    } end
    package.preload.chat=function() string.color=function(s,code) c.help_colors=c.help_colors or {};c.help_colors[code]=true;return s end;return {} end
    package.preload.socket=function() return {gettime=function() return c.time end} end
    _addon={}
    windower={addon_path=root,prim={},ffxi={},get_windower_settings=function() return c.viewport end,
        register_event=function(name,fn) c.events[name]=fn end,
        add_to_chat=function(code,line) c.messages[#c.messages+1]={code,line} end,
        play_sound=function(path) c.sounds[#c.sounds+1]=path end,
        send_command=function(line) c.commands[#c.commands+1]=line end}
    windower.ffxi.get_mob_by_target=function(which) return which=='t' and c.target or c.battle end
    windower.prim.create=function(name) check(not c.prims[name],'duplicate primitive');c.prims[name]={} end
    windower.prim.delete=function(name) check(c.prims[name],'unknown primitive');c.prims[name].deleted=true end
    windower.prim.set_texture=function(name,path)
        local f=assert(io.open(path,'rb'),'missing texture: '..path);f:close();c.prims[name].texture=path
    end
    windower.prim.set_fit_to_texture=function() end
    windower.prim.set_position=function(name,x,y) c.writes=c.writes+1;c.prims[name].x,c.prims[name].y=x,y end
    windower.prim.set_size=function(name,w,h) c.prims[name].w,c.prims[name].h=w,h end
    windower.prim.set_visibility=function(name,value) c.prims[name].visible=value end
    windower.prim.set_color=function(name,a,r,g,b)
        c.writes=c.writes+1
        for _,v in ipairs({a,r,g,b}) do check(v>=0 and v<=255,'invalid color') end
        c.prims[name].color={a,r,g,b}
    end
    assert(loadfile(source))()
    c.events.load()
    c.caption,c.guide=c.objects[1],c.objects[2]
    c.command=function(_,...) c.events['addon command'](...) end
    c.tick=function(_,seconds) c.time=c.time+(seconds or 0);c.events.postrender() end
    c.mouse=function(_,event,x,y,blocked)
        -- Model texts' earlier mouse callback: default-draggable captions
        -- would intercept this press before the banner receives it.
        for _,t in ipairs(c.objects) do
            if event==1 and t.draggable_flag and t:hover(x,y) then blocked=true;c.text_captured=true end
        end
        return c.events.mouse(event,x,y,0,blocked)
    end
    c.action=function(_,category,id,actor)
        local start=category==7 or category==8
        c.events.action({actor_id=actor or 1001,category=category,param=start and 24931 or id,
            targets={{id=2001,actions={{param=start and id or 0,message=1}}}}})
    end
    c.interrupt=function(_,category,first)
        c.events.action({actor_id=1001,category=category,param=28787,
            targets=first and {{actions={{param=first}}}} or nil})
    end
    return c
end

local c=session()
equal(c.settings.sounds,'off');equal(c.settings.timing,'fixed')
equal(c.settings.x_position,960);equal(c.settings.y_position,520)
check(not c.caption.draggable_flag and not c.guide.draggable_flag)
equal(c.caption.content,'Final Alert');check(c.caption.is_visible and not c.guide.is_visible)
equal(#c.sounds,0)
c:tick(5.99);check(c.caption.is_visible)
c:tick(0.01);check(not c.caption.is_visible)
c:command();equal(c.caption.content,'Casting: Edit Mode');check(c.guide.is_visible)
check(c.help_colors[140] and c.help_colors[167] and c.help_colors[200] and c.help_colors[207] and c.help_colors[0])
c:tick(1.5);equal(c.caption.content,'Edit Mode');check(c.prims.finalAlert_magic.visible)
c:tick(1.5);equal(c.caption.content,'Readying: Edit Mode');check(c.prims.finalAlert_ability.visible)
c:tick(1.5);equal(c.caption.content,'Edit Mode');check(c.prims.finalAlert_ability.visible)
c:tick(1.5);check(c.prims.finalAlert_interrupt.visible)
c:tick(1.5);equal(c.caption.content,'Casting: Edit Mode')
local pink=c.prims.finalAlert_magic.color
check(pink[2]>pink[3] and pink[4]>pink[3])
local blue=c.prims.finalAlert_ability.color
check(blue[4]>blue[2])
c:action(8,1);equal(c.caption.content,'Casting: Edit Mode');equal(#c.sounds,0)
c:command('HELP');equal(c.caption.content,'Casting: Edit Mode')
c:command('invalid');equal(c.caption.content,'Casting: Edit Mode')
c:command('edit','on');c:command('edit','on');equal(c.caption.content,'Casting: Edit Mode')
-- Drag directly on the caption: only the banner captures it and both move.
local x,y=c.caption.x+2,c.caption.y+2
check(c:mouse(1,x,y));check(not c.text_captured)
local old_x,old_y=c.caption.x,c.caption.y
check(c:mouse(0,x+43,y+27));equal(c.caption.x,old_x+43);equal(c.caption.y,old_y+27)
c:tick(10);equal(c.caption.content,'Casting: Edit Mode') -- cycle frozen while held
local saved=c.saves
check(c:mouse(2,x+43,y+27,true));equal(c.saves,saved+1) -- blocked release still finishes
c:tick(1.5);equal(c.caption.content,'Edit Mode')
c:command('lock');check(not c.settings.draggable)
x,y=c.settings.x_position,c.settings.y_position+5
check(c:mouse(1,x,y));check(c:mouse(2,x,y)) -- editing overrides lock without saving unlock
c:command('size');equal(c.settings.background_size,'small');check(c.caption.is_visible)
equal(c.prims.finalAlert_magic.h,25)
c:command('scale','0.7');equal(c.prims.finalAlert_magic.w,350)
c:command('pos','reset');equal(c.settings.x_position,960);equal(c.settings.y_position,531.25)
c:command();check(not c.caption.is_visible and not c.guide.is_visible)
c:command('edit','off');check(not c.caption.is_visible)
c:command('test','ws');c:tick(0.2);equal(c.caption.content,'Self-Destruct')
check(not c:mouse(1,c.settings.x_position,c.settings.y_position+5))
c:command('unlock');check(c:mouse(1,c.settings.x_position,c.settings.y_position+5));c:mouse(2,960,537)
c:tick(4);check(not c.caption.is_visible);check(not c:mouse(1,960,537))
equal(#c.sounds,0)
print('PASS: centered/silent defaults, chat help, five-stage preview, text drag, blocked release, lock, scale and recovery')

c=session();c:command('timing','lifecycle');c:action(8,1);c:tick(0.2)
equal(c.caption.content,'Casting: Fire');check(c.caption.is_visible)
local stable_writes=c.writes
c:tick(0.5);c:tick(0.5);equal(c.writes,stable_writes)
local preparation_tint=c.prims.finalAlert_magic.color
c:tick(4);check(c.caption.is_visible) -- not fixed-mode 3s
c:action(4,2);equal(c.caption.content,'Casting: Fire') -- stale finish ignored
c:action(4,1);equal(c.caption.content,'Fire')
for i=2,4 do equal(c.prims.finalAlert_magic.color[i],preparation_tint[i]) end
c:tick(0.75);c:action(4,1);c:tick(0.3);check(not c.caption.is_visible) -- duplicate doesn't extend
c:action(7,300);equal(c.caption.content,'Readying: Self-Destruct')
c:action(11,300);equal(c.caption.content,'Self-Destruct');check(c.prims.finalAlert_ability.visible)
c:tick(1.1);check(not c.caption.is_visible)
c:action(7,42);equal(c.caption.content,'Readying: Blade: Ten')
c:action(3,42);equal(c.caption.content,'Blade: Ten')
c:tick(1.1);c:action(4,2);equal(c.caption.content,'Blizzard') -- finish without observed start
c:tick(1.1);c:action(8,1);c:interrupt(7);equal(c.caption.content,'Casting: Fire')
c:interrupt(8,2);equal(c.caption.content,'Casting: Fire')
c:interrupt(8);equal(c.caption.content,'Interrupted');check(c.prims.finalAlert_interrupt.visible)
c:tick(1.1);check(not c.caption.is_visible)
c:command('timeout','5.5');c:action(8,1);c:tick(5);check(c.caption.is_visible)
c:action(8,1);c:tick(0.51);check(not c.caption.is_visible) -- duplicate start doesn't extend fallback
c:action(8,1);c.target={id=1002,is_npc=true,hpp=100};c:tick();check(not c.caption.is_visible)
c:action(4,1,1001);check(not c.caption.is_visible)
c.target={id=1001,is_npc=true,hpp=100};c:action(8,1);c.target.hpp=0;c:tick();check(not c.caption.is_visible)
c.target.hpp=100;c:action(8,1);c.events['zone change']();check(not c.caption.is_visible)
c:action(8,1);c.events.logout();check(not c.caption.is_visible)
c.events.action({actor_id=1001,category=8,param=24931});check(not c.caption.is_visible)
c.events.action({actor_id=1001,category=8,param=28787});equal(c.caption.content,'Interrupted')
c:command('timing','fixed');c:action(8,1);equal(c.caption.content,'Fire')
c:tick(2.5);c:action(4,1);c:tick(0.6);check(not c.caption.is_visible)
c:interrupt(8);equal(c.caption.content,'Interrupted');c:tick(3.1);check(not c.caption.is_visible)
print('PASS: spell/TP/weapon-skill lifecycle, unmatched/duplicate events, interruption, fallback, target/death/zone/logout cleanup, fixed-mode regression')

c=session();c:command('timing','lifecycle');c:command('sounds','on');c:command('emphasize','Fi re')
c:action(8,1);equal(#c.sounds,1);check(c.sounds[1]:match('emphasize.wav$'))
c:action(4,1);equal(#c.sounds,1) -- completion does not replay warning
c:command('sounds','off');c:action(8,1);equal(#c.sounds,1)
c:command('edit','on');c:tick(10);equal(#c.sounds,1)
c:command('sounds');equal(c.settings.sounds,'on');c:command('sounds');equal(c.settings.sounds,'off')
local saves=c.saves
for _,args in ipairs({{'duration','0'},{'finish','nan'},{'timeout','inf'},{'scale','-1'},
    {'pos','1'},{'scale','1e308'},{'size','no'},{'sounds','no'},{'edit','no'},{'timing','no'},{'emphasize'},
    {'restart','no'},{'unload','no'},{'status','no'}}) do
    c:command((unpack or table.unpack)(args));equal(c.saves,saves);equal(#c.commands,0)
end
c:command('duration','0.01');equal(c.settings.trigger_duration,0.01)
c:command('finish','99');equal(c.settings.finish_duration,99)
c:command('timeout','1000');equal(c.settings.fallback_timeout,1000)
c:command('status');check(c.messages[#c.messages][2]:match('Timeout=1000s'))
c:command('restart');c:command('restart');c:tick(0.06);equal(#c.commands,0)
check(c.caption.opacity<255 and c.guide.opacity<255)
c:tick(0.07);equal(#c.commands,1);equal(c.commands[1],'lua reload finalAlert')
for _,p in pairs(c.prims) do check(p.deleted) end
c:tick(2);c.events.unload();equal(#c.commands,1)
c=session();c:command('unload');c:tick(0.13);equal(#c.commands,1);equal(c.commands[1],'lua unload finalAlert')
-- Existing explicitly saved preferences survive the upgrade.
c=session({sounds='on',x_position=750,y_position=200,background_size='small',draggable=false})
equal(c.settings.sounds,'on');equal(c.settings.x_position,750);equal(c.settings.y_position,200)
c:command('edit','on');check(c.caption.is_visible)
local persisted={sounds=c.settings.sounds,x_position=c.settings.x_position,y_position=c.settings.y_position,draggable=c.settings.draggable}
c=session(persisted);equal(c.caption.content,'Final Alert');check(not c.guide.is_visible);equal(c.settings.draggable,false)
equal(#c.sounds,0) -- even an installation with sounds on gets a silent startup
c:action(8,1);equal(c.caption.content,'Fire') -- real alerts take precedence
c.viewport={x_res=640,y_res=360,ui_x_res=640,ui_y_res=360}
c:command('pos','reset');equal(c.settings.x_position,320);equal(c.settings.y_position,160)
c.target={id=99,is_npc=false};c.battle={id=1001,is_npc=true,hpp=100}
c:action(8,1);equal(c.caption.content,'Fire')
print('PASS: emphasis matching/silence, invalid commands, uncapped positive timers, graceful once-only restart/unload, saved-settings/reload compatibility and battle-target fallback')
print('PASS: six-second silent startup, reload startup without edit mode, real-event priority, preview preparation frames')
