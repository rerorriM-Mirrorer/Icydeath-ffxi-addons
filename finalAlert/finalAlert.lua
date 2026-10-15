_addon.name = 'finalAlert'
_addon.author = 'Godchain; A'
_addon.version = '1.5.0-test2'
_addon.commands = {'finalAlert', 'fa'}

local config = require('config')
local texts = require('texts')
local res = require('resources')
require('chat')
local now = require('socket').gettime -- Wall time, including fractional seconds.

local function viewport()
    local v = windower.get_windower_settings()
    return v.ui_x_res or v.x_res, v.ui_y_res or v.y_res
end

local width, height = viewport()
local defaults = {
    x_position = width / 2, y_position = height / 2 - 20,
    background_size = 'regular', scale = 1, draggable = true,
    sounds = 'off', emphasize = S{}, trigger_duration = 3,
    timing = 'fixed', finish_duration = 1, fallback_timeout = 30,
}
local settings = config.load(defaults)

-- Only the banner owns mouse movement. texts otherwise installs a second,
-- competing drag handler that captures clicks directly on the caption.
local caption = texts.new({flags = {draggable = false}})
local guide = texts.new({flags = {draggable = false}})
local kinds = {'ma', 'ws', 'int', 'emphasize'}
local primitives = {
    ma = 'finalAlert_magic', ws = 'finalAlert_ability',
    int = 'finalAlert_interrupt', emphasize = 'finalAlert_emphasize',
}
local tints = {ma = {218, 183, 199}, ws = {183, 200, 221}, int = {255, 255, 255}}
local preview = {
    {text = 'Casting: Edit Mode', kind = 'ma'},
    {text = 'Edit Mode', kind = 'ma'},
    {text = 'Readying: Edit Mode', kind = 'ws'},
    {text = 'Edit Mode', kind = 'ws'},
    {text = 'Edit Mode', kind = 'int'},
}
local active, editing, drag, retiring
local created, destroyed = false, false
local last_paint, last_layout, caption_position, guide_position
local preview_index, preview_at = 1, 0
local PREVIEW_SECONDS, FADE_SECONDS = 1.5, 0.12

local function reply(message)
    windower.add_to_chat(207, 'finalAlert: ' .. message)
end

local function dimensions()
    return 500 * settings.scale, (settings.background_size == 'small' and 25 or 40) * settings.scale
end

local function emphasized(name)
    return name and settings.emphasize:contains(name:gsub('%s+', ''):lower())
end

local function current_target()
    local target = windower.ffxi.get_mob_by_target('t')
    if target and target.is_npc then return target end
    return windower.ffxi.get_mob_by_target('bt')
end

local function finish_drag()
    if not drag then return end
    drag = nil
    settings:save()
    preview_at = now() + PREVIEW_SECONDS
    reply(('Position saved: %g, %g.'):format(settings.x_position, settings.y_position))
end

local function hide()
    last_paint = nil
    caption:hide()
    guide:hide()
    if created then
        for _, kind in ipairs(kinds) do windower.prim.set_visibility(primitives[kind], false) end
    end
end

local function layout()
    local w, h = dimensions()
    local left, top = settings.x_position - w / 2, settings.y_position
    if created and (not last_layout or last_layout[1] ~= left or last_layout[2] ~= top
        or last_layout[3] ~= w or last_layout[4] ~= h) then
        for _, kind in ipairs(kinds) do
            windower.prim.set_position(primitives[kind], left, top)
            windower.prim.set_size(primitives[kind], w, h)
        end
        last_layout = {left, top, w, h}
    end
    local text_width = caption:extents()
    local offset = settings.background_size == 'small' and 3 or 10
    local cx, cy = settings.x_position - text_width / 2, settings.y_position + offset * settings.scale
    if not caption_position or caption_position[1] ~= cx or caption_position[2] ~= cy then
        caption:pos(cx, cy); caption_position = {cx, cy}
    end
    local guide_width = guide:extents()
    local gx, gy = settings.x_position - guide_width / 2, settings.y_position + h + 4 * settings.scale
    if not guide_position or guide_position[1] ~= gx or guide_position[2] ~= gy then
        guide:pos(gx, gy); guide_position = {gx, gy}
    end
end

local function recover_position()
    local vw, vh = viewport()
    local w, h = dimensions()
    -- Keep the frame reachable after moving between differently sized clients.
    settings.x_position = w <= vw and math.max(w / 2, math.min(vw - w / 2, settings.x_position)) or vw / 2
    settings.y_position = math.max(0, math.min(math.max(0, vh - h), settings.y_position))
end

local function paint(opacity)
    if destroyed or not created then return end
    local item = editing and preview[preview_index] or active
    if not item then hide(); return end
    opacity = math.floor(opacity or 255)
    local emphasis = not editing and emphasized(item.name) == true
    -- A held cast can last many seconds across several clients. Do not keep
    -- sending identical text, colors and visibility to the rendering engine.
    if last_paint and last_paint.item == item and last_paint.editing == editing
        and last_paint.opacity == opacity and last_paint.emphasis == emphasis then
        layout(); return
    end
    last_paint = {item = item, editing = editing, opacity = opacity, emphasis = emphasis}
    caption:text(item.text)
    caption:alpha(opacity)
    guide:alpha(opacity)
    caption:show()
    for _, kind in ipairs(kinds) do
        local tint = tints[kind] or tints[item.kind]
        windower.prim.set_color(primitives[kind], opacity, tint[1], tint[2], tint[3])
        windower.prim.set_visibility(primitives[kind], kind == item.kind or
            (kind == 'emphasize' and emphasis))
    end
    if editing then guide:show() else guide:hide() end
    layout()
end

local function refresh_backgrounds()
    last_paint = nil
    if not created then
        for _, kind in ipairs(kinds) do windower.prim.create(primitives[kind]) end
        created = true
    end
    for _, kind in ipairs(kinds) do
        -- Tint the existing neutral frame instead of multiplying a saturated
        -- pink/blue texture: this preserves its border and grey gradient.
        local file = kind == 'emphasize' and 'background_emphasize.png' or 'background_interrupt.png'
        windower.prim.set_fit_to_texture(primitives[kind], false)
        windower.prim.set_texture(primitives[kind], windower.addon_path .. 'images/' .. settings.background_size .. '/' .. file)
    end
    caption:size(math.max(1, 12 * settings.scale))
    guide:size(math.max(1, 9 * settings.scale))
    recover_position()
    layout()
    paint()
end

local function clear()
    finish_drag()
    active = nil
    hide()
end

local function set_edit(enabled)
    if editing == enabled then return end
    clear()
    editing = enabled
    preview_index, preview_at = 1, now() + PREVIEW_SECONDS
    paint()
end

local function sound(item)
    -- Off means quiet, including emphasized alerts. Finishing a preparation
    -- changes its caption without replaying its warning sound.
    if settings.sounds ~= 'on' then return end
    local file = emphasized(item.name) and 'emphasize' or
        ({ma = 'magic_alert', ws = 'ability_alert', int = 'interrupt_alert'})[item.kind]
    windower.play_sound(windower.addon_path .. 'sounds/' .. file .. '.wav')
end

local function display(item, seconds, audible)
    local previous = active
    local time = now()
    item.started = previous and previous.actor_id == item.actor_id and previous.action_id == item.action_id
        and previous.phase == 'preparing' and previous.started or time
    item.deadline = time + seconds
    active = item
    paint(item.started == time and 0 or 255)
    if audible then sound(item) end
end

local function resource_for(category, id)
    if category == 8 or category == 4 then return 'spells', 'ma' end
    if category == 11 or id > 256 then return 'monster_abilities', 'ws' end
    return 'weapon_skills', 'ws'
end

local function action_name(family, id)
    local entry = res[family] and res[family][id]
    return entry and (entry.name or entry.en) or ('Unknown (%s)'):format(tostring(id))
end

local function first_action(act)
    local target = act.targets and act.targets[1]
    return target and target.actions and target.actions[1]
end

local function handle_action(act)
    if editing or retiring or type(act) ~= 'table' then return end
    local target = current_target()
    if not target or act.actor_id ~= target.id then return end
    local category = act.category
    local starting = category == 7 or category == 8
    local finishing = category == 3 or category == 4 or category == 11
    if not starting and not finishing then return end
    if active and active.actor_id and active.actor_id ~= target.id then clear() end
    local kind = category == 8 and 'ma' or 'ws'
    local first = first_action(act)

    -- Interruptions need not contain a usable nested action ID. Check this
    -- marker before looking up the spell/ability or indexing its targets.
    if starting and act.param == 28787 then
        if settings.timing == 'lifecycle' and active and active.phase == 'preparing' then
            if active.kind ~= kind then return end
            local id = first and first.param
            if id and id > 0 and id ~= active.action_id then return end
        end
        display({text = 'Interrupted', name = 'Interrupted', kind = 'int', phase = 'interrupted', actor_id = act.actor_id},
            settings.timing == 'fixed' and settings.trigger_duration or settings.finish_duration, true)
        return
    end
    if finishing and settings.timing == 'fixed' then return end
    -- Starts carry their action ID in a nested action; finishes carry it in
    -- the top-level param. They are not interchangeable packet fields.
    local id = starting and first and first.param or (finishing and act.param)
    if type(id) ~= 'number' or id <= 0 then return end
    local family
    family, kind = resource_for(category, id)
    local name = action_name(family, id)
    if settings.timing == 'fixed' then
        -- Preserve the old start-triggered fixed-duration display, without
        -- preparation prefixes or finish packets extending its duration.
        display({text = name, name = name, kind = kind, phase = 'fixed', actor_id = act.actor_id,
            action_id = id, family = family}, settings.trigger_duration, true)
    elseif starting then
        if active and active.phase == 'preparing' and active.actor_id == act.actor_id
            and active.family == family and active.action_id == id then return end
        display({text = (kind == 'ma' and 'Casting: ' or 'Readying: ') .. name,
            name = name, kind = kind, phase = 'preparing', actor_id = act.actor_id,
            action_id = id, family = family}, settings.fallback_timeout, true)
    else
        -- A delayed finish for another action must not replace a newer cast.
        -- With no preparation recorded, a valid finish can still be shown.
        if active and active.actor_id == act.actor_id then
            if active.phase == 'preparing' and (active.family ~= family or active.action_id ~= id) then return end
            if active.phase == 'finished' and active.family == family and active.action_id == id then return end
        end
        display({text = name, name = name, kind = kind, phase = 'finished', actor_id = act.actor_id,
            action_id = id, family = family}, settings.finish_duration, false)
    end
end

local function help()
    local function color(s, c) return s:color(c) end
    windower.add_to_chat(0, color('---------- ', 140) .. color('finalAlert ' .. _addon.version, 167) .. color(' ----------', 140))
    local entries = {
        {'[help]', 'Bare //fa shows help AND toggles the cycling edit preview; help alone does not toggle.'},
        {'edit [on|off]', 'Toggle or explicitly set the silent, draggable five-stage preview.'},
        {'timing [fixed|lifecycle]', 'Report/set fixed-duration or action-lifecycle timing.'},
        {'duration [seconds]', 'Report/set fixed-mode duration; saved. Default: 3.'},
        {'finish [seconds]', 'Report/set completion and interruption display time. Default: 1.'},
        {'timeout [seconds]', 'Report/set preparation fallback timeout. Default: 30.'},
        {'pos [<x> <y>|reset]', 'Report position, move the banner, or recover screen center.'},
        {'size [small|regular]', 'Toggle or explicitly select the frame size.'},
        {'scale [number]', 'Report/set a positive scale, for smaller client windows.'},
        {'sounds [on|off]', 'Toggle/set all alert sounds. Default: off; preview always silent.'},
        {'emphasize <action name>', 'Toggle emphasis by action name; prefixes do not affect matching.'},
        {'lock', 'Save dragging locked outside edit mode.'},
        {'unlock', 'Save dragging unlocked outside edit mode.'},
        {'test <ws|ma|int>', 'Show a single test alert; does not replace edit mode.'},
        {'status', 'Report version, timing, preview, sound, position and tracked action.'},
        {'restart', 'Gracefully reload saved settings; clear temporary state.'},
        {'unload', 'Fade out, clean up and unload this client\'s addon.'},
    }
    for _, entry in ipairs(entries) do
        windower.add_to_chat(0, color('//fa ', 200) .. color(entry[1], 207) ..
            color(' -> ', 200) .. color(entry[2], 0))
    end
end

local function invalid(message)
    reply(message or 'Invalid command or arguments.')
    help()
end

local function positive(s)
    local n = tonumber(s)
    return n and n == n and n > 0 and n < math.huge and n or nil
end

local handlers = {}
handlers.help = function(args) if #args ~= 0 then return invalid() end; help() end
handlers.edit = function(args)
    local state = args[1] and args[1]:lower()
    if #args > 1 or (state and state ~= 'on' and state ~= 'off') then return invalid() end
    set_edit(state == nil and not editing or state == 'on')
    reply(editing and 'Edit preview on; drag to move, //fa edit to exit.' or 'Edit preview off.')
end
handlers.timing = function(args)
    local mode = args[1] and args[1]:lower()
    if #args > 1 or (mode and mode ~= 'fixed' and mode ~= 'lifecycle') then return invalid() end
    if mode then clear(); settings.timing = mode; settings:save(); paint() end
    reply('Timing: ' .. settings.timing .. '.')
end
for command, key in pairs({duration = 'trigger_duration', finish = 'finish_duration', timeout = 'fallback_timeout'}) do
    local setting_key, setting_command = key, command -- Separate upvalues under Lua 5.1.
    handlers[setting_command] = function(args)
        if #args > 1 or (#args == 1 and not positive(args[1])) then return invalid('Use a positive, finite duration.') end
        if args[1] then settings[setting_key] = positive(args[1]); settings:save() end
        reply(setting_command .. ': ' .. settings[setting_key] .. ' seconds.')
    end
end
handlers.size = function(args)
    local size = args[1] and args[1]:lower() or (settings.background_size == 'small' and 'regular' or 'small')
    if #args > 1 or (size ~= 'small' and size ~= 'regular') then return invalid() end
    finish_drag(); settings.background_size = size; refresh_backgrounds(); settings:save()
    reply('Size: ' .. size .. '.')
end
handlers.scale = function(args)
    local value = args[1] and positive(args[1])
    if #args > 1 or (#args == 1 and (not value or value * 500 == math.huge)) then
        return invalid('Use a positive scale whose frame dimensions remain finite.')
    end
    if args[1] then finish_drag(); settings.scale = positive(args[1]); refresh_backgrounds(); settings:save() end
    reply('Scale: ' .. settings.scale .. '.')
end
handlers.sounds = function(args)
    local state = args[1] and args[1]:lower() or (settings.sounds == 'on' and 'off' or 'on')
    if #args > 1 or (state ~= 'on' and state ~= 'off') then return invalid() end
    settings.sounds = state; settings:save(); reply('Sounds: ' .. state .. '.')
end
handlers.pos = function(args)
    if #args == 1 and args[1]:lower() == 'reset' then
        finish_drag()
        local vw, vh = viewport()
        local _, h = dimensions()
        settings.x_position, settings.y_position = vw / 2, vh / 2 - h / 2
    elseif #args == 2 and tonumber(args[1]) and tonumber(args[2]) then
        local x, y = tonumber(args[1]), tonumber(args[2])
        if x ~= x or y ~= y or math.abs(x) == math.huge or math.abs(y) == math.huge then return invalid() end
        finish_drag(); settings.x_position, settings.y_position = x, y
    elseif #args ~= 0 then return invalid() end
    if #args ~= 0 then recover_position(); layout(); settings:save() end
    reply(('Position: %g, %g (horizontal center, top Y).'):format(settings.x_position, settings.y_position))
end
for command, locked in pairs({lock = true, unlock = false}) do
    local lock_value = locked
    handlers[command] = function(args)
        if #args ~= 0 then return invalid() end
        finish_drag(); settings.draggable = not lock_value; settings:save()
        reply(lock_value and 'Dragging locked outside edit mode.' or 'Dragging unlocked.')
    end
end
handlers.emphasize = function(args)
    if #args == 0 then return invalid('Specify an action name.') end
    local name = table.concat(args, ' ')
    local key = name:gsub('%s+', ''):lower()
    local present = settings.emphasize:contains(key)
    if present then settings.emphasize:remove(key) else settings.emphasize:add(key) end
    settings:save(); paint(); reply((present and 'Removed emphasis: ' or 'Added emphasis: ') .. name .. '.')
end
handlers.test = function(args)
    local kind = args[1] and args[1]:lower()
    local names = {ws = 'Self-Destruct', ma = 'Tornado II', int = 'Interrupted'}
    if #args ~= 1 or not names[kind] then return invalid() end
    if editing then return reply('Edit preview is active; //fa edit off first.') end
    display({text = names[kind], name = names[kind], kind = kind, phase = 'test'}, settings.trigger_duration, true)
end
handlers.status = function(args)
    if #args ~= 0 then return invalid() end
    reply(('v%s | Timing=%s | Edit=%s | Sounds=%s | Drag=%s | Size=%s | Scale=%g'):format(
        _addon.version, settings.timing, editing and 'on' or 'off', settings.sounds,
        settings.draggable and 'unlocked' or 'locked', settings.background_size, settings.scale))
    reply(('Pos=%g,%g | Duration=%gs | Finish=%gs | Timeout=%gs | Action=%s'):format(
        settings.x_position, settings.y_position, settings.trigger_duration, settings.finish_duration,
        settings.fallback_timeout, active and (active.phase .. ': ' .. active.text .. ' [actor ' .. tostring(active.actor_id) .. ']') or 'none'))
end

local function cleanup()
    if destroyed then return end
    destroyed = true
    caption:destroy(); guide:destroy()
    if created then for _, kind in ipairs(kinds) do windower.prim.delete(primitives[kind]) end end
end

local function dispatch_retirement()
    if not retiring then return end
    local command = retiring.command
    retiring = nil
    cleanup()
    windower.send_command(command) -- Exactly one dispatch, even after repeated requests.
end

local function retire(command, args)
    if #args ~= 0 then return invalid() end
    if retiring or destroyed then return end
    finish_drag()
    reply(command == 'restart' and 'Restarting.' or 'Unloading.')
    retiring = {command = 'lua ' .. (command == 'restart' and 'reload' or 'unload') .. ' finalAlert', started = now()}
    if not editing and not active then dispatch_retirement() end
end
handlers.restart = function(args) retire('restart', args) end
handlers.unload = function(args) retire('unload', args) end

local function handle_command(command, ...)
    if retiring or destroyed then return end
    local args = {...}
    if not command or command == '' then
        help()
        handlers.edit({}) -- Deliberate bare-command primary action, alongside help.
        return
    end
    local handler = handlers[command:lower()]
    if handler then handler(args) else invalid('Unknown command: ' .. command .. '.') end
end

windower.register_event('load', function()
    caption:bg_visible(false); caption:bold(true)
    guide:bg_visible(false); guide:color(195, 195, 195)
    guide:text('Drag to move | Exit with //fa edit')
    refresh_backgrounds()
    -- A silent load confirmation uses its own six-second deadline. It does
    -- not change saved timing, enter edit mode, or delay real combat alerts.
    display({text = 'Final Alert', kind = 'int', phase = 'startup'}, 6, false)
end)
windower.register_event('addon command', handle_command)
windower.register_event('action', handle_action)
windower.register_event('mouse', function(event, x, y, delta, blocked)
    if retiring or destroyed then return end
    -- Once our banner owns a drag, finish it even if another handler marks
    -- the release blocked. Otherwise one blocked release can leave it stuck.
    if drag then
        if event == 0 then
            settings.x_position = math.floor(x - drag.x + 0.5)
            settings.y_position = math.floor(y - drag.y + 0.5)
            layout() -- Move text and frame together, not a frame apart.
            return true
        elseif event == 2 then
            recover_position(); layout(); finish_drag(); return true
        end
    end
    if blocked or event ~= 1 or (not editing and (not active or settings.draggable == false)) then return end
    if not editing and caption:alpha() == 0 then return end
    local w, h = dimensions()
    local left = settings.x_position - w / 2
    -- Include long captions extending beyond the artwork; never capture an
    -- invisible banner. Both text objects have library dragging disabled.
    if editing or active then
        if (x >= left and x <= left + w and y >= settings.y_position and y <= settings.y_position + h)
            or caption:hover(x, y) then
            drag = {x = x - settings.x_position, y = y - settings.y_position}
            return true
        end
    end
end)
windower.register_event('postrender', function()
    if destroyed then return end
    local time = now()
    if retiring then
        local fraction = (time - retiring.started) / FADE_SECONDS
        if fraction >= 1 then dispatch_retirement() else paint(255 * (1 - fraction)) end
        return
    end
    if editing then
        if not drag and time >= preview_at then
            preview_index = preview_index % #preview + 1
            preview_at = time + PREVIEW_SECONDS
        end
        paint()
    elseif active then
        if settings.timing == 'lifecycle' and active.actor_id then
            local target = current_target()
            if not target or target.id ~= active.actor_id or target.hpp == 0 then clear(); return end
        end
        if time >= active.deadline then clear(); return end
        local opacity = math.min(1, (time - active.started) / FADE_SECONDS,
            (active.deadline - time) / FADE_SECONDS)
        paint(255 * math.max(0, opacity))
    end
end)
local function reset_runtime()
    finish_drag(); editing = false; clear()
end
windower.register_event('zone change', reset_runtime)
windower.register_event('logout', reset_runtime)
windower.register_event('unload', function() finish_drag(); cleanup() end)
