local count = 0
local function check(value, message)
    count = count + 1
    assert(value, message)
end
for _, file in ipairs({ 'fxmanifest.lua', 'config.lua', 'client/model.lua', 'client/main.lua' }) do
    check(loadfile(file) ~= nil, file .. ' syntax')
end
dofile('config.lua')
dofile('client/model.lua')

local defaults = Crosshair.defaults()
local clean = Crosshair.sanitize({ enabled = false, outline = false, centerDot = true, size = 999,
    gap = -10, opacity = 0 / 0, thickness = math.huge, color = '#ffffff', style = 'invalid', foreign = true })
check(clean.enabled == false and clean.outline == false and clean.centerDot == true, 'preserve boolean false')
check(clean.size == 64 and clean.gap == -10, 'clamp numeric limits and allow negative gap')
check(clean.opacity == defaults.opacity and clean.thickness == defaults.thickness, 'reject NaN and infinity')
check(clean.color == '#FFFFFF' and clean.style == defaults.style and clean.foreign == nil, 'allowlist settings')
check(Crosshair.sanitize('bad').size == defaults.size, 'malformed persisted value')
local fractional = Crosshair.sanitize({ size = 1.2, thickness = 0.8, gap = -1.6, outlineSize = 0.5, color = '#123abc', opacity = 0 })
check(math.abs(fractional.size - 1.2) < 0.001 and math.abs(fractional.thickness - 0.8) < 0.001, 'fractional length and thickness')
check(math.abs(fractional.gap + 1.6) < 0.001 and fractional.outlineSize == 0.5, 'fractional gap and outline')
check(fractional.color == '#123ABC' and fractional.opacity == 0, 'arbitrary RGB and transparent alpha')
check(Crosshair.sanitize({ color = 'url(fake)' }).color == defaults.color, 'reject non-hex colors')
for _, rect in ipairs(Crosshair.geometry(Crosshair.sanitize({ style = 'box', size = 0, gap = -32 }))) do
    check(rect[3] > 0 and rect[4] > 0, 'negative gap box keeps valid dimensions')
end
Config.Defaults.enabled = false
check(Crosshair.defaults().enabled == false, 'server false default')
Config.Defaults.enabled = true
check(#Crosshair.geometry(defaults) == 4, 'cross geometry')
local dot = Crosshair.sanitize({ style = 'dot', centerDot = true })
check(#Crosshair.geometry(dot) == 1, 'dot does not duplicate center')
check(#Crosshair.geometry(Crosshair.sanitize({ style = 't', centerDot = true })) == 4, 'T plus center')
check(#Crosshair.geometry(Crosshair.sanitize({ style = 'box' })) == 4, 'box geometry')
for _, rect in ipairs(Crosshair.geometry(Crosshair.sanitize({ style = 'box', size = 2, gap = 0, thickness = 6 }))) do
    check(rect[3] > 0 and rect[4] > 0, 'small thick box keeps positive dimensions')
end
local r, g, b = Crosshair.rgb('#00BFFF')
check(r == 0 and g == 191 and b == 255, 'RGB conversion')
local visible = { enabled = true, playing = true, armed = true, aiming = true }
check(Crosshair.visible(visible), 'visible during armed aim')
for _, key in ipairs({ 'dead', 'paused', 'focused', 'hidden', 'reloading', 'wheel', 'scoped', 'excluded' }) do
    visible[key] = true
    check(not Crosshair.visible(visible), 'hide for ' .. key)
    visible[key] = nil
end
for _, key in ipairs({ 'enabled', 'playing', 'armed', 'aiming' }) do
    visible[key] = false
    check(not Crosshair.visible(visible), 'require ' .. key)
    visible[key] = true
end

-- Exercise the actual client, including frame suppression, menu draft lifecycle,
-- KVP persistence and provider restart, with native/export boundaries simulated.
local state = { armed = true, aiming = true, playing = true, weapon = 10, width = 1920, height = 1080 }
local threads, events, commands, elements, draws = {}, {}, {}, {}, {}
local hidden, writes, generation = 0, 0, 0
local lifecycle
local stored = 'corrupt'
local encoded
json = {
    decode = function(value) if value == 'corrupt' then error('bad json') end return encoded end,
    encode = function(value) encoded = Crosshair.sanitize(value) return 'saved' end,
}
function GetResourceKvpString() return stored end
function SetResourceKvp(_, value) stored, writes = value, writes + 1 end
function joaat(value) if value == 'GROUP_SNIPER' then return 100 end return 200 end
function GetResourceState() return state.providerStopped and 'stopped' or 'started' end
function GetCurrentResourceName() return 'h4nr-crosshair' end
function RegisterCommand(name, callback) commands[name] = callback end
function RegisterKeyMapping() end
function AddEventHandler(name, callback) events[name] = callback end
function Wait() coroutine.yield() end
function CreateThread(callback)
    local thread = coroutine.create(callback)
    threads[#threads + 1] = thread
    local ok, problem = coroutine.resume(thread)
    assert(ok, problem)
end
function PlayerPedId() return 1 end
function PlayerId() return 1 end
function GetSelectedPedWeapon() return state.weapon end
function GetWeapontypeGroup() return state.sniper and 100 or 101 end
function IsFirstPersonAimCamActive() return state.scope end
function IsPlayerPlaying() return state.playing end
function IsPedArmed() return state.armed end
function IsPlayerFreeAiming() return state.aiming end
function IsPlayerTargettingAnything() return state.targetting end
function IsNuiFocused() return state.focused end
function IsPauseMenuActive() return state.paused end
function IsEntityDead() return state.dead end
function IsScreenFadedOut() return state.faded end
function IsScreenFadingOut() return false end
function IsHudHidden() return state.hudHidden end
function IsPedReloading() return state.reloading end
function IsHudComponentActive() return state.wheel end
function GetActiveScreenResolution() return state.width, state.height end
function HideHudComponentThisFrame(id) assert(id == 14) hidden = hidden + 1 end
function DrawRect(...) draws[#draws + 1] = { ... } end
local function ok(value) return { ok = true, value = value or {} } end
local menu = {}
function menu:AwaitReady() return ok() end
function menu:CreateMenu(spec)
    check(spec.theme.preset == 'modern', 'modern theme')
    generation = generation + 1
    elements = {}
    return ok({ menuId = generation })
end
function menu:CreatePage() return ok({ pageId = 'main' }) end
function menu:RegisterMenuLifecycle(_, callback) lifecycle = callback return ok() end
function menu:AddElement(_, _, _, spec, callback)
    elements[spec.key] = { spec = spec, callback = callback }
    return ok({ elementId = spec.key })
end
function menu:UpdateElement(_, _, key, patch)
    for name, value in pairs(patch) do elements[key].spec[name] = value end
    return ok()
end
function menu:OpenMenu() state.focused = true return ok() end
function menu:CloseMenu(id)
    state.focused = false
    lifecycle({ menuId = id, event = 'closed' })
    return ok()
end
function menu:DestroyMenu() return ok() end
exports = { ['feather-menu-v2'] = menu }
Config.ExcludedWeapons = { 'WEAPON_CUSTOM_SCOPE' }
dofile('client/main.lua')
local function frame()
    draws, hidden = {}, 0
    local success, problem = coroutine.resume(threads[1])
    assert(success, problem)
end
local function change(key, value) elements[key].callback({ value = value }) end
local function click(key) elements[key].callback({}) end
local function open() commands.crosshair() end
frame()
check(hidden == 1 and #draws == 8, 'native hidden and custom drawn with outline')
check(draws[5][1] < 0.5 and draws[5][2] == 0.5, 'centered geometry')
local normalWidth = draws[5][3]
state.width = 2560
frame()
check(math.abs(draws[5][3] * 2560 - normalWidth * 1920) < 0.001, 'ultrawide preserves pixel proportions')
state.width = 1920
for _, key in ipairs({ 'paused', 'dead', 'focused', 'faded', 'hudHidden', 'reloading', 'wheel' }) do
    state[key] = true
    frame()
    check(#draws == 0 and hidden == 1, 'runtime suppression during ' .. key)
    state[key] = false
end
state.armed = false
frame()
check(#draws == 0, 'no unarmed crosshair')
state.armed, state.aiming, state.targetting = true, false, true
frame()
check(#draws > 0, 'controller target lock')
state.aiming, state.targetting = true, false
state.sniper, state.scope = true, true
frame()
check(hidden == 0 and #draws == 0, 'preserve scoped sniper sights')
Config.PreserveSniperScope = false
frame()
check(hidden == 1 and #draws > 0, 'scope replacement policy configurable')
Config.PreserveSniperScope = true
state.sniper, state.scope = false, false
state.weapon = 200
frame()
check(hidden == 0 and #draws == 0, 'excluded weapons retain native sights')
state.weapon = 10

open()
frame()
check(#draws > 0 and draws[1][1] > 0.6, 'settings preview on right')
check(elements.size.spec.step == 0.1 and elements.gap.spec.min == -32, 'CS-style slider precision and gap')
change('red', 18)
change('green', 52)
change('blue', 86)
frame()
check(draws[5][5] == 18 and draws[5][6] == 52 and draws[5][7] == 86, 'RGB sliders update preview')
check(elements.color.spec.value == '#123456' and #elements.color.spec.options == 9, 'custom RGB appears in palette')
change('color', '#5EF2A0')
check(elements.red.spec.value == 94 and elements.green.spec.value == 242 and elements.blue.spec.value == 160, 'palette syncs RGB sliders')
change('outlineSize', 0.5)
frame()
check(math.abs((draws[1][3] - draws[5][3]) * 1920 - 1) < 0.001, 'outline thickness rendered from slider')
change('opacity', 0)
frame()
check(draws[5][8] == 0, 'zero opacity preview')
click('reset')
check(elements.red.spec.value == 0 and elements.green.spec.value == 191 and elements.blue.spec.value == 255,
    'defaults reset RGB controls')
check(elements.outlineSize.spec.value == 1, 'defaults reset outline width')
change('style', 'dot')
change('outline', false)
frame()
check(#draws == 1, 'live style preview')
click('cancel')
frame()
check(#draws == 8 and writes == 0, 'cancel discards draft')
open()
change('enabled', false)
click('save')
frame()
check(#draws == 0 and hidden == 1 and writes == 1 and not encoded.enabled, 'saved disabled still hides native')
open()
click('reset')
check(writes == 1 and elements.enabled.spec.value == true, 'defaults are a draft')
click('cancel')
frame()
check(#draws == 0, 'cancel defaults retains saved preferences')
open()
click('reset')
click('save')
frame()
check(#draws == 8 and writes == 2, 'save default settings')
open()
change('style', 'dot')
lifecycle({ menuId = generation, event = 'suspended' })
frame()
check(#draws == 0, 'suspended menu hides preview')
lifecycle({ menuId = generation, event = 'resumed' })
frame()
check(#draws > 0, 'resumed menu restores preview')
lifecycle({ menuId = generation, event = 'closed' })
state.focused = false
frame()
check(#draws == 8, 'Escape discards draft')
open()
change('style', 'dot')
state.providerStopped = true
events.onClientResourceStop('feather-menu-v2')
state.focused = false
frame()
check(#draws == 8, 'provider stop discards preview draft')
state.providerStopped = false
open()
check(elements.style.spec.value == 'cross', 'provider restart rebuilds from saved settings')
click('cancel')
-- A fresh client runtime must actually read the persisted false value.
open()
change('enabled', false)
click('save')
dofile('client/main.lua')
local restartedThread = threads[#threads]
draws, hidden = {}, 0
local restarted, problem = coroutine.resume(restartedThread)
assert(restarted, problem)
check(#draws == 0 and hidden == 1, 'resource restart loads persisted disabled preference')
open()
check(elements.enabled.spec.value == false, 'menu reads persisted false after restart')
click('cancel')
local externalReads = 0
function GetExternalKvpString(resource, key)
    check(resource == 'feather-crosshair' and key == 'feather-crosshair:settings:v1', 'read previous resource namespace')
    externalReads = externalReads + 1
    return 'saved'
end
stored = nil
local previousWrites = writes
dofile('client/main.lua')
open()
check(elements.enabled.spec.value == false and writes == previousWrites + 1, 'rename imports and saves old false preference')
click('cancel')
dofile('client/main.lua')
check(externalReads == 1, 'new settings take precedence over old namespace')
open()
change('red', 18)
change('green', 52)
change('blue', 86)
change('size', 1.2)
change('thickness', 0.8)
change('gap', -1.6)
change('outlineSize', 0.5)
click('save')
check(encoded.color == '#123456' and math.abs(encoded.gap + 1.6) < 0.001, 'custom RGB and negative gap persisted')
dofile('client/main.lua')
open()
check(elements.color.spec.value == '#123456' and #elements.color.spec.options == 9, 'custom palette survives restart')
check(elements.red.spec.value == 18 and math.abs(elements.thickness.spec.value - 0.8) < 0.001,
    'RGB and fractional slider values survive restart')
change('blue', 255)
click('cancel')
open()
check(elements.blue.spec.value == 86, 'cancel restores saved custom RGB')
click('cancel')
print(('Passed %d assertions (model, rendering, menu lifecycle, persistence, restart).'):format(count))
dofile('tests/chat_suggestions_spec.lua')
