# LibSharedMediaControls-1.0

A status-bar texture selector for WoW Forever's native Settings UI.

The standalone addon bundles LibStub, CallbackHandler-1.0, and LibSharedMedia-3.0.
No separate library installation or AceGUI dependency is required. LibStub's
version checks share the active libraries with other addons' embedded copies.
For embedding, load your LibStub and LibSharedMedia dependencies, then only
`LibSharedMediaControls-1.0.lua`; do not load `Demo.lua` or this project's TOC.
Call the library after the native Settings API is available.

```lua
local category = Settings.RegisterVerticalLayoutCategory("My Addon")
local setting = Settings.RegisterAddOnSetting(category, "MYADDON_BAR", "bar",
    MyAddonSavedVariables, "string", "Bar texture", "Blizzard")
setting:SetValueChangedCallback(function(_, name)
    MyBar:SetStatusBarTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", name))
end)
local initializer = LibStub("LibSharedMediaControls-1.0")
    :CreateStatusbarDropdown(category, setting, "Choose a bar texture.")
Settings.RegisterAddOnCategory(category)
```

The caller initializes its saved variables and owns the setting, callbacks, and
persistence. Proxy settings also work. Change values through `setting:SetValue()`
so Settings receives its normal notifications. The return value is Blizzard's
Settings initializer; the library owns its custom option and selection handlers.

An optional fourth argument supplies a companion native Settings color object:

```lua
local colorSetting = Settings.RegisterAddOnSetting(category, "MYADDON_COLOR", "color",
    MyAddonSavedVariables, "string", "Bar color", "ff3399ff")
Settings.CreateColorSwatch(category, colorSetting, "Choose a preview color.")
LibStub("LibSharedMediaControls-1.0")
    :CreateStatusbarDropdown(category, setting, "Choose a bar texture.", colorSetting)
```

The color value must be an eight-digit `AARRGGBB` string, as used by Forever's
native color swatch. The library reads it with `CreateColorFromHexString()` and
applies RGBA using `SetVertexColor()`, retaining the existing 45% RGB brightness
behind labels. Without a companion setting, the existing gray preview is unchanged.
The library never writes the color setting. While the dropdown control is active,
its native callback handles subscribe to the companion setting and update the
selected preview immediately; Blizzard unregisters these handles on release.
Menu rows read the color each time they initialize. Reopen an already open menu
to ensure every row shows a changed color; no live menu rebuild is performed.

LSM's sorted `List("statusbar")` is read on each menu generation. Row initializers
call `Fetch()` and attach a dimmed texture behind each row's label through Blizzard's compositor. Native
highlight radios handle hover and selection, calling `setting:SetValue(name)`.
The selected texture also fills the dropdown behind its label. Missing names remain stored
and display as text. `Fetch()` honors LSM's global media override, if configured.
New media appears on reopening; there is no live registry subscription or cache.

## Client exercise

With the standalone addon enabled, run `/lsmc`. Select several
textures and confirm their names, previews, and printed change callbacks. Close
and reopen the menu and Settings, and scroll enough to exercise reused rows.
Use the native Preview color swatch and check the selected background updates
while adjusting the picker and on cancel. Reopen the texture menu to check matching
tints on every row. Selecting textures should leave the color unchanged. Check
Defaults and persistence after reload, and verify an untinted consumer still has
the original gray previews after a tinted control has used the same pooled frame.
Run `/lsmc set` to change the setting through its normal API. Run `/lsmc register`
after first opening the menu, then reopen it and select the newly added texture.
Reload the UI to check persistence. Switch to other Settings dropdowns to check
that preview artwork does not leak into reused frames. Repeat normal interactions
with Lua errors and taint logging enabled, including in combat. These client
checks require WoW and have not been run by the implementation environment.

Scope is status-bar textures only. Invalid asset paths remain the media provider's
responsibility. Fonts need font-string initialization, sounds need explicit
playback behavior, and borders need different geometry; these are not implemented.
