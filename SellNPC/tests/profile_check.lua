-- Static/loadable profile check. No Windower client.
S = function(values)
    local out = {}
    for _, name in ipairs(values) do
        assert(not out[name], 'Duplicate item name: ' .. tostring(name))
        out[name] = true
    end
    return out
end
local p = assert(loadfile('profiles.lua'))()
local count = 0
for _ in pairs(p.junk) do count=count+1 end
assert(count==262, 'Expected 262 junk entries, got ' .. count)
assert(p.junk['Silk Thread'] and p.junk['Papaka Grass'] and p.junk['Shell Bug'])
assert(p.junk['Animal Glue'] and p.junk['Wind Crystal'])
for _, name in ipairs({'Goblin Helm', 'Goblin Mail', 'Goblin Mask', 'Dhalmel Saliva'}) do
    assert(not p.junk[name], 'NPC-unsellable item unexpectedly retained: ' .. name)
end
assert(p.furrow['Acorn'] and p.furrow['Earth Spirit'])
print('PROFILE PASS: 262 distinct junk entries, unsellables absent, added names present, furrow present')
