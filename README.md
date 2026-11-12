# LibSharedMediaControls-1.0

Native Blizzard Settings selectors for LibSharedMedia status-bar textures,
fonts, backgrounds, borders, and sounds in WoW Forever.

MIT licensed. Copyright (c) 2026 Orionshock. See [License](#license) for
the separate notices covering bundled dependencies.

## Loading

### Standalone addon

Download the packaged addon ZIP from GitHub Releases, rather than GitHub's
automatic source archives. Extract `LibSharedMediaControls-1.0` into Forever's
`Interface/AddOns` directory. The standalone package intentionally includes
`Demo.lua`; run `/lsmc` in-game to open it. Loading the addon registers the slash
command, but the demo category and its settings are created only when invoked.

The standalone addon bundles LibStub, CallbackHandler-1.0, and LibSharedMedia-3.0.
Its TOC loads them before the library and opt-in demo. A separate LibSharedMedia
installation is unnecessary. LibStub version checks allow the dependencies to
coexist with copies embedded in other addons. There are no AceGUI, AceConfig,
or AceDB dependencies.

### Single-file embedding

To embed, load LibStub, CallbackHandler-1.0, and LibSharedMedia-3.0 before
`LibSharedMediaControls-1.0.lua`. Use your existing dependencies or the bundled
copies. Do not load this project's TOC or `Demo.lua` when embedding. Ensure
`Blizzard_Settings_Shared` is loaded before calling the constructors.
Copy only `LibSharedMediaControls-1.0.lua` into your addon and list it before your
Settings setup file in your TOC. The Lua file includes its MIT notice. LibStub and
LibSharedMedia-3.0 must already be available; CallbackHandler-1.0 is LSM's transitive
dependency. Your addon loads those dependencies and owns its saved variables.
Neither the one-file library nor its constructors register the `/lsmc` demo.

```lua
local LSMC = LibStub("LibSharedMediaControls-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
```

## Common contract

Create a vertical-layout Settings category and native Settings objects first.
Each constructor adds one dropdown to the category and returns its native
Settings initializer. Construct once per selector during Settings setup. Do not
add the returned initializer to the layout again.

Use a separate constructor call for each row, including rows in different
categories. Separate selectors may refer to the same setting, but their
initializers must not be shared between simultaneously displayed rows. The
library asserts this before a second row can overwrite active preview state.
Each constructor owns its callbacks, previews, Font objects, and sound handle.
The persistent font-name counter only supplies unique global Font object names.
Settings variable names are global to Blizzard Settings; addons must choose
their own unique names, such as `MYADDON_BACKGROUND`, in registration calls.

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

## Settings search

All five constructors retain Blizzard's native Settings search support. Forever
automatically indexes the setting's display name. Add keywords through the
returned initializer when the consuming addon needs additional search terms:

```lua
local initializer = LSMC:CreateFontDropdown(category, fontSetting, tooltip)
initializer:AddSearchTags("font", "typeface", "text appearance")
```

Search finds the Settings control; it does not search or filter the media options
inside its dropdown. Registered media names and tooltip text are not automatically
indexed. The consuming addon owns any additional search tags.

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
Menu label width is capped at 400 pixels to keep long names from expanding the
menu indefinitely. Native label truncation and selected-control width still apply.

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
If LSM returns no font path at all, the saved name remains visible in Blizzard's
native font. This handles an unavailable registration or empty registry without
checking whether a registered file exists or renders correctly.

The library configures reusable Font objects and applies them with
`SetFontObject()`. Blizzard's menu compositor prohibits `SetFont()` on attached
FontStrings. The library refetches font paths when updating previews.

## Borders

```lua
local initializer = LSMC:CreateBorderDropdown(
    category, borderSetting, tooltip, colorSetting, edgeSizeSetting
)
```

`category` is a native vertical-layout category, `borderSetting` is a string
Settings object holding an LSM `"border"` name, and `tooltip` is a string or `nil`.
The constructor adds the control to the layout and returns its native initializer.

| Optional companion | Settings type and value | Default |
| --- | --- | --- |
| `colorSetting` | `"string"`, eight-digit `AARRGGBB` | White |
| `edgeSizeSetting` | `"number"`, backdrop edge size in pixels | 8 |

The open menu has an isolated `BackdropTemplate` child that uses the fetched
texture as its `edgeFile`. Blizzard's backdrop implementation renders corners
and tiled edges. It does not replace Blizzard's menu border or background.
The preview sits inside the menu boundary, below the option frames, with mouse
input disabled. It is not part of the scrollable row layout.

Opening applies the currently selected border. Hovering changes only the menu
preview; its last hovered border remains until the next hover or close. Clicking
calls `borderSetting:SetValue(name)`. `"None"` clears the preview border.
LSM enumeration runs on menu generation, and artwork comes from `Fetch("border", name)`.
Registered media is assumed usable; no alternate border renderer or asset
validation is provided.

The closed control also has a small isolated border preview inside its normal
boundary. Companion notifications update this selected preview live. Menu edges
are limited to 1-32 pixels; the short selected control limits them to 1-8 pixels.
These limits affect previews only. Large menu edges may overlap more of the list
area, though labels and native highlights draw above them. Reopen the menu to
apply companion changes to its initial preview, or hover another entry to read
their current values.

The library creates one reusable selected-preview frame per native dropdown.
Menu acquisition uses the compositor's `AttachTemplate("BackdropTemplate")` pool.
It explicitly resets anchors, layering, size-change script, artwork, and tint on
reuse. The release callback clears the backdrop, removes its size-change script,
and hides the frame before Blizzard releases it. Selected previews clear and
hide on Settings control release; native callback handles unregister normally.

The addon owns settings, persistence, companion controls, and applying the border
to its actual UI. Its own frame can use `SetBackdrop({edgeFile = path, edgeSize = size})`
and `SetBackdropBorderColor(r, g, b, a)` through a native `BackdropTemplate`.
The demo shows registration of the color swatch and edge-size slider.

## Sounds

```lua
local initializer = LSMC:CreateSoundDropdown(category, soundSetting, tooltip, channelSetting)
```

`category` is a native vertical-layout category, `soundSetting` is a string
Settings object holding an LSM `"sound"` name, and `tooltip` is a string or `nil`.
The optional `channelSetting` is a native string Settings object. Use `"Master"`,
`"SFX"`, `"Music"`, `"Ambience"`, or `"Dialog"`; the default is `"SFX"`.
The addon owns settings, persistence, and any companion channel control.

Each native radio entry has a separate speaker button created with Blizzard's
`MenuTemplates.AttachBasicButton()`. Clicking the name selects through
`soundSetting:SetValue(name)`. The speaker consumes its own click, reads the
current channel, and calls `PlaySoundFile(LSM:Fetch("sound", name), channel)`.
It does not select the entry or close the menu. Hovering, opening, and selecting
do not automatically preview sounds. Native menu UI feedback can still play.

A speaker button beside the closed dropdown previews the current selected sound.
It reads both settings at click time and never changes the selection. This button
is reused with its native Settings row, hidden and disconnected on release, and
shares the same playback handle as the menu's speaker buttons.

Only one preview from this selector plays at a time. A new speaker click stops
the previous handle with `StopSound()`. Closing its open menu, selecting an entry,
or switching away from that menu stops playback through the native release callback.
The compositor releases menu speaker buttons and icon textures with their rows.
Hiding the Settings control also stops its current preview.
Playback started beside the closed dropdown has no menu lifetime until that
selector's menu is opened. An unrelated dropdown opening while the control
remains visible does not stop this playback. Different sound selectors own
independent handles and do not stop each other's closed-control previews.
There are no playback events, completion polling, or persistent audio handlers.

LSM's `"None"` entry uses file ID 1. The library skips that value, so its speaker
is silent and also stops a previous preview. Missing or empty fetched values are
silent. Registered filenames and file IDs otherwise go directly to the playback
API; LSM accepts `.ogg` and `.mp3` file paths. The library does not validate audio
assets or change global sound CVars. Existing channel volume and enable settings
can make previews inaudible. No preview-volume control is provided: the extracted
native volume-override interface targets sound kits rather than LSM file playback.

The sound list is enumerated on menu generation and its path is fetched on each
speaker click. Reopen to discover new names. Channel changes need no subscription
or menu rebuild because the click reads `channelSetting:GetValue()` directly.
The returned initializer is already registered with the category layout.
Saved names that are no longer registered remain visible instead of showing
Blizzard's generic `Custom` label; preview lookup still follows LSM semantics.

```lua
local sound = Settings.RegisterAddOnSetting(category, "MYADDON_SOUND", "sound",
    MyAddonDB, "string", "Sound", "None")
LSMC:CreateSoundDropdown(category, sound, "Click the speaker to preview.")
-- Handle sound:SetValueChangedCallback() in your addon if selection needs action.
-- Play the chosen sound from your own event handler, not the selection callback,
-- when selection itself should remain silent.
```

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
Status Bars, Fonts, Backgrounds, Borders, and Sounds sections. Each groups its companion controls
before its selector. Backgrounds has its own independent color swatch. Values
persist in `LibSharedMediaControlsDemoDB`.
Selection callbacks print the chosen names.
The Backgrounds section defaults to `"Blizzard Dialog Background"` and white tint.
Check independent tint changes against the status-bar color, select `"None"`,
reopen after `/lsmc register`, and switch between background, status-bar, and font
menus to check reused artwork and colors. Also exercise a background selector
without a companion to verify original texture colors after tinted frame reuse.
Borders includes its own color swatch and edge-size slider. Check corners and
edges at different sizes, hover without selecting, then close or open an unrelated
dropdown to check cleanup. Reopening must start with the current selection.
Check `"None"`, companion changes, scrolling, and the late border registration.
Sounds includes a channel selector and registers two built-in demo sound IDs so
multiple previews can be compared without another media addon. Check speaker
clicks leave the selected name unchanged, name clicks select without previewing,
and a new preview stops the previous one. Test all five channels, `"None"`, menu
closing, switching dropdowns, scrolling, and late registrations. Actual playback
and child-button interaction still require verification in Forever.

| Command | Behavior |
| --- | --- |
| `/lsmc` | Open the demo |
| `/lsmc set` | Set the texture setting to `"Blizzard"` through its native API |
| `/lsmc register` | Register late entries for all five media types; reopen their menus to see them |

Exercise selection, companions, picker cancel, hover colors, menu reopening,
scrolling, long names, Defaults, and persistence after reload. Switch to unrelated
Settings dropdowns to check pooled-frame cleanup. Watch for Lua errors and taint
or blocked-action warnings during normal interactions, including in combat.
Syntax and lint checks do not establish runtime behavior in Forever.

## Packaging and releases

The official [BigWigsMods packager](https://github.com/BigWigsMods/packager) reads
`.pkgmeta` and packages the existing tracked dependencies. No externals, nolib
archive, extra client variants, or separate embedding build are configured.
The target is WoW Forever, Interface `16001`.

The standalone ZIP contains this directory, plus the packager's generated changelog:

```text
LibSharedMediaControls-1.0/
    LibSharedMediaControls-1.0.toc
    LibSharedMediaControls-1.0.lua
    Demo.lua
    LICENSE
    README.md
    libs/
        LibStub/                 (Lua source and existing license)
        CallbackHandler-1.0/     (Lua source and existing license)
        LibSharedMedia-3.0/       (Lua source and LGPL license)
```

Development instructions, workflows, editor files, and local build artifacts
are excluded. The demo and all files referenced by the TOC remain included.

The release workflow runs only when a `v*` tag is pushed and rejects lightweight
tags. It checks out full history and invokes `BigWigsMods/packager@v2` using
GitHub's provided token with `contents: write`. Ordinary branch pushes do not
publish releases. No CurseForge, Wago, or WoWInterface upload is configured.

After reviewing and pushing the repository to GitHub, a maintainer can create
and push an annotated release tag, for example:

```sh
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Ensure repository Actions policy permits the referenced actions and a token
with write access to release contents. No personal access token is required.
The packager substitutes the annotated tag version into the TOC's
`@project-version@`. This release version is independent of LibStub's major
`LibSharedMediaControls-1.0` and implementation minor number; change the latter
only when updating the library implementation.

## License

Original library and demo code and project documentation are distributed under
the [MIT License](LICENSE), copyright (c) 2026 Orionshock. Retain the copyright
and permission notice when embedding the library; it is included in the Lua header.

Bundled dependencies retain their original authorship and license notices in
`libs/`. LibSharedMedia-3.0 is LGPL 2.1; CallbackHandler-1.0 carries the Ace3 BSD
notice; LibStub's source declares it public domain and its existing accompanying
notice is retained. The MIT grant does not relicense those dependencies or
Blizzard's APIs and code. See each dependency's source header and license file.
