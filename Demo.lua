-- Standalone, opt-in client exercise. Embedding addons should not load this file.
local category, setting
local media = LibStub("LibSharedMedia-3.0")

SLASH_LIBSHAREDMEDIACONTROLS1 = "/lsmc"
SlashCmdList.LIBSHAREDMEDIACONTROLS = function(command)
    if not category then
        LibSharedMediaControlsDemoDB = LibSharedMediaControlsDemoDB or {statusbar = "Blizzard"}
        category = Settings.RegisterVerticalLayoutCategory("Shared Media Controls Demo")
        Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Status Bars"))
        setting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_STATUSBAR", "statusbar",
            LibSharedMediaControlsDemoDB, "string", "Status-bar texture", "Blizzard")
        setting:SetValueChangedCallback(function(_, name)
            print("Shared Media Controls selected:", name)
        end)
        local colorSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_COLOR", "color",
            LibSharedMediaControlsDemoDB, "string", "Preview color", "ff3399ff")
        Settings.CreateColorSwatch(category, colorSetting, "Tint the texture previews with this color.")
        LibStub("LibSharedMediaControls-1.0"):CreateStatusbarDropdown(category, setting,
            "Choose a texture. The stored value is its registered media name.", colorSetting)

        Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Fonts"))
        local fontSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT", "font",
            LibSharedMediaControlsDemoDB, "string", "Font", media:GetDefault("font"))
        fontSetting:SetValueChangedCallback(function(_, name)
            print("Shared Media Controls font:", name)
        end)
        local fontSize = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_SIZE", "fontSize",
            LibSharedMediaControlsDemoDB, "number", "Font preview size", 14)
        Settings.CreateSlider(category, fontSize, Settings.CreateSliderOptions(8, 32, 1),
            "Menu samples use this size; the selected sample is capped at 18 to fit the control.")
        local fontColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_COLOR", "fontColor",
            LibSharedMediaControlsDemoDB, "string", "Font preview color", "ffffffff")
        Settings.CreateColorSwatch(category, fontColor, "Color for the font samples.")
        local fontOutline = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_OUTLINE", "fontOutline",
            LibSharedMediaControlsDemoDB, "string", "Font preview outline", "")
        Settings.CreateDropdown(category, fontOutline, function()
            local options = Settings.CreateControlTextContainer()
            options:Add("", "None")
            options:Add("OUTLINE", "Outline")
            options:Add("THICKOUTLINE", "Thick outline")
            return options:GetData()
        end)
        LibStub("LibSharedMediaControls-1.0"):CreateFontDropdown(category, fontSetting,
            "Each font name previews its registered font. The stored value is the media name.",
            fontSize, fontColor, fontOutline)

        Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Backgrounds"))
        local backgroundColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BACKGROUND_COLOR", "backgroundColor",
            LibSharedMediaControlsDemoDB, "string", "Preview color", "ffffffff")
        Settings.CreateColorSwatch(category, backgroundColor, "Tint background previews independently of status bars.")
        local backgroundSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BACKGROUND", "background",
            LibSharedMediaControlsDemoDB, "string", "Background texture", "Blizzard Dialog Background")
        backgroundSetting:SetValueChangedCallback(function(_, name)
            print("Shared Media Controls background:", name)
        end)
        LibStub("LibSharedMediaControls-1.0"):CreateBackgroundDropdown(category, backgroundSetting,
            "Choose a background texture. The stored value is its registered media name.", backgroundColor)

        Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Borders"))
        local borderColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER_COLOR", "borderColor",
            LibSharedMediaControlsDemoDB, "string", "Border color", "ffffffff")
        Settings.CreateColorSwatch(category, borderColor, "Tint the border artwork.")
        local borderSize = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER_SIZE", "borderSize",
            LibSharedMediaControlsDemoDB, "number", "Border edge size", 8)
        Settings.CreateSlider(category, borderSize, Settings.CreateSliderOptions(1, 32, 1),
            "Menu edge size; the selected control preview is capped at 8 to fit its height.")
        local borderSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER", "border",
            LibSharedMediaControlsDemoDB, "string", "Border", "Blizzard Dialog")
        borderSetting:SetValueChangedCallback(function(_, name)
            print("Shared Media Controls border:", name)
        end)
        LibStub("LibSharedMediaControls-1.0"):CreateBorderDropdown(category, borderSetting,
            "Hover to preview a border around the menu. Click to select its registered name.", borderColor, borderSize)

        Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Sounds"))
        -- Built-in file IDs also used by installed Forever addons; no bundled audio.
        media:Register("sound", "LSMC Demo Alert", 567478)
        media:Register("sound", "LSMC Demo Ding", 567458)
        local channel = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_SOUND_CHANNEL", "soundChannel",
            LibSharedMediaControlsDemoDB, "string", "Playback channel", "SFX")
        Settings.CreateDropdown(category, channel, function()
            local options = Settings.CreateControlTextContainer()
            for _, name in ipairs({"Master", "SFX", "Music", "Ambience", "Dialog"}) do
                options:Add(name, name)
            end
            return options:GetData()
        end, "Use this channel for speaker-button previews. Game audio settings still apply.")
        local soundSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_SOUND", "sound",
            LibSharedMediaControlsDemoDB, "string", "Sound", "None")
        soundSetting:SetValueChangedCallback(function(_, name)
            print("Shared Media Controls sound:", name)
        end)
        LibStub("LibSharedMediaControls-1.0"):CreateSoundDropdown(category, soundSetting,
            "Click a name to select; click its speaker to preview without selecting.", channel)
        Settings.RegisterAddOnCategory(category)
    end

    if command == "register" then
        media:Register("statusbar", "LSMC Late Registration", [[Interface\Buttons\WHITE8X8]])
        media:Register("font", "LSMC Late Font Registration", media:Fetch("font", media:GetDefault("font")))
        media:Register("background", "LSMC Late Background Registration", [[Interface\Buttons\WHITE8X8]])
        media:Register("border", "LSMC Late Border Registration", media:Fetch("border", "Blizzard Dialog"))
        media:Register("sound", "LSMC Late Sound Registration", 567478)
        print("Registered late media entries; reopen their menus to discover them.")
    elseif command == "set" then
        setting:SetValue("Blizzard")
    end
    Settings.OpenToCategory(category:GetID())
end
