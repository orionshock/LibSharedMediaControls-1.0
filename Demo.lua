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
        Settings.RegisterAddOnCategory(category)
    end

    if command == "register" then
        media:Register("statusbar", "LSMC Late Registration", [[Interface\Buttons\WHITE8X8]])
        print("Registered LSMC Late Registration; reopen the dropdown to discover it.")
    elseif command == "set" then
        setting:SetValue("Blizzard")
    end
    Settings.OpenToCategory(category:GetID())
end
