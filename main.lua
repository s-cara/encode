local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local default_hub_name = "encode"
local flying = false

local keybinds = {
    toggle_ui = Enum.KeyCode.RightShift,

    fly = Enum.KeyCode.Y,
}

local function new(class, parent, props)
    local i = Instance.new(class, parent)
    for name, data in props do
        i[name] = data
    end
    return i
end

local data = {
    {
        title = "click teleport",
        settings = {
            startergear = "boolean",
        },
        func = function(settings)
            mouse = player:GetMouse()

            local function get_tool()
                local tool = new("Tool", Players.LocalPlayer.Backpack, {
                    RequiresHandle = false,
                    Name = "click tp",
                })
                tool.Activated:Connect(function()
                    local pos = mouse.Hit
                    pos = CFrame.new(pos.X, pos.Y + 2.5, pos.Z)
                    Players.LocalPlayer.Character.HumanoidRootPart.CFrame = pos
                end)
            end

            get_tool()

            if settings.starter_gear then
                player.CharacterAdded:Connect(get_tool)
            end
        end,
    },

    {
        title = "humanoid",
        settings = {
            walkspeed = "number",
            jumpheight = "number",
        },
        func = function(settings)
            local humanoid = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")

            if settings.walkspeed then
                humanoid.WalkSpeed = settings.walkspeed
            end

            if settings.jumpheight then
                humanoid.UseJumpPower = false
                humanoid.JumpHeight = settings.jumpheight
            end
        end,
    },
    
    {
        title = "tp to player",
        settings = {
            playername = "string",
        },

        func = function(settings)
            Players.LocalPlayer.Character.PrimaryPart.CFrame = Players[settings.playername].Character.PrimaryPart.CFrame
        end,
    },

    {
        title = "bodyvelocity fly",
        settings = {
            speed = "number",
            keybind = "string",
        },
        
        func = function(settings)
            if flying then
                return
            end
            flying = true
            
            local speed = settings.speed
            local s, keybind = pcall(function() return Enum.KeyCode[settings.keybind] end)
            keybind = s and keybind or Enum.KeyCode.E

            local conv = {
                A = { "RightVector", -1, "A" },
                D = { "RightVector", 1, "D" },
                S = { "LookVector", -1, "S" },
                W = { "LookVector", 1, "W" },
            }

            local held_keys = {}
            local key_inverse = {
                W = "S",
                A = "D",
                S = "W",
                D = "A",
            }

            local function add_key(key)
                local inv_pos = table.find(held_keys, key_inverse[key])
                if inv_pos then
                    table.remove(held_keys, inv_pos)
                else
                    table.insert(held_keys, key)
                end
            end

            local function remove_key(key)
                if table.find(held_keys, key) then
                    table.remove(held_keys, table.find(held_keys, key))
                end
            end

            local body_vel = new("BodyVelocity", Players.LocalPlayer.Character.PrimaryPart, {
                Velocity = Vector3.zero,
                MaxForce = Vector3.one * 9e9,
            })
            local velocity = Vector3.zero

            UserInputService.InputBegan:Connect(function(input, processed)
                if processed then
                    return
                end

                if input.KeyCode == keybind then
                    flying = not flying

                    if flying then
                        body_vel = new("BodyVelocity", Players.LocalPlayer.Character.PrimaryPart, {
                            Velocity = Vector3.zero,
                            MaxForce = Vector3.one * 9e9,
                        })
                    else
                        body_vel:Destroy()
                        body_vel = nil
                    end
                end

                if body_vel and flying and conv[input.KeyCode.Name] then
                    add_key(input.KeyCode.Name)
                end
            end)

            UserInputService.InputEnded:Connect(function(input, processed)
                if processed then
                    return
                end

                remove_key(input.KeyCode.Name)
            end)

            RunService.RenderStepped:Connect(function()
                if not flying or not body_vel then
                    return
                end

                local dir_t = { Vector3.zero }
                for idx, key in held_keys do
                    fir_t[idx] = workspace.CurrentCamera.CFrame[conv[key][1]] * conv[key][2]
                end

                local v
                if #held_keys == 0 then
                    v = Vector3.zero
                elseif #held_keys == 1 then
                    v = dir_t[1]
                else
                    v = dir_t[1]:Lerp(dir_t[2], 0.5)
                end

                body_vel.Velocity = v * speed
            end)
        end,
    },
}

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

    for _, exploit in data do
        new_button(exploit.title, nil, exploit)
    end

    top.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

init()

