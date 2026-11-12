# LibSharedMediaControls-1.0

Native Blizzard Settings selectors for LibSharedMedia status-bar textures and
fonts in WoW Forever. Backgrounds, borders, and sounds are not implemented.

## Loading

The standalone addon bundles LibStub, CallbackHandler-1.0, and LibSharedMedia-3.0.
Its TOC loads them before the library and opt-in demo. A separate LibSharedMedia
installation is unnecessary. LibStub version checks allow the dependencies to
coexist with copies embedded in other addons. There are no AceGUI, AceConfig,
or AceDB dependencies.

To embed, load LibStub, CallbackHandler-1.0, and LibSharedMedia-3.0 before
`LibSharedMediaControls-1.0.lua`. Use your existing dependencies or the bundled
copies. Do not load this project's TOC or `Demo.lua` when embedding. Ensure
`Blizzard_Settings_Shared` is loaded before calling the constructors.

```lua
local LSMC = LibStub("LibSharedMediaControls-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
```

## Common contract

Create a vertical-layout Settings category and native Settings objects first.
Each constructor adds one dropdown to the category and returns its native
Settings initializer. Construct once per selector during Settings setup. Do not
add the returned initializer to the layout again.

The addon owns its category, setting registration, persistence, companion
controls, change callbacks, and applying values to its actual UI. Both
`Settings.RegisterAddOnSetting()` and `Settings.RegisterProxySetting()` objects
work. A proxy can use AceDB, but the library has no knowledge of that storage.

The primary setting must have type `"string"` and contain a registered LSM media
**name**. Selecting an entry calls `setting:SetValue(name)`. The library handles
media enumeration, lookup, previews, and native menu interaction. It does not
write resolved paths or modify companion settings.

Companions are optional native Settings objects, not getters or saved-variable
tables. Supply valid values in the formats below and create their controls
where appropriate. Pass `nil` for omitted positional arguments, such as a font
color without a size setting.

Use `setting:SetValue()` for programmatic changes so native notifications fire.
Direct writes to saved-variable tables bypass those notifications. Apply initial
values to your addon yourself; constructing a selector does not initialize your
bars or text, and preview callbacks do not apply changes to your addon.

The return value is an initializer, not a persistent dropdown frame. The library
owns its `InitFrame`, `Resetter`, `customOptionHandler`, and
`getSelectionTextFunc`. Replacing these handlers breaks preview setup or cleanup.

## Status-bar textures

```lua
local initializer = LSMC:CreateStatusbarDropdown(category, setting, tooltip, colorSetting)
```

| Argument | Value |
| --- | --- |
| `category` | Native vertical-layout Settings category |
| `setting` | String Settings object containing an LSM `"statusbar"` name |
| `tooltip` | Tooltip string or `nil` |
| `colorSetting` | Optional string Settings object containing eight hexadecimal digits: `AARRGGBB` |

The texture fills the background behind each entry's name and the selected
value. RGB channels are multiplied by 0.45 for readability; alpha passes through
unchanged. Without a companion, the preview uses `(0.45, 0.45, 0.45, 1)`.
This dimming affects previews only, not the addon's own bar.

Missing names remain stored. Menu entries use LSM's normal `Fetch()` fallback.
The selected preview requests no default texture, leaving the name visible
without artwork when its texture is unavailable. LSM global overrides still
apply according to `Fetch()` semantics.

## Fonts

```lua
local initializer = LSMC:CreateFontDropdown(
    category, setting, tooltip, sizeSetting, colorSetting, outlineSetting
)
```

`category` and `tooltip` have the same meaning as above. `setting` must be a
string Settings object containing an LSM `"font"` name.

| Optional companion | Settings type and value | Default |
| --- | --- | --- |
| `sizeSetting` | `"number"`, font size in pixels | 14 |
| `colorSetting` | `"string"`, eight-digit `AARRGGBB` | White |
| `outlineSetting` | `"string"`: `""`, `"OUTLINE"`, or `"THICKOUTLINE"` | No outline |

Media names render in their registered fonts in both the menu and selected
control. Other outline values render without an outline. Preview sizes are
clamped to 8-32 in menus and 8-18 in the selected control to fit its height.
These limits do not change companion values or the addon's own text.

Companion colors use native inline color markup so hover and selection styling
cannot replace them. The stored name remains plain text. Menu label width is
capped at 400 pixels; long names can truncate, especially in the selected control.
Fonts and their glyph coverage are assumed usable; the library does not validate
them or add fallback machinery.

The library configures reusable Font objects and applies them with
`SetFontObject()`. Blizzard's menu compositor prohibits `SetFont()` on attached
FontStrings. The library refetches font paths when updating previews.

## Addon example

Run this after your saved variables and Settings API are ready. Declare
`MyAddonDB` in your addon's TOC and create the `MyBar` and `MyText` frames first.
The shared color in this example affects both selectors.

```lua
MyAddonDB = MyAddonDB or {}
local category = Settings.RegisterVerticalLayoutCategory("My Addon")
local function AddSetting(variable, key, kind, label, default)
    return Settings.RegisterAddOnSetting(category, variable, key, MyAddonDB,
        kind, label, default)
end

local bar = AddSetting("MYADDON_BAR", "bar", "string", "Bar texture", "Blizzard")
local color = AddSetting("MYADDON_COLOR", "color", "string", "Color", "ff3399ff")
Settings.CreateColorSwatch(category, color, "Choose a color.")
LSMC:CreateStatusbarDropdown(category, bar, "Choose a bar texture.", color)

local font = AddSetting("MYADDON_FONT", "font", "string", "Font", LSM:GetDefault("font"))
local size = AddSetting("MYADDON_SIZE", "size", "number", "Font size", 14)
Settings.CreateSlider(category, size, Settings.CreateSliderOptions(8, 32, 1))
LSMC:CreateFontDropdown(category, font, "Choose a font.", size, color)

local function ApplyAppearance()
    local rgba = CreateColorFromHexString(color:GetValue())
    MyBar:SetStatusBarTexture(LSM:Fetch("statusbar", bar:GetValue()))
    MyBar:SetStatusBarColor(rgba:GetRGBA())
    MyText:SetFont(LSM:Fetch("font", font:GetValue()), size:GetValue(), "")
    MyText:SetTextColor(rgba:GetRGBA())
end
for _, setting in ipairs({bar, color, font, size}) do
    setting:SetValueChangedCallback(ApplyAppearance)
end
Settings.RegisterAddOnCategory(category)
ApplyAppearance()
```

For an outline companion, register a string setting with default `""`, provide
a native dropdown with the three supported values, and pass the setting as the
sixth argument to `CreateFontDropdown()`. The demo contains an example. For an
untinted status-bar selector, omit its fourth argument.

## Refresh and lifecycle

The library reads LSM's sorted `List()` whenever the native menu generates its
contents. New media appears on reopening. There is no private registry copy,
permanent media subscription, polling, or `OnUpdate` script.

Primary setting notifications update the selected value through native Settings.
While a control is active, native callback handles listen for companion changes
and update its selected preview immediately. Menu rows read companions when they
initialize. Reopen an already-open menu to refresh every row; changing color or
size does not rebuild an open menu.

Blizzard's compositor owns menu artwork and FontStrings. Initializers set their
appearance again for pooled-frame reuse. On release, the library hides the
selected texture or restores the selected font label's original font object and
color. Blizzard unregisters the control's callback handles.

Changes to LSM registrations or global overrides have no separate live refresh
subscription. Reopening the menu fetches their current values. Invalid media
assets remain the provider's responsibility.

## Standalone demo and client checks

Run `/lsmc` to create and open the opt-in native Settings category. It includes
the status-bar selector and color control, then a Fonts section with size, color,
outline, and font controls. Values persist in `LibSharedMediaControlsDemoDB`.
Selection callbacks print the chosen names.

| Command | Behavior |
| --- | --- |
| `/lsmc` | Open the demo |
| `/lsmc set` | Set the texture setting to `"Blizzard"` through its native API |
| `/lsmc register` | Register a late texture and font; reopen their menus to see them |

Exercise selection, companions, picker cancel, hover colors, menu reopening,
scrolling, long names, Defaults, and persistence after reload. Switch to unrelated
Settings dropdowns to check pooled-frame cleanup. Watch for Lua errors and taint
or blocked-action warnings during normal interactions, including in combat.
Syntax and lint checks do not establish runtime behavior in Forever.
