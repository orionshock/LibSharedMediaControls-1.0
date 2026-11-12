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
        Settings.RegisterAddOnCategory(category)
    end

    if command == "register" then
        media:Register("statusbar", "LSMC Late Registration", [[Interface\Buttons\WHITE8X8]])
        media:Register("font", "LSMC Late Font Registration", media:Fetch("font", media:GetDefault("font")))
        media:Register("background", "LSMC Late Background Registration", [[Interface\Buttons\WHITE8X8]])
        print("Registered late status-bar, font, and background entries; reopen their menus to discover them.")
    elseif command == "set" then
        setting:SetValue("Blizzard")
    end
    Settings.OpenToCategory(category:GetID())
end
