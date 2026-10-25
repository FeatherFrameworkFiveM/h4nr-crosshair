-- Chat is optional. Its registry owns autocomplete presentation and owner cleanup.
local registered = false
local function register()
    if registered or GetResourceState('feather-chat') ~= 'started' then return end
    local ok, problem = pcall(function()
        local chat = exports['feather-chat']
        local health = chat:GetHealth()
        if not health.ok or health.value.state ~= 'ready' then return end
        local description = Config.DefaultLang == 'ro' and 'Deschide setările țintei personalizate'
            or 'Open custom crosshair settings'
        local result = chat:RegisterSuggestion({ key = 'h4nr-crosshair.settings',
            trigger = '/' .. Config.Command, description = description })
        if not result.ok then error('registration failed: ' .. tostring(result.code)) end
        registered = true
    end)
    if not ok then print('[h4nr-crosshair] Chat suggestion: ' .. tostring(problem)) end
end

AddEventHandler('chat.ready.v1', register)
AddEventHandler('onResourceStop', function(resource)
    if resource == 'feather-chat' then registered = false end
end)
CreateThread(register)
