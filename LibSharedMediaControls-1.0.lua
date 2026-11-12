local MAJOR, MINOR = "LibSharedMediaControls-1.0", 1
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
function lib:CreateStatusbarDropdown(category, setting, tooltip)
    assert(setting:GetVariableType() == "string", "Status-bar settings must store a media name")

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
                preview:SetSize(100, 16)
                preview:SetPoint("RIGHT", button, "RIGHT", -8, 0)
                preview:SetTexture(media:Fetch("statusbar", name))
                preview:SetVertexColor(1, 1, 1, 1)

                local text = button.Text
                local textWidth = text:GetUnboundedStringWidth()
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(textWidth)
                return textWidth + 14 + 12 + 100 + 8, 24
            end)
        end
    end

    initializer.getSelectionTextFunc = function()
        local name = setting:GetValue()
        local texture = media:Fetch("statusbar", name, true)
        if texture then
            return CreateSimpleTextureMarkup(texture, 60, 12) .. " " .. name
        end
        -- Preserve missing names rather than silently changing the setting.
        return name
    end

    return initializer
end
