-- Standalone example of all five selectors and their companion settings.
-- Embedding addons should not load this file.
local media = LibStub("LibSharedMedia-3.0")
local LSMC = LibStub("LibSharedMediaControls-1.0")

-- Build on first use so saved variables and native Settings are ready.
local function CreateDemoCategory()
    -- Demo persistence is owned here, not by the library.
    LibSharedMediaControlsDemoDB = LibSharedMediaControlsDemoDB or {statusbar = "Blizzard"}
    local category = Settings.RegisterVerticalLayoutCategory("Shared Media Controls Demo")

    -- ========================================================================
    -- LSMC:CreateStatusbarDropdown — Status Bars
    -- Companion: colorSetting
    -- ========================================================================
    -- A texture selector tinted by a companion color setting.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Status Bars"))

    -- Store the registered media name; callbacks belong to the consuming addon.
    local setting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_STATUSBAR", "statusbar",
        LibSharedMediaControlsDemoDB, "string", "Status-bar texture", "Blizzard")
    setting:SetValueChangedCallback(function(_, name)
        print("Shared Media Controls selected:", name)
    end)

    -- AARRGGBB color companion; the selector applies its normal preview dimming.
    local colorSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_COLOR", "color",
        LibSharedMediaControlsDemoDB, "string", "Preview color", "ff3399ff")
    Settings.CreateColorSwatch(category, colorSetting, "Tint the texture previews with this color.")

    -- The constructor adds the selector to the category; do not add it again.
    LSMC:CreateStatusbarDropdown(category, setting,
        "Choose a texture. The stored value is its registered media name.", colorSetting)

    -- ========================================================================
    -- LSMC:CreateFontDropdown — Fonts
    -- Companions: fontSize, fontColor, fontOutline
    -- ========================================================================
    -- Names render in their own font, with size, color, and outline companions.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Fonts"))

    -- Font media name, independent of its preview properties.
    local fontSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT", "font",
        LibSharedMediaControlsDemoDB, "string", "Font", media:GetDefault("font"))
    fontSetting:SetValueChangedCallback(function(_, name)
        print("Shared Media Controls font:", name)
    end)

    -- Numeric size companion; the selected preview caps its rendered size at 18.
    local fontSize = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_SIZE", "fontSize",
        LibSharedMediaControlsDemoDB, "number", "Font preview size", 14)
    Settings.CreateSlider(category, fontSize, Settings.CreateSliderOptions(8, 32, 1),
        "Menu samples use this size; the selected sample is capped at 18 to fit the control.")

    -- AARRGGBB text color, retained through hover and selection.
    local fontColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_COLOR", "fontColor",
        LibSharedMediaControlsDemoDB, "string", "Font preview color", "ffffffff")
    Settings.CreateColorSwatch(category, fontColor, "Color for the font samples.")

    -- Outline companion uses native font flags; an empty string means no outline.
    local fontOutline = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_OUTLINE", "fontOutline",
        LibSharedMediaControlsDemoDB, "string", "Font preview outline", "")
    Settings.CreateDropdown(category, fontOutline, function()
        local options = Settings.CreateControlTextContainer()
        options:Add("", "None")
        options:Add("OUTLINE", "Outline")
        options:Add("THICKOUTLINE", "Thick outline")
        return options:GetData()
    end)

    -- Pass all three existing Settings objects as optional companions.
    LSMC:CreateFontDropdown(category, fontSetting,
        "Each font name previews its registered font. The stored value is the media name.",
        fontSize, fontColor, fontOutline)

    -- ========================================================================
    -- LSMC:CreateBackgroundDropdown — Backgrounds
    -- Companion: backgroundColor
    -- ========================================================================
    -- Hover previews fill the menu without selecting an option.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Backgrounds"))

    -- Independent background tint; white preserves the texture colors.
    local backgroundColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BACKGROUND_COLOR", "backgroundColor",
        LibSharedMediaControlsDemoDB, "string", "Preview color", "ffffffff")
    Settings.CreateColorSwatch(category, backgroundColor, "Tint background previews independently of status bars.")

    -- Selected background media name; hovering does not write this setting.
    local backgroundSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BACKGROUND", "background",
        LibSharedMediaControlsDemoDB, "string", "Background texture", "Blizzard Dialog Background")
    backgroundSetting:SetValueChangedCallback(function(_, name)
        print("Shared Media Controls background:", name)
    end)

    -- Reopening starts the menu preview with the selected background.
    LSMC:CreateBackgroundDropdown(category, backgroundSetting,
        "Choose a background texture. The stored value is its registered media name.", backgroundColor)

    -- ========================================================================
    -- LSMC:CreateBorderDropdown — Borders
    -- Companions: borderColor, borderSize
    -- ========================================================================
    -- Actual backdrop edges and corners, previewed around the menu.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Borders"))

    -- AARRGGBB edge tint; the underlying registered texture stays unchanged.
    local borderColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER_COLOR", "borderColor",
        LibSharedMediaControlsDemoDB, "string", "Border color", "ffffffff")
    Settings.CreateColorSwatch(category, borderColor, "Tint the border artwork.")

    -- Numeric edge size, separate from the preview frame dimensions.
    local borderSize = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER_SIZE", "borderSize",
        LibSharedMediaControlsDemoDB, "number", "Border edge size", 12)
    Settings.CreateSlider(category, borderSize, Settings.CreateSliderOptions(1, 32, 1),
        "Menu edge size; the selected control preview is capped at 8 to fit its height.")

    -- Border media name; None clears the border preview.
    local borderSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER", "border",
        LibSharedMediaControlsDemoDB, "string", "Border", "Blizzard Dialog")
    borderSetting:SetValueChangedCallback(function(_, name)
        print("Shared Media Controls border:", name)
    end)

    -- Color and size update the selected preview live; hover reads current values.
    LSMC:CreateBorderDropdown(category, borderSetting,
        "Hover to preview a border around the menu. Click to select its registered name.", borderColor, borderSize)

    -- ========================================================================
    -- LSMC:CreateSoundDropdown — Sounds
    -- Companion: channel
    -- ========================================================================
    -- Speaker clicks preview audio independently of radio selection.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Sounds"))
    -- Built-in file IDs also used by installed Forever addons; no bundled audio.
    media:Register("sound", "LSMC Demo Alert", 567478)
    media:Register("sound", "LSMC Demo Ding", 567458)

    -- Channel companion is read when a speaker is clicked, not when selected.
    local channel = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_SOUND_CHANNEL", "soundChannel",
        LibSharedMediaControlsDemoDB, "string", "Playback channel", "SFX")
    Settings.CreateDropdown(category, channel, function()
        local options = Settings.CreateControlTextContainer()
        for _, name in ipairs({"Master", "SFX", "Music", "Ambience", "Dialog"}) do
            options:Add(name, name)
        end
        return options:GetData()
    end, "Use this channel for speaker-button previews. Game audio settings still apply.")

    -- Store only the sound name; selecting it does not play it.
    local soundSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_SOUND", "sound",
        LibSharedMediaControlsDemoDB, "string", "Sound", "None")
    soundSetting:SetValueChangedCallback(function(_, name)
        print("Shared Media Controls sound:", name)
    end)

    -- Includes menu speakers and a speaker beside the selected value.
    LSMC:CreateSoundDropdown(category, soundSetting,
        "Click a name to select; click its speaker to preview without selecting.", channel)

    -- ========================================================================
    -- Register the completed category
    -- ========================================================================
    Settings.RegisterAddOnCategory(category)

    return category
end

-- The slash command only initializes the example once and opens its category.
local category
SLASH_LIBSHAREDMEDIACONTROLS1 = "/lsmc"
SlashCmdList.LIBSHAREDMEDIACONTROLS = function()
    category = category or CreateDemoCategory()
    Settings.OpenToCategory(category:GetID())
end
