Crosshair = {}

Crosshair.palette = { '#FFFFFF', '#00BFFF', '#00FFFF', '#5EF2A0', '#FFFF00', '#FF5050', '#FF66CC', '#B388FF' }
Crosshair.ranges =
    { size = { 0, 64 }, gap = { -32, 64 }, thickness = { 0.1, 16 }, opacity = { 0, 100 }, outlineSize = { 0, 8 } }
Crosshair.steps = { size = 0.1, gap = 0.1, thickness = 0.1, opacity = 1, outlineSize = 0.1 }
local styles = { cross = true, dot = true, t = true, box = true }
local base = {
    enabled = true,
    style = 'cross',
    color = '#00BFFF',
    size = 7,
    gap = 4,
    thickness = 2,
    opacity = 100,
    outline = true,
    outlineSize = 1,
    centerDot = false,
}

local function normalize(value, fallback)
    local result = {}
    value = type(value) == 'table' and value or {}
    for key, default in pairs(fallback) do
        local candidate = value[key]
        if Crosshair.ranges[key] then
            local bounds = Crosshair.ranges[key]
            if type(candidate) ~= 'number' or candidate ~= candidate or math.abs(candidate) == math.huge then
                candidate = default
            end
            local step = Crosshair.steps[key]
            result[key] = math.floor(math.max(bounds[1], math.min(bounds[2], candidate)) / step + 0.5) * step
        elseif key == 'style' then
            result[key] = styles[candidate] and candidate or default
        elseif key == 'color' then
            result[key] = default
            if type(candidate) == 'string' and candidate:match('^#%x%x%x%x%x%x$') then
                result[key] = candidate:upper()
            end
        else
            if type(candidate) == 'boolean' then
                result[key] = candidate
            else
                result[key] = default
            end
        end
    end
    return result
end

function Crosshair.defaults()
    return normalize(Config.Defaults, base)
end

function Crosshair.sanitize(value)
    return normalize(value, Crosshair.defaults())
end

function Crosshair.rgb(color)
    return tonumber(color:sub(2, 3), 16), tonumber(color:sub(4, 5), 16), tonumber(color:sub(6, 7), 16)
end

-- Rectangles in 1080p reference pixels, relative to the aiming point.
function Crosshair.geometry(settings)
    local rectangles = {}
    local function rect(x, y, w, h)
        if w > 0 and h > 0 then
            rectangles[#rectangles + 1] = { x, y, w, h }
        end
    end
    local size, gap, thickness = settings.size, settings.gap, settings.thickness
    if settings.style == 'dot' then
        rect(0, 0, size, size)
    elseif settings.style == 'box' then
        local radius = math.max(0, size + gap)
        rect(0, -radius, radius * 2 + thickness, thickness)
        rect(0, radius, radius * 2 + thickness, thickness)
        rect(-radius, 0, thickness, radius * 2 + thickness)
        rect(radius, 0, thickness, radius * 2 + thickness)
    else
        local offset = gap + size / 2
        rect(-offset, 0, size, thickness)
        rect(offset, 0, size, thickness)
        rect(0, offset, thickness, size)
        if settings.style ~= 't' then
            rect(0, -offset, thickness, size)
        end
    end
    if settings.centerDot and settings.style ~= 'dot' then
        rect(0, 0, thickness, thickness)
    end
    return rectangles
end

function Crosshair.visible(state)
    return state.enabled
        and state.playing
        and state.armed
        and state.aiming
        and not (
            state.dead
            or state.paused
            or state.focused
            or state.hidden
            or state.reloading
            or state.wheel
            or state.scoped
            or state.excluded
        )
end
