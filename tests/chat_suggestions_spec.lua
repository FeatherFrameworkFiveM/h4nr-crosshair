dofile('config/shared.lua')
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
local events, registration, count = {}, {}, 0
local chatState, ready = 'started', true
local function check(value, message)
    count = count + 1
    assert(value, message)
end
function GetResourceState()
    return chatState
end
function AddEventHandler(name, callback)
    events[name] = callback
end
function CreateThread(callback)
    callback()
end
exports = {
    ['feather-chat'] = {
        GetHealth = function()
            return { ok = true, value = { state = ready and 'ready' or 'starting' } }
        end,
        RegisterSuggestion = function(_, spec)
            registration[#registration + 1] = spec
            return { ok = true }
        end,
    },
}
local function load()
    dofile('server/chat_suggestions.lua')
end
load()
check(#registration == 1 and registration[1].trigger == '/tinta', 'register at startup using configured command')
check(registration[1].description == 'Deschide setările țintei personalizate', 'Romanian suggestion')
events['chat.ready.v1']()
check(#registration == 1, 'duplicate ready event does not duplicate registration')
events.onResourceStop('unrelated-resource')
events['chat.ready.v1']()
check(#registration == 1, 'unrelated stop does not clear guard')
events.onResourceStop('feather-chat')
events['chat.ready.v1']()
check(#registration == 2, 'chat restart re-registers suggestion')
chatState = 'missing'
load()
check(#registration == 2, 'optional chat absent')
chatState, ready = 'started', false
events['chat.ready.v1']()
check(#registration == 2, 'wait for chat readiness')
ready = true
events['chat.ready.v1']()
check(#registration == 3, 'chat starting after crosshair registers when ready')
Config.Command, Config.DefaultLang = 'aimsettings', 'en_us'
load()
check(
    registration[4].trigger == '/aimsettings' and registration[4].description == 'Open custom crosshair settings',
    'configured command and English fallback'
)
print(('Passed %d assertions (chat suggestion registration and restarts).'):format(count))
