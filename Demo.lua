-- Standalone example of all five selectors and their companion settings.
-- Embedding addons should not load this file.
local media = LibStub("LibSharedMedia-3.0")
local LSMC = LibStub("LibSharedMediaControls-1.0")

local function CreateSliderWithInput(category, setting, options, tooltip)
    local initializer = Settings.CreateSlider(category, setting, options, tooltip)

    local initFrame, resetter = initializer.InitFrame, initializer.Resetter
    local step = (options.maxValue - options.minValue) / options.steps

    -- Settings recycles slider rows. Bind the field only while this row owns it.
    initializer.InitFrame = function(owner, frame)
        initFrame(owner, frame)
        local input = frame.LSMCDemoSliderInput
        if not input then
            input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
            input:SetSize(42, 20)
            input:SetPoint("LEFT", frame.SliderWithSteppers, "RIGHT", 8, 0)
            input:SetAutoFocus(false)
            input:SetJustifyH("CENTER")
            frame.LSMCDemoSliderInput = input
        end

        local function Refresh()
            input:SetText(tostring(setting:GetValue()))
        end

        input:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText())
            if value and frame:IsEnabled() then
                value = math.min(options.maxValue, math.max(options.minValue, value))
                local steps = math.floor((value - options.minValue) / step + 0.5)
                setting:SetValue(math.min(options.maxValue, options.minValue + steps * step))
            end
            self:ClearFocus()
        end)
        input:SetScript("OnEscapePressed", input.ClearFocus)
        input:SetScript("OnEditFocusLost", Refresh)
        frame.cbrHandles:SetOnValueChangedCallback(setting:GetVariable(), Refresh)
        Refresh()
        input:Show()
    end

    initializer.Resetter = function(owner, frame)
        local input = frame.LSMCDemoSliderInput
        input:ClearFocus()
        input:Hide()
        input:SetScript("OnEnterPressed", nil)
        input:SetScript("OnEscapePressed", nil)
        input:SetScript("OnEditFocusLost", nil)
        resetter(owner, frame)
    end
end

-- Build on first use so saved variables and native Settings are ready.
local function CreateDemoCategory()
    -- Demo persistence is owned here, not by the library.
    LibSharedMediaControlsDemoDB = LibSharedMediaControlsDemoDB or {statusbar = "Blizzard"}
    local category = Settings.RegisterVerticalLayoutCategory("Shared Media Controls Demo")
    local ApplyBar, ApplyFont, ApplyBackdrop

    -- ========================================================================
    -- LSMC:CreateStatusbarDropdown — Status Bars
    -- Companion: colorSetting
    -- ========================================================================
    -- A texture selector tinted by a companion color setting.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Status Bars"))

    -- Store the registered media name; callbacks belong to the consuming addon.
    local setting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_STATUSBAR", "statusbar",
        LibSharedMediaControlsDemoDB, "string", "Status-bar texture", "Blizzard")

    -- AARRGGBB color companion; the selector applies its normal preview dimming.
    local colorSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_COLOR", "color",
        LibSharedMediaControlsDemoDB, "string", "Preview color", "ff3399ff")
    Settings.CreateColorSwatch(category, colorSetting, "Tint the status bar and its texture previews.")

    -- The constructor adds the selector to the category; do not add it again.
    LSMC:CreateStatusbarDropdown(category, setting,
        "Choose a texture. The stored value is its registered media name.", colorSetting,
        function(name) ApplyBar(name) end, function() ApplyBar() end)

    -- ========================================================================
    -- LSMC:CreateFontDropdown — Fonts
    -- Companions: fontSize, fontColor, fontOutline
    -- ========================================================================
    -- Names render in their own font, with size, color, and outline companions.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Fonts"))

    -- Font media name, independent of its preview properties.
    local fontSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT", "font",
        LibSharedMediaControlsDemoDB, "string", "Font", media:GetDefault("font"))

    -- Numeric size companion; the selected preview caps its rendered size at 18.
    local fontSize = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_SIZE", "fontSize",
        LibSharedMediaControlsDemoDB, "number", "Font size", 14)
    CreateSliderWithInput(category, fontSize, Settings.CreateSliderOptions(8, 32, 1),
        "Set the demo text and menu sample size. The selected sample is capped at 18.")

    -- AARRGGBB text color, retained through hover and selection.
    local fontColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_COLOR", "fontColor",
        LibSharedMediaControlsDemoDB, "string", "Font color", "ffffffff")
    Settings.CreateColorSwatch(category, fontColor, "Color the demo text and font samples.")

    -- Outline companion uses native font flags; an empty string means no outline.
    local fontOutline = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_FONT_OUTLINE", "fontOutline",
        LibSharedMediaControlsDemoDB, "string", "Font outline", "")
    local function GetOutlineOptions()
        local options = Settings.CreateControlTextContainer()
        options:Add("", "None")
        options:Add("OUTLINE", "Outline")
        options:Add("THICKOUTLINE", "Thick outline")
        return options:GetData()
    end
    local outlineDropdown = Settings.CreateDropdown(category, fontOutline, function() return {} end)
    local function IsOutlineSelected(option)
        return fontOutline:GetValue() == option.value
    end
    local function SelectOutline(option)
        fontOutline:SetValue(option.value)
    end
    outlineDropdown.customOptionHandler = function(rootDescription)
        rootDescription:AddMenuReleasedCallback(function()
            ApplyFont()
        end)
        for _, option in ipairs(GetOutlineOptions()) do
            option.onEnter = function()
                ApplyFont(nil, option.value)
            end
            Settings.CreateDropdownButton(rootDescription, option, IsOutlineSelected, SelectOutline)
        end
    end

    -- Pass all three existing Settings objects as optional companions.
    LSMC:CreateFontDropdown(category, fontSetting,
        "Each font name previews its registered font. The stored value is the media name.",
        fontSize, fontColor, fontOutline,
        function(name) ApplyFont(name) end, function() ApplyFont() end)

    -- ========================================================================
    -- LSMC:CreateBackgroundDropdown — Backgrounds
    -- Companion: backgroundColor
    -- ========================================================================
    -- Hover previews fill the menu without selecting an option.
    Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("Backgrounds"))

    -- Independent background tint; white preserves the texture colors.
    local backgroundColor = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BACKGROUND_COLOR", "backgroundColor",
        LibSharedMediaControlsDemoDB, "string", "Preview color", "ffffffff")
    Settings.CreateColorSwatch(category, backgroundColor, "Tint the demo background and its texture previews.")

    -- Selected background media name; hovering does not write this setting.
    local backgroundSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BACKGROUND", "background",
        LibSharedMediaControlsDemoDB, "string", "Background texture", "Blizzard Dialog Background")

    -- Reopening starts the menu preview with the selected background.
    LSMC:CreateBackgroundDropdown(category, backgroundSetting,
        "Choose a background texture. The stored value is its registered media name.", backgroundColor,
        function(name) ApplyBackdrop(name) end, function() ApplyBackdrop() end)

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
    CreateSliderWithInput(category, borderSize, Settings.CreateSliderOptions(1, 32, 1),
        "Set the demo and menu edge size. The selected preview is capped at 8.")

    -- Border media name; None clears the border preview.
    local borderSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_BORDER", "border",
        LibSharedMediaControlsDemoDB, "string", "Border", "Blizzard Dialog")

    -- Color and size update the selected preview live; hover reads current values.
    LSMC:CreateBorderDropdown(category, borderSetting,
        "Hover to preview a border around the menu. Click to select its registered name.", borderColor, borderSize,
        function(name) ApplyBackdrop(nil, name) end, function() ApplyBackdrop() end)

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
    end, "Use this channel for the demo alert and speaker previews. Game audio settings still apply.")

    -- Store only the sound name; selecting it does not play it.
    local soundSetting = Settings.RegisterAddOnSetting(category, "LSMC_DEMO_SOUND", "sound",
        LibSharedMediaControlsDemoDB, "string", "Sound", "None")

    -- Includes menu speakers and a speaker beside the selected value.
    LSMC:CreateSoundDropdown(category, soundSetting,
        "Click a name to select; click its speaker to preview without selecting.", channel)

    -- ========================================================================
    -- Register the completed category
    -- ========================================================================
    Settings.RegisterAddOnCategory(category)

    -- Apply the same settings to ordinary addon widgets at their full size and color.
    local preview = CreateFrame("Frame", nil, SettingsPanel, "BackdropTemplate")
    preview:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 8, 0)
    preview:SetSize(280, 160)

    local background = preview:CreateTexture(nil, "BACKGROUND")

    local bar = CreateFrame("StatusBar", nil, preview)
    bar:SetPoint("TOPLEFT", 32, -32)
    bar:SetPoint("TOPRIGHT", -32, -32)
    bar:SetHeight(24)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(72)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.65)

    local barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    barText:SetPoint("CENTER")
    barText:SetText("Health  72 / 100")

    local sample = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sample:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -12)
    sample:SetWidth(preview:GetWidth() - 64)
    sample:SetJustifyH("LEFT")
    sample:SetText("Your party is ready. Check your supplies before heading into the dungeon.")

    local playAlert = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    playAlert:SetPoint("TOPLEFT", sample, "BOTTOMLEFT", 0, -12)
    playAlert:SetSize(110, 24)
    playAlert:SetText("Play alert")
    playAlert:SetScript("OnClick", function()
        local file = media:Fetch("sound", soundSetting:GetValue())
        if file and file ~= 1 then
            PlaySoundFile(file, channel:GetValue())
        end
    end)

    local function ReadColor(color)
        return CreateColorFromHexString(color:GetValue()):GetRGBA()
    end

    ApplyBar = function(name)
        bar:SetStatusBarTexture(media:Fetch("statusbar", name or setting:GetValue()))
        bar:SetStatusBarColor(ReadColor(colorSetting))
    end

    ApplyFont = function(name, outline)
        sample:SetFont(media:Fetch("font", name or fontSetting:GetValue()),
            fontSize:GetValue(), outline or fontOutline:GetValue())
        sample:SetTextColor(ReadColor(fontColor))
        preview:SetHeight(136 + sample:GetStringHeight())
    end

    ApplyBackdrop = function(backgroundName, borderName)
        background:SetTexture(media:Fetch("background", backgroundName or backgroundSetting:GetValue()))
        background:SetVertexColor(ReadColor(backgroundColor))
        local border = media:Fetch("border", borderName or borderSetting:GetValue())
        local edgeSize = borderSize:GetValue()
        -- Keep the background under the border artwork as the edge size grows.
        local inset = border and edgeSize / 4 or 0
        background:ClearAllPoints()
        background:SetPoint("TOPLEFT", inset, -inset)
        background:SetPoint("BOTTOMRIGHT", -inset, inset)
        preview:SetBackdrop(border and {
            edgeFile = border,
            edgeSize = edgeSize,
        } or nil)
        preview:SetBackdropBorderColor(ReadColor(borderColor))
    end

    local function ApplySound()
        playAlert:SetEnabled(soundSetting:GetValue() ~= "None")
    end

    local function RestoreBar()
        ApplyBar()
    end

    local function RestoreFont()
        ApplyFont()
    end

    local function RestoreBackdrop()
        ApplyBackdrop()
    end

    -- Each callback also handles changes made through Settings defaults.
    for _, barSetting in ipairs({setting, colorSetting}) do
        barSetting:SetValueChangedCallback(RestoreBar)
    end
    for _, textSetting in ipairs({fontSetting, fontSize, fontColor, fontOutline}) do
        textSetting:SetValueChangedCallback(RestoreFont)
    end
    for _, backdropSetting in ipairs({backgroundSetting, backgroundColor, borderSetting, borderColor, borderSize}) do
        backdropSetting:SetValueChangedCallback(RestoreBackdrop)
    end
    soundSetting:SetValueChangedCallback(ApplySound)

    ApplyBar()
    ApplyFont()
    ApplyBackdrop()
    ApplySound()

    local function UpdatePreviewVisibility()
        preview:SetShown(SettingsPanel:GetCurrentCategory() == category)
    end
    SettingsPanel:HookScript("OnShow", UpdatePreviewVisibility)
    EventRegistry:RegisterCallback("Settings.CategoryChanged", UpdatePreviewVisibility, preview)
    UpdatePreviewVisibility()

    return category
end

-- The slash command only initializes the example once and opens its category.
local category
SLASH_LIBSHAREDMEDIACONTROLS1 = "/lsmc"
SlashCmdList.LIBSHAREDMEDIACONTROLS = function()
    category = category or CreateDemoCategory()
    Settings.OpenToCategory(category:GetID())
end
