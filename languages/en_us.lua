-- Player-visible text. ro is the default; en_us has the same keys (tests/run.py checks).
Locales = Locales or {}

Locales.en_us = { title = 'Crosshair settings', help = 'Preview on the right. Changes apply after Save.',
        enabled = 'Custom crosshair', style = 'Style', cross = 'Cross', dot = 'Dot', t = 'T shape', box = 'Square',
        color = 'Quick colors', customColor = 'Custom', red = 'Red', green = 'Green', blue = 'Blue',
        size = 'Length', gap = 'Center gap', thickness = 'Thickness', outlineSize = 'Outline thickness',
        opacity = 'Opacity (%)', outline = 'Black outline', centerDot = 'Center dot',
        reset = 'Defaults', cancel = 'Cancel', save = 'Save', command = 'Open crosshair settings',
        on = 'On', off = 'Off',
        paletteLabels = { 'White', 'Electric blue', 'Cyan', 'Mint green', 'Yellow', 'Red', 'Pink', 'Violet' },
    chatSuggestion = 'Open custom crosshair settings',
}
