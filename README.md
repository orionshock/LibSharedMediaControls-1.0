# LibSharedMediaControls-1.0

Native Blizzard Settings selectors for LibSharedMedia status-bar textures,
fonts, and backgrounds in WoW Forever. Borders and sounds are not implemented.

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

## Background textures

```lua
local initializer = LSMC:CreateBackgroundDropdown(category, setting, tooltip, colorSetting)
```

| Argument | Value |
| --- | --- |
| `category` | Native vertical-layout Settings category |
| `setting` | String Settings object containing an LSM `"background"` name |
| `tooltip` | Tooltip string or `nil` |
| `colorSetting` | Optional string Settings object containing eight hexadecimal digits: `AARRGGBB` |

The constructor adds the dropdown to the category and returns its native Settings
initializer. The addon owns both settings, persistence, the companion's control,
and applying the selected background to its UI. Selecting an entry writes only
the registered name to the primary setting through `SetValue()`.

Without a color companion, previews use vertex color `(1, 1, 1, 1)` and retain
the texture's original colors and transparency. With a companion, previews apply
its RGBA directly, without the status-bar selector's 45% dimming.

The open menu displays one background behind all its options. It starts with the
selected texture; hovering an option previews that texture across the menu.
The last hovered preview remains until another entry is hovered or the menu closes.
Hovering does not write the setting. Clicking selects normally, and the closed
control continues to display the selected texture behind its label.
Native highlighting and label shadows remain in place; there is no extra
backdrop or border. Texture lookup, missing-name behavior, live selected tint,
menu reopening, and pooled-region cleanup follow the status-bar behavior.
Each media type has its own implementation and lifecycle code; constructors
share only the library registration and top-level LibSharedMedia reference.
Backgrounds stretch to fit the preview rectangle; they do not tile or reproduce
the consuming addon's final background dimensions. Bright textures can reduce
label contrast. The library does not darken them automatically.

The library reads `List("background")` when generating the menu and calls
`Fetch("background", name)` for hovered artwork. The selected control requests no
default when fetching its texture. Missing names remain stored; menu lookup uses
LSM's normal fallback, and global overrides follow LSM semantics. The registered
`"None"` option clears the artwork while retaining its selectable name.

Native companion callbacks update the selected tint immediately while the
control is active. Hover another option to refresh the menu tint, or reopen it
to start again with the selected texture and discover newly registered media.
Menu acquisition attaches a single compositor-managed texture, released when
the menu closes. The library assigns each reused texture's path and vertex
color explicitly, hides selected artwork on release, and lets Blizzard remove
the control's callback handles.

```lua
local background = Settings.RegisterAddOnSetting(category, "MYADDON_BACKGROUND",
    "background", MyAddonDB, "string", "Background texture", "Blizzard Dialog Background")
local backgroundColor = Settings.RegisterAddOnSetting(category, "MYADDON_BACKGROUND_COLOR",
    "backgroundColor", MyAddonDB, "string", "Background color", "ffffffff")
Settings.CreateColorSwatch(category, backgroundColor, "Tint the background preview.")
LSMC:CreateBackgroundDropdown(category, background, "Choose a background.", backgroundColor)

local function ApplyBackground()
    MyBackgroundTexture:SetTexture(LSM:Fetch("background", background:GetValue()))
    MyBackgroundTexture:SetVertexColor(
        CreateColorFromHexString(backgroundColor:GetValue()):GetRGBA())
end
background:SetValueChangedCallback(ApplyBackground)
backgroundColor:SetValueChangedCallback(ApplyBackground)
ApplyBackground()
```

This example assumes an initialized `MyAddonDB`, an existing category, and a
Texture region named `MyBackgroundTexture` owned by your addon. Declare the saved
variable in your TOC. Omit the fourth constructor argument for an untinted selector.

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
Status Bars, Fonts, and Backgrounds sections. Each groups its companion controls
before its selector. Backgrounds has its own independent color swatch. Values
persist in `LibSharedMediaControlsDemoDB`.
Selection callbacks print the chosen names.
The Backgrounds section defaults to `"Blizzard Dialog Background"` and white tint.
Check independent tint changes against the status-bar color, select `"None"`,
reopen after `/lsmc register`, and switch between background, status-bar, and font
menus to check reused artwork and colors. Also exercise a background selector
without a companion to verify original texture colors after tinted frame reuse.

| Command | Behavior |
| --- | --- |
| `/lsmc` | Open the demo |
| `/lsmc set` | Set the texture setting to `"Blizzard"` through its native API |
| `/lsmc register` | Register late status-bar, font, and background entries; reopen their menus to see them |

Exercise selection, companions, picker cancel, hover colors, menu reopening,
scrolling, long names, Defaults, and persistence after reload. Switch to unrelated
Settings dropdowns to check pooled-frame cleanup. Watch for Lua errors and taint
or blocked-action warnings during normal interactions, including in combat.
Syntax and lint checks do not establish runtime behavior in Forever.
