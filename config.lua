Config = {}
Config.DefaultLang = 'ro' -- ro / en_us
Config.Command = 'crosshair'

-- Server policy: independent of the player's custom-crosshair enabled toggle.
Config.HideNativeReticle = true
-- Keep native sniper sights when looking through a sniper scope.
Config.PreserveSniperScope = true
-- Additional scoped/custom weapons that should retain their own sights.
Config.ExcludedWeapons = {} -- e.g. { 'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER' }

-- Size/gap/thickness are pixels at 1080p and scale with screen height.
Config.Defaults = {
    enabled = true,
    style = 'cross', -- cross / dot / t / box
    color = '#00BFFF',
    size = 7,
    gap = 4,
    thickness = 2,
    opacity = 100,
    outline = true,
    centerDot = false,
}
