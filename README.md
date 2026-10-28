# H4NR Crosshair

Small GTA V/FiveM crosshair resource with client rendering. Works alongside
`feather-weapons` or another weapon system; requires only `feather-menu-v2` for
its settings menu. An optional server integration registers its command suggestion
with `feather-chat`. No database, Core, Inventory, frontend build, or additional
NUI page is needed.

## Install

Place the resource in `resources/[h4nr]/h4nr-crosshair`, then start:

```cfg
ensure feather-menu-v2
ensure h4nr-crosshair
```

If the server already starts the entire `[h4nr]` group, its explicit menu
dependency handles ordering. For an already-running server, run `refresh` and
`ensure h4nr-crosshair` in the server console. No change to `feather-weapons`
or `feather-hud` is required. Avoid running another custom-crosshair resource at
the same time.

Renamed from `feather-crosshair`. Stop the old resource before starting this one
and replace any explicit `ensure feather-crosshair` configuration entry with
`ensure h4nr-crosshair`. Existing client preferences are imported once from the
old resource's KVP when no settings exist under the new name. `/tinta`
is the player command.

## Player settings

Use **`/tinta`**. An optional key can be assigned in FiveM key bindings.
Romanian is the default language; `Config.DefaultLang = 'en_us'` selects English.
Romanian covers the menu labels, help, style choices, toggle states, palette
color names, action buttons, key-binding description, and chat suggestion.
With `feather-chat` running, the configured command appears in autocomplete.
The suggestion registers at startup and again after Chat restarts. Chat releases
its input focus before executing the command, allowing the settings menu to
take focus. In F8, enter `tinta` without the slash.

- Cross, square dot, T shape, or square outline.
- CS2-style controls for length, thickness, gap, outline thickness, RGB color,
  opacity, style and optional center dot. Length, thickness, gap and outline
  support 0.1 increments, including negative gaps for overlapping arms.
- Red, Green and Blue sliders each support 0–255 for any RGB color. Eight quick
  palette colors remain available and stay synchronized with the RGB sliders.
- Live preview to the right of the menu. The crosshair preview is hidden when
  its Enabled toggle is off.
- **Save** applies and persists preferences in client KVP.
- **Cancel**, Escape, menu replacement, or provider stop discard the draft.
- **Defaults** resets the draft; press Save to apply it.

Preferences survive reconnects and resource restarts on that client installation;
they are shared by that player's characters, not stored in character SQL.
Clearing the client's KVP data removes them.

## Server configuration

Edit `config/shared.lua` (texts in `languages/`) and restart the resource. Settings are bounded and allowlisted,
including values loaded from KVP. `Config.Defaults` applies when no saved
preference exists and when the player chooses Defaults.

| Setting | Default | Meaning |
| --- | --- | --- |
| `Command` | `tinta` | Player settings command; also registered for optional key binding. |
| `HideNativeReticle` | `true` | Hide GTA HUD component 14 each frame, independently of the player's Enabled setting. Turning the custom crosshair off therefore gives no ordinary reticle. |
| `PreserveSniperScope` | `true` | While aiming through a first-person sniper-group scope, leave native sights available and omit the custom crosshair. Set false to suppress its reticle and draw the custom crosshair when eligible. This does not remove the scope camera/mask. |
| `ExcludedWeapons` | `{}` | Weapon-name array that bypasses both custom drawing and native suppression. Useful for weapons with special sights. |
| `Defaults.enabled` | `true` | Enable the custom crosshair. |
| `Defaults.style` | `cross` | `cross`, `dot`, `t`, or `box`. |
| `Defaults.color` | `#00BFFF` | Any six-digit RGB hex color (`#RRGGBB`). |
| `Defaults.size` | `7` | Arm length, or square-dot side, 0–64 reference pixels, step 0.1. |
| `Defaults.gap` | `4` | Inner gap, -32–64 reference pixels, step 0.1; square radius is max(0, size + gap). Ignored for dot. |
| `Defaults.thickness` | `2` | Line/center-dot thickness, 0.1–16 reference pixels, step 0.1. Ignored for the main dot. |
| `Defaults.opacity` | `100` | 0–100 percent, including the outline. |
| `Defaults.outline` | `true` | Enable the black outline. |
| `Defaults.outlineSize` | `1` | Black outline thickness, 0–8 reference pixels, step 0.1. |
| `Defaults.centerDot` | `false` | Add a center dot to cross, T, or square. |

Dimensions scale from a 1080p reference using screen height, with horizontal
normalization to keep proportions on wide displays. The aiming point is fixed
at screen center; this is a static visual aid, not a projection of bullet impact,
recoil, weapon spread, or the muzzle ray. Special camera/weapon modes require
live verification and may need an `ExcludedWeapons` entry.

The screenshot-inspired controls adjust this resource's static crosshair.
They do not reproduce CS2 recoil, dynamic spread, game-specific measurement
units, or share-code import. Use `/tinta` to open the menu and change
settings with its sliders; no console variables are required.

The custom crosshair appears only while aiming a firearm (including controller
targeting). It is hidden during reload, death, pause, screen fade, NUI focus,
hidden native HUD, and the weapon wheel. The settings preview is independent of
aiming and uses the draft. Sniper and excluded-weapon exceptions apply to
gameplay, not the preview.

Native suppression uses Cfx's [HUD component 14](https://github.com/citizenfx/natives/blob/master/HUD/HideHudComponentThisFrame.md).
Rendering uses [DrawRect](https://github.com/citizenfx/natives/blob/master/GRAPHICS/DrawRect.md)
without textures, browser blur, or NUI messages. Stopping this resource ends its
frame-based drawing/suppression; other HUD resources retain their own policies.

## Verification

```sh
python3 tests/run.py
```

Requires the Lua 5.4 shared library (`liblua5.4`). The offline suite exercises
validation, geometry, aspect correction, native boundaries, drafts, persistence,
scope policy, and provider restart with simulated Cfx services.

Live FiveM acceptance remains required: check pistol/rifle/shotgun/taser,
controller aim, first/third person, scope entry/exit, mounted scopes and special
weapons, vehicle aim, reload, death/respawn, menus, pause, different resolutions,
and affected ReShade setups. Confirm Save survives a reconnect; Cancel/Escape
must restore the saved crosshair. Restart both resources and verify menu/focus
recovery. Confirm ordinary native reticles stay hidden, sniper exceptions work,
and stopping the resource restores the previous HUD policy. Offline tests do
not establish visual alignment, performance, or in-game acceptance.
