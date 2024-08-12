local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local default_hub_name = "encode"

local keybinds = {
    toggle_ui = Enum.KeyCode.RightShift,

    fly = Enum.KeyCode.Y,
}

local data = {
    fly = {
    },
    click_tp = {
    },
}

local function new(class, parent, props)
    local i = Instance.new(class, parent)
    for name, data in props do
        i[name] = data
    end
    return i
end

local function create_button()
end

local function init()
    local mouse = Players.LocalPlayer:GetMouse()
    local dragging = false
    local buttons = 0
    local open_page

    local top = new("ScreenGui", nil, {
        ResetOnSpawn = false,
    })

    local background = new("Frame", top, {
        Position = UDim2.new(0, 5, 1, -5),
        Size = UDim2.fromOffset(250, 350),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
    })

    local topbar = new("TextLabel", background, {
        Size = UDim2.new(1, 0, 0, 50),
        Position = Udim2.new(),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Text = default_hub_name,
        Font = Enum.Font.Gotham,
        TextSize = 30,
        RichText = true,
        TextColor3 = Color3.new(1, 1, 1),
    })

    local back = new("TextButton", background, {
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.fromScale(0, 1),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        Text = "back",
        Font = Enum.Font.SourceSansSemibold,
        TextSize = 18,
        RichText = true,
        TextColor3 = Color3.new(1, 1, 1),
    })

    local main = new("Frame", background, {
        Size = UDim2.new(1, 0, 1, -75),
        Position = UDim2.fromOffset(0, 50),
        BackgroundTransparency = 1,
    })

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        background.AnchorPoint = Vector2.new(
            (mouse.X - background.AbsolutePosition.X) / 250,
            (mouse.Y - background.AbsolutePosition.Y) / 350
        )
    end)

    topbar.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = false
    end)

    RunService.RenderStepped:Connect(function(dt)
        if dragging then
            background.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == keybinds.toggle_ui then
            background.Visible = not background.Visible
        end
    end)

    back.Activated:Connect(function()
        if open_page ~= nil then
            open_page.Visible = false
            main.Visible = true
        end
    end)

    local function new_button(title, execute_text, info)
        local settings = {}

        local button = new("TextButton", main, {
            Size = UDim2.new(1, -10, 0, 25),
            Position = Udim2.fromOffset(5, 5 + buttons * 30),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Text = title,
            Font = Enum.Font.SourceSansSemibold,
            TextSize = 18,
            TextColor3 = Color3.new(1, 1, 1),
        })

        new("UICorner", button, { CornerRadius = UDim.new(0, 5) })

        local page = new("Frame", background, {
            Visible = false,
            Size = UDim2.new(1, 0, 1, -50),
            Position = UDim2.fromOffset(0, 50),
            BackgroundTransparency = 1,
        })

        local execute = new("Frame", background, {
            Size = UDim2.new(1, 0, 1, 50),
            Position = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Text = execute_text or "execute",
            RichText = true,
            Font = Enum.Font.SourceSansSemibold,
            TextSize = 18,
            TextColor3 = Color3.new(1, 1, 1),
        })

        new("UICorner", execute, { CornerRadius = UDim2.new(0, 5) })

        execute.Activated:Connect(function()
            info.func(settings)
        end)

        local page_buttons = 1
        for setting, setting_type in info.settings do
            if setting_type == "boolean" then
                local setting_tab = new("TextButton", page, {
                    Size = UDim2.new(1, -10, 0, 25),
                    Position = UDim2.fromOffset(5, 5 + page_buttons * 30),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    Text = setting,
                    Font = Enum.Font.SourceSansSemibold,
                    TextSize = 18,
                    TextColor3 = Color3.new(1, 1, 1),
                })

                local enabled = new("Frame", setting_tab, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(10, 10),
                    BackgroundColor3 = Color3.new(1, 0, 0),
                })

                new("UICorner", enabled, { CornerRadius = UDim.new(0, 10) })

                setting_tab.Activated:Connect(function()
                    settings[setting] = not settings[setting]

                    if settings[setting] then
                        enabled.BackgroundColor3 = Color3.new(0, 1, 0)
                    else
                        enabled.BackgroundColor3 = Color3.new(1, 0, 0)
                    end
                end)
            elseif setting_type == "string" or setting_type == "number" then
                local setting_tab = new("TextBox", page, {
                    Size = UDim2.new(1, -10, 0, 25),
                    Position = UDim2.fromOffset(5, 5 + page_buttons * 30),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    PlaceholderText = string.format("%s: %s", setting, setting_type)
                    Text = "",
                    Font = Enum.Font.SourceSansSemibold,
                    TextSize = 18,
                    TextColor3 = Color3.new(1, 1, 1),
                    PlaceholderColor3 = Color3.fromRGB(200, 200, 200),
                })

                new("UICorner", setting_tab, { CornerRadius = UDim.new(0, 5) })

                setting_tab.FocusLost:Connect(function()
                    local s
                    if setting_tab.Text == "" then
                    elseif setting_type == "number" then
                        s = tonumber(setting_tab.Text)
                    else
                        s = setting_tab.Text
                    end
                    settings[setting] = s
                end)
            end

            page_buttons += 1
        end

        button.Activated:Connect(function()
            main.Visible = false
            page.Visible = true
            open_page = page
        end)

        buttons += 1

        return button
    end

    new_button("settings", "apply", {
        settings = {
            hub_title = "string",
            hide_keybind = "string",
        },
        func = function(settings)
            local s, kb = pcall(function()
                return Enum.KeyCode[settings.hide_keybind]
            end)

            if s then
                keybinds.toggle_ui = kb
            end

            if settings.hub_title ~= "" then
                topbar.Text = settings.hub_title
            end
        end,
    })

    for _,exploit in exploits do
        new_button(exploit.title, nil, exploit)
    end

    top.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

init()

