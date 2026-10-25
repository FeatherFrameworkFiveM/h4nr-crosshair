# H4NR Crosshair — FiveM implementation

## Ownership

Crosshair is a standalone, client-only presentation resource. It owns its
crosshair preferences, native-reticle suppression, native drawing, and Menu v2
consumer integration. Weapons remains responsible for weapon ownership and
runtime authorization; Inventory remains responsible for item instances. There
are no weapon mutations, direct SQL, server events, or framework dependencies.

Menu v2 owns menu rendering, focus and input. Crosshair owns bounded drafts,
Save/Cancel and client KVP persistence. Preferences are installation/player
preferences rather than per-character records. Romanian is the default with
English fallback; the settings menu uses the modern Neon Vice preset.

Resource/repository name: `h4nr-crosshair`, under `resources/[h4nr]`. Renamed
from `feather-crosshair`; existing preferences are imported once from the old
client KVP namespace when the new resource has no saved preferences. The
`/crosshair` player command is unchanged.

## Delivery — 2026-10-25

- Implemented: four configurable static shapes, arbitrary RGB sliders plus eight
  palette colors, fractional dimensions/negative gap, adjustable outline width,
  opacity and optional center dot; 1080p-reference native rectangles.
- Implemented: configurable frame-based HUD component 14 suppression, independent
  of custom enablement; first-person sniper and explicit weapon exemptions.
- Implemented: aiming-only presentation, controller target-lock eligibility,
  reload/death/pause/fade/NUI/wheel/HUD gates, draft preview and persistence.
- Implemented: menu replacement/close/suspend/resume/provider-stop cleanup and
  reconstruction after Menu v2 restart.
- Local evidence: Lua 5.4 model and simulated client tests, covering real consumer
  callbacks/native boundaries. See README for the runnable command.
- Pending: visual, multiplayer/coexistence, device, ReShade, camera/alignment,
  resolution, performance and restart/reconnect acceptance in FiveM.

The existing HUD leaves component 14 available and never explicitly forces it
visible, so a Crosshair per-frame hide composes without a HUD change. Other HUD
implementations that explicitly show it each frame require coexistence review.
Scopes/camera masks are not removed. The centered static crosshair does not
predict impact, enforce accuracy, or track the muzzle ray.

## CS2-style customization menu — 2026-10-25

The player opens `/crosshair` and adjusts the menu, as in the supplied CS2
settings screenshot. Menu v2 renders length/thickness/gap/outline-width sliders
with 0.1 steps; RGB channels use integer 0–255 sliders. Custom hex colors remain
representable in the palette after saving/reopening. Palette selection and RGB
sliders synchronize in both directions; Defaults resets the draft and all color
controls. Native preview updates as the draft changes. Save/Cancel and KVP
migration retain the existing lifecycle. Old settings without `outlineSize`
default to the original one-pixel outline. No console-command customization or
share-code import was added. CS2 dynamic/recoil simulation is outside scope.
