-- Native Settings media selectors for WoW Forever. Full API and examples: README.md.
-- Load after LibStub, LibSharedMedia-3.0, and Blizzard Settings. Construct once
-- per selector in a vertical-layout category; returns an initializer already added
-- to its layout. The addon owns Settings objects, persistence, and applying values.
-- Primary settings store LSM names. Use SetValue() for notifications. Companions
-- update selected previews live; reopen menus to refresh all rows. The library owns
-- the initializer lifecycle and option/selection handlers; do not replace them.
local MAJOR, MINOR = "LibSharedMediaControls-1.0", 8
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local media = LibStub("LibSharedMedia-3.0")

local function NewPreviewFont()
    lib.fontSerial = (lib.fontSerial or 0) + 1
    return CreateFont("LibSharedMediaControlsPreviewFont" .. lib.fontSerial)
end

-- Settings calls its options provider for tooltips as well as menu generation.
-- Our entries are supplied by customOptionHandler instead of the stock inserter.
local function EmptyOptions()
    return {}
end

--- Font names themselves preview the chosen font.
-- CreateFontDropdown(category, setting, tooltip[, sizeSetting, colorSetting, outlineSetting])
-- setting: string Settings object holding an LSM "font" name; tooltip: string or nil.
-- Optional Settings companions: number size (default 14), AARRGGBB string color
-- (default white), string outline ("", "OUTLINE", "THICKOUTLINE"; default "").
-- Preview-only size limits: menu 8-32, selected 8-18. Fonts are assumed usable.
-- Returns the native initializer. Selecting a font writes only the primary setting.
function lib:CreateFontDropdown(category, setting, tooltip, sizeSetting, colorSetting, outlineSetting)
    assert(setting:GetVariableType() == "string", "Font settings must store a media name")
    if sizeSetting then assert(sizeSetting:GetVariableType() == "number", "Font size must be numeric") end
    if colorSetting then assert(colorSetting:GetVariableType() == "string", "Font color must be AARRGGBB") end
    if outlineSetting then assert(outlineSetting:GetVariableType() == "string", "Font outline must be a string") end

    local menuFonts = {}
    local selectedFont = NewPreviewFont()
    local function PreviewName(name)
        if colorSetting then
            -- Inline color survives native hover/selection SetTextColor calls.
            return CreateColorFromHexString(colorSetting:GetValue()):WrapTextInColorCode(name)
        end
        return name
    end
    local function UpdateSample(sample, name, maxSize, fontObject)
        local size = sizeSetting and sizeSetting:GetValue() or 14
        size = math.max(8, math.min(maxSize, size))
        local outline = outlineSetting and outlineSetting:GetValue() or ""
        if outline ~= "OUTLINE" and outline ~= "THICKOUTLINE" then outline = "" end
        -- Compositor FontStrings prohibit SetFont; SetFontObject is supported.
        fontObject:SetFont(media:Fetch("font", name), size, outline)
        sample:SetFontObject(fontObject)
        sample:SetText(PreviewName(name))
        sample:SetTextColor(1, 1, 1, 1)
    end

    local initializer = Settings.CreateDropdown(category, setting, EmptyOptions, tooltip)
    initializer.data.forceSteppersHidden = true
    local activeSample, savedFont, savedColor
    local function RefreshSample()
        if activeSample then UpdateSample(activeSample, setting:GetValue(), 18, selectedFont) end
    end

    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        RefreshSample()
        for _, name in ipairs(media:List("font")) do
            -- Reuse font objects on reopening; refetch their paths in UpdateSample.
            menuFonts[name] = menuFonts[name] or NewPreviewFont()
            local entry = Settings.CreateDropdownButton(rootDescription,
                {value = name, label = name, text = name},
                function(data) return setting:GetValue() == data.value end,
                function(data) setting:SetValue(data.value) end)
            entry:AddInitializer(function(button)
                local text = button.Text
                UpdateSample(text, name, 32, menuFonts[name])
                local width = math.min(400, text:GetUnboundedStringWidth())
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(width)
                return math.max(220, width + 28), 40
            end)
        end
    end

    local initFrame, resetter = initializer.InitFrame, initializer.Resetter
    initializer.InitFrame = function(owner, frame)
        local dropdown = frame.Control.Dropdown
        activeSample = dropdown.Text
        savedFont = activeSample:GetFontObject()
        savedColor = {activeSample:GetTextColor()}
        RefreshSample()
        initFrame(owner, frame)
        for _, companion in pairs({sizeSetting, colorSetting, outlineSetting}) do
            frame.cbrHandles:SetOnValueChangedCallback(companion:GetVariable(), RefreshSample)
        end
    end
    initializer.Resetter = function(owner, frame)
        local text = frame.Control.Dropdown.Text
        text:SetFontObject(savedFont)
        text:SetTextColor(unpack(savedColor))
        activeSample, savedFont, savedColor = nil, nil, nil
        resetter(owner, frame)
    end
    initializer.getSelectionTextFunc = function()
        RefreshSample()
        return PreviewName(setting:GetValue())
    end
    return initializer
end

--- CreateStatusbarDropdown(category, setting, tooltip[, colorSetting])
-- setting: string Settings object holding an LSM "statusbar" name; tooltip: string or nil.
-- colorSetting: optional native AARRGGBB string setting. Preview RGB brightness
-- is multiplied by 0.45 for readability; alpha is unchanged. Default: gray artwork.
-- Returns the native initializer; selection calls setting:SetValue(name).
function lib:CreateStatusbarDropdown(category, setting, tooltip, colorSetting)
    assert(setting:GetVariableType() == "string", "Status-bar settings must store a media name")
    if colorSetting then
        assert(colorSetting:GetVariableType() == "string", "Color settings must store an AARRGGBB string")
    end

    local function TintPreview(preview)
        local r, g, b, a = 1, 1, 1, 1
        if colorSetting then
            r, g, b, a = CreateColorFromHexString(colorSetting:GetValue()):GetRGBA()
        end
        -- Keep the existing dimming behind labels, including for untinted rows.
        preview:SetVertexColor(r * 0.45, g * 0.45, b * 0.45, a)
    end

    local initializer = Settings.CreateDropdown(category, setting, EmptyOptions, tooltip)
    initializer.data.forceSteppersHidden = true

    local function IsSelected(name)
        return setting:GetValue() == name
    end

    local function SetSelected(name)
        setting:SetValue(name)
    end

    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        -- List is LSM's maintained, sorted list; never retain or mutate it.
        for _, name in ipairs(media:List("statusbar")) do
            local option = {value = name, label = name, text = name}
            local entry = Settings.CreateDropdownButton(rootDescription, option,
                function(data) return IsSelected(data.value) end,
                function(data) SetSelected(data.value) end)

            entry:AddInitializer(function(button)
                -- Compositor attachments are reset and released by Blizzard.
                -- Fetch here so reused rows always receive the current texture.
                local preview = button:AttachTexture()
                preview:SetDrawLayer("BACKGROUND", -1)
                preview:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -2)
                preview:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 2)
                preview:SetTexture(media:Fetch("statusbar", name))
                TintPreview(preview)

                local text = button.Text
                local textWidth = text:GetUnboundedStringWidth()
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(textWidth)
                text:SetShadowColor(0, 0, 0, 1)
                text:SetShadowOffset(1, -1)
                return math.max(220, textWidth + 28), 24
            end)
        end
    end

    local activePreview
    local initFrame = initializer.InitFrame
    local resetter = initializer.Resetter

    -- Use the initializer lifecycle so artwork is hidden before a pooled
    -- Settings row is handed to another setting, including a stock dropdown.
    initializer.InitFrame = function(owner, frame)
        local dropdown = frame.Control.Dropdown
        if not dropdown.LSMCStatusbarPreview then
            local preview = dropdown:CreateTexture(nil, "ARTWORK")
            preview:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 4, -4)
            preview:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -4, 4)
            dropdown.LSMCStatusbarPreview = preview
        end
        activePreview = dropdown.LSMCStatusbarPreview
        activePreview:SetTexture(media:Fetch("statusbar", setting:GetValue(), true))
        TintPreview(activePreview)
        activePreview:Show()
        initFrame(owner, frame)
        if colorSetting then
            -- The native control unregisters these handles on Release().
            frame.cbrHandles:SetOnValueChangedCallback(colorSetting:GetVariable(), function()
                if activePreview then
                    TintPreview(activePreview)
                end
            end)
        end
    end

    initializer.Resetter = function(owner, frame)
        frame.Control.Dropdown.LSMCStatusbarPreview:Hide()
        activePreview = nil
        resetter(owner, frame)
    end

    initializer.getSelectionTextFunc = function()
        local name = setting:GetValue()
        if activePreview then
            activePreview:SetTexture(media:Fetch("statusbar", name, true))
            TintPreview(activePreview)
        end
        -- Preserve missing names rather than silently changing the setting.
        return name
    end

    return initializer
end
