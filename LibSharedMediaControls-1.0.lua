local MAJOR, MINOR = "LibSharedMediaControls-1.0", 4
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local media = LibStub("LibSharedMedia-3.0")

-- Settings calls its options provider for tooltips as well as menu generation.
-- Our entries are supplied by customOptionHandler instead of the stock inserter.
local function EmptyOptions()
    return {}
end

--- Create a native Settings dropdown for an existing string-valued setting.
-- The caller owns the category, setting, persistence, and change callbacks.
-- Returns the normal Settings initializer.
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
