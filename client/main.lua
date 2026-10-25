local KVP_KEY = 'h4nr-crosshair:settings:v1'
local Menu = exports['feather-menu-v2']
local menuId, pageId, draft
local menuOpen, preview, opening = false, false, false
local fields = {}
local labels = {
    ro = { title = 'Setări țintă', help = 'Previzualizare în dreapta. Modificările se aplică după Salvează.',
        enabled = 'Țintă personalizată', style = 'Stil', cross = 'Cruce', dot = 'Punct', t = 'Forma T', box = 'Pătrat',
        color = 'Culori rapide', customColor = 'Personalizată', red = 'Roșu', green = 'Verde', blue = 'Albastru',
        size = 'Lungime', gap = 'Distanță față de centru', thickness = 'Grosime', outlineSize = 'Grosime contur',
        opacity = 'Opacitate (%)', outline = 'Contur negru', centerDot = 'Punct central',
        reset = 'Valori implicite', cancel = 'Anulează', save = 'Salvează', command = 'Deschide setările țintei' },
    en_us = { title = 'Crosshair settings', help = 'Preview on the right. Changes apply after Save.',
        enabled = 'Custom crosshair', style = 'Style', cross = 'Cross', dot = 'Dot', t = 'T shape', box = 'Square',
        color = 'Quick colors', customColor = 'Custom', red = 'Red', green = 'Green', blue = 'Blue',
        size = 'Length', gap = 'Center gap', thickness = 'Thickness', outlineSize = 'Outline thickness',
        opacity = 'Opacity (%)', outline = 'Black outline', centerDot = 'Center dot',
        reset = 'Defaults', cancel = 'Cancel', save = 'Save', command = 'Open crosshair settings' },
}
local text = labels[Config.DefaultLang] or labels.en_us
local excluded = {}
for _, weapon in ipairs(Config.ExcludedWeapons or {}) do excluded[joaat(weapon)] = true end
local SNIPER_GROUP = joaat('GROUP_SNIPER') & 0xFFFFFFFF

local function load()
    local raw = GetResourceKvpString(KVP_KEY)
    local migrated = false
    if not raw then
        -- KVP is scoped by resource name, so preserve preferences from the rename.
        local ok, legacy = pcall(GetExternalKvpString, 'feather-crosshair', 'feather-crosshair:settings:v1')
        if ok then raw, migrated = legacy, legacy ~= nil end
    end
    if raw then
        local ok, value = pcall(json.decode, raw)
        if ok and type(value) == 'table' then
            local sanitized = Crosshair.sanitize(value)
            if migrated then SetResourceKvp(KVP_KEY, json.encode(sanitized)) end
            return sanitized
        end
    end
    return Crosshair.defaults()
end
local settings = load()
local rectangles = Crosshair.geometry(settings)
local renderedSettings = settings

local function requireResult(result)
    if type(result) ~= 'table' or not result.ok then
        error(('[h4nr-crosshair] Menu v2: %s'):format(tostring(result and result.message)))
    end
    return result.value
end

local function closeMenu()
    menuOpen, preview, draft = false, false, nil
    if menuId and GetResourceState('feather-menu-v2') == 'started' then Menu:CloseMenu(menuId) end
end

local function buildMenu()
    if menuId then Menu:DestroyMenu(menuId) end
    menuId, pageId, fields = nil, nil, {}
    menuId = requireResult(Menu:CreateMenu({ key = 'crosshair-settings', draggable = true, closable = true,
        resizable = false, persistPosition = false, keyHints = false,
        position = { x = '25%', y = '50%' }, size = { width = '29rem', maxWidth = '94vw', maxHeight = '85vh' },
        theme = { preset = 'modern' },
    })).menuId
    pageId = requireResult(Menu:CreatePage(menuId, { key = 'main' })).pageId
    local currentMenu = menuId
    requireResult(Menu:RegisterMenuLifecycle(menuId, function(event)
        if event.menuId ~= menuId then return end
        if event.event == 'closed' then menuOpen, preview, draft = false, false, nil
        elseif event.event == 'suspended' then preview = false
        elseif event.event == 'resumed' then preview = menuOpen end
    end))
    local function add(kind, spec, callback)
        return requireResult(Menu:AddElement(menuId, pageId, kind, spec, callback and function(event)
            if menuOpen and menuId == currentMenu and draft then callback(event) end
        end)).elementId
    end
    add('header', { key = 'title', value = text.title, slot = 'header' })
    add('textdisplay', { key = 'help', value = text.help })
    local function colorOptions()
        local options, found = {}, false
        for _, color in ipairs(Crosshair.palette) do
            options[#options + 1] = color
            if color == draft.color then found = true end
        end
        if not found then options[#options + 1] = { value = draft.color, color = draft.color, label = text.customColor } end
        return options
    end
    local function channelValue(key)
        local r, g, b = Crosshair.rgb(draft.color)
        return ({ red = r, green = g, blue = b })[key]
    end
    local function syncColors()
        requireResult(Menu:UpdateElement(menuId, pageId, fields.color, { value = draft.color, options = colorOptions() }))
        for _, key in ipairs({ 'red', 'green', 'blue' }) do
            requireResult(Menu:UpdateElement(menuId, pageId, fields[key], { value = channelValue(key) }))
        end
    end
    local function field(key, kind, options)
        local spec = { key = key, label = text[key], value = draft[key], persist = true }
        if options then spec.options = options end
        local bounds = Crosshair.ranges[key]
        if bounds then spec.min, spec.max, spec.step = bounds[1], bounds[2], Crosshair.steps[key] end
        fields[key] = add(kind, spec, function(event)
            draft[key] = event.value
            draft = Crosshair.sanitize(draft)
            if key == 'color' then syncColors() end
        end)
    end
    field('enabled', 'toggle')
    local styles = {}
    for _, style in ipairs({ 'cross', 'dot', 't', 'box' }) do styles[#styles + 1] = { value = style, label = text[style] } end
    field('style', 'dropdown', styles)
    field('centerDot', 'toggle')
    for _, key in ipairs({ 'size', 'thickness', 'gap' }) do field(key, 'slider') end
    field('outline', 'toggle')
    field('outlineSize', 'slider')
    field('color', 'colorpicker', colorOptions())
    for _, channel in ipairs({ 'red', 'green', 'blue' }) do
        local key = channel
        fields[key] = add('slider', { key = key, label = text[key], value = channelValue(key), min = 0, max = 255, step = 1, persist = true }, function(event)
            local value = event.value
            if type(value) ~= 'number' or value ~= value or value < 0 or value > 255 then return end
            local r, g, b = Crosshair.rgb(draft.color)
            value = math.floor(value + 0.5)
            if key == 'red' then r = value elseif key == 'green' then g = value else b = value end
            draft.color = ('#%02X%02X%02X'):format(r, g, b)
            syncColors()
        end)
    end
    field('opacity', 'slider')
    add('button', { key = 'reset', label = text.reset, slot = 'footer', row = 'actions' }, function()
        draft = Crosshair.defaults()
        for key, id in pairs(fields) do
            if draft[key] ~= nil and key ~= 'color' then
                requireResult(Menu:UpdateElement(menuId, pageId, id, { value = draft[key] }))
            end
        end
        syncColors()
    end)
    add('button', { key = 'cancel', label = text.cancel, slot = 'footer', row = 'actions' }, closeMenu)
    add('button', { key = 'save', label = text.save, slot = 'footer', row = 'actions' }, function()
        local value = Crosshair.sanitize(draft)
        SetResourceKvp(KVP_KEY, json.encode(value))
        settings = value
        closeMenu()
    end)
end

RegisterCommand(Config.Command, function()
    if menuOpen then closeMenu() return end
    if opening or IsNuiFocused() or IsPauseMenuActive() or GetResourceState('feather-menu-v2') ~= 'started' then return end
    opening = true
    CreateThread(function()
        local ok, problem = pcall(function()
            requireResult(Menu:AwaitReady(5000))
            -- A different NUI may have taken focus while readiness was pending.
            if IsNuiFocused() or IsPauseMenuActive() then return end
            draft = Crosshair.sanitize(settings)
            buildMenu()
            menuOpen, preview = true, true
            requireResult(Menu:OpenMenu(menuId))
        end)
        if not ok then
            closeMenu()
            if menuId and GetResourceState('feather-menu-v2') == 'started' then Menu:DestroyMenu(menuId) end
            menuId = nil
            print(tostring(problem))
        end
        opening = false
    end)
end, false)
RegisterKeyMapping(Config.Command, text.command, 'keyboard', '')

local function draw(value, x, y)
    if renderedSettings ~= value then
        rectangles = Crosshair.geometry(value)
        renderedSettings = value
    end
    local width, height = GetActiveScreenResolution()
    if width <= 0 or height <= 0 then return end
    local scale = height / 1080
    local r, g, b = Crosshair.rgb(value.color)
    local alpha = math.floor(value.opacity * 255 / 100 + 0.5)
    local function rectangle(rect, border, red, green, blue)
        DrawRect(x + rect[1] * scale / width, y + rect[2] / 1080,
            (rect[3] + border * 2) * scale / width, (rect[4] + border * 2) / 1080, red, green, blue, alpha)
    end
    -- Draw all outline pieces before colored pieces so intersections stay clean.
    if value.outline and value.outlineSize > 0 then
        for _, rect in ipairs(rectangles) do rectangle(rect, value.outlineSize, 0, 0, 0) end
    end
    for _, rect in ipairs(rectangles) do rectangle(rect, 0, r, g, b) end
end

CreateThread(function()
    while true do
        Wait(0)
        local ped, player = PlayerPedId(), PlayerId()
        local weapon = GetSelectedPedWeapon(ped)
        local scoped = Config.PreserveSniperScope and IsFirstPersonAimCamActive()
            and (GetWeapontypeGroup(weapon) & 0xFFFFFFFF) == SNIPER_GROUP
        local exempt = excluded[weapon] == true
        if Config.HideNativeReticle and not scoped and not exempt then HideHudComponentThisFrame(14) end
        local blocked = IsPauseMenuActive() or IsEntityDead(ped) or IsScreenFadedOut() or IsScreenFadingOut()
            or not IsPlayerPlaying(player)
        if menuOpen then
            if preview and draft and draft.enabled and not blocked then draw(draft, 0.72, 0.5) end
        elseif not blocked and Crosshair.visible({ enabled = settings.enabled, playing = true,
            armed = IsPedArmed(ped, 4), aiming = IsPlayerFreeAiming(player) or IsPlayerTargettingAnything(player),
            focused = IsNuiFocused(), hidden = IsHudHidden(), reloading = IsPedReloading(ped),
            wheel = IsHudComponentActive(19), scoped = scoped, excluded = exempt,
        }) then
            draw(settings, 0.5, 0.5)
        end
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'feather-menu-v2' then
        menuOpen, preview, menuId, pageId, draft = false, false, nil, nil, nil
    elseif resource == GetCurrentResourceName() then
        closeMenu()
        if menuId and GetResourceState('feather-menu-v2') == 'started' then Menu:DestroyMenu(menuId) end
    end
end)
