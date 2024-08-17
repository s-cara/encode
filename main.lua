local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local default_hub_name = "encode"
local toggle_ui_keybind = Enum.KeyCode.RightShift

local fly_key_conv = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.S] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.LeftShift] = Vector3.new(0, -1, 0),
    [Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
}

local function new(class, parent, props)
    local i = Instance.new(class, parent)
    for name, data in props do
        i[name] = data
    end
    return i
end

local function get_char()
    return Players.LocalPlayer.Character
end

local function v3_distance(u, v)
    return (u - v).Magnitude
end

local data = {
    {
        title = "click teleport",
        settings = {
            startergear = "boolean",
        },
        exec = function(self)
            local mouse = Players.LocalPlayer:GetMouse()

            local function get_tool()
                local tool = new("Tool", Players.LocalPlayer.Backpack, {
                    RequiresHandle = false,
                    Name = "click tp",
                })
                tool.Activated:Connect(function()
                    local pos = mouse.Hit
                    pos = CFrame.new(pos.X, pos.Y + 2.5, pos.Z)
                    get_char().PrimaryPart.CFrame = pos
                end)
            end

            get_tool()

            if self.data.startergear then
                Players.LocalPlayer.CharacterAdded:Connect(get_tool)
            end
        end,
    },

    {
        title = "humanoid",
        settings = {
            walkspeed = "number",
            jumpheight = "number",
        },
        exec = function(self)
            local humanoid = get_char():FindFirstChildWhichIsA("Humanoid")

            if self.data.walkspeed then
                humanoid.WalkSpeed = self.data.walkspeed
            end

            if self.data.jumpheight then
                humanoid.UseJumpPower = false
                humanoid.JumpHeight = self.data.jumpheight
            end
        end,
    },
    
    {
        title = "tp to player",
        settings = {
            playername = "string",
        },

        exec = function(self)
            get_char().PrimaryPart.CFrame = Players[self.data.playername].Character.PrimaryPart.CFrame
        end,
    },

    {
        title = "cframe fly / noclip",
        settings = {
            speed = "number",
            keybind = "string",
        },

        toggle = function(self)
            get_char().PrimaryPart.Anchored = self.data.enabled
        end,
        
        init = function(self)
            self.data.enabled = false
            self.data.keybind = "L"
            self.data.speed = 50

            RunService:BindToRenderStep("6100339b-ff94-4e2a-b78e-58548737dae3", Enum.RenderPriority.Camera.Value - 1, function(dt)
                if not self.data.enabled then
                    return
                end

                local ld = Vector3.zero
                for k, v in fly_key_conv do
                    if UserInputService:IsKeyDown(k) then
                        ld += v
                    end
                end

                local camcf = workspace.CurrentCamera.CFrame
                local pp = get_char().PrimaryPart
                pp.CFrame = camcf.Rotation + pp.Position

                if ld.Magnitude > 0 then
                    local direction = (camcf.RightVector * ld.X + camcf.UpVector * ld.Y + camcf.LookVector * ld.Z).Unit
                    pp.CFrame += direction * dt * (self.data.speed or 1)
                end
            end)
        end,
    },

    {
        title = "freecam",
        settings = {
            speed = "number",
            keybind = "string",
        },

        toggle = function(self)
            self.data.cframe = workspace.CurrentCamera.CFrame
            get_char().PrimaryPart.Anchored = self.data.enabled
        end,

        init = function(self)
            self.data.enabled = false
            self.data.keybind = "P"
            self.data.speed = 50
            self.data.cframe = CFrame.new()

            RunService:BindToRenderStep("ab61fbe5-f92b-e9ff-b6ca-c76abb23d7af", Enum.RenderPriority.Last.Value, function(dt)
                if not self.data.enabled then
                    return
                end

                local ld = Vector3.zero
                for k, v in fly_key_conv do
                    if UserInputService:IsKeyDown(k) then
                        ld += v
                    end
                end

                local camcf = self.data.cframe
                if ld.Magnitude > 0 then
                    local direction = (camcf.RightVector * ld.X + camcf.UpVector * ld.Y + camcf.LookVector * ld.Z).Unit
                    self.data.cframe += direction * dt * (self.data.speed or 1)
                end

                local mouse_delta = UserInputService:GetMouseDelta() * 0.01
                local rx, ry, _ = self.data.cframe:ToOrientation()

                rx -= mouse_delta.Y
                ry -= mouse_delta.X

                self.data.cframe = CFrame.fromOrientation(rx, ry, 0) + self.data.cframe.Position

                workspace.CurrentCamera.CFrame = self.data.cframe
            end)
        end,
    },

    {
        title = "fullbright",
        settings = {
        },

        exec = function(self)
            RunService:BindToRenderStep("f11b77da-e45b-4ca1-aeb0-33a8bdabc5c4", Enum.RenderPriority.Last.Value, function()
                Lighting.Brightness = 1
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                Lighting.GlobalShadows = false
            end)
        end,
    },

    {
        title = "aimlock",
        settings = {
            ignore_team = "boolean",
            keybind = "string",
            focus_player = "string",
        },

        init = function(self)
            self.data.ignore_team = false
            self.data.keybind = "RightBracket"
            
            RunService:BindToRenderStep("c71d9b2f-f889-43e8-a8cd-a8a040c39d69", Enum.RenderPriority.Last.Value, function()
                if not self.data.enabled then
                    return
                end

                local target
                if self.data.focus_player ~= nil then
                    target = Players:FindFirstChild(self.data.focus_player)
                    if target ~= nil then
                        target = target.Character
                    end
                end

                if target == nil then
                    local min_distance = math.huge
                    for _, player in Players:GetPlayers() do
                        if self.data.ignore_team and player.Team == Players.LocalPlayer.Team then
                            continue
                        elseif player == Players.LocalPlayer then
                            continue
                        end

                        local d = v3_distance(player.Character.PrimaryPart.Position, get_char().PrimaryPart.Position)
                        if d < min_distance then
                            min_distance = d
                            target = player.Character
                        end
                    end
                end

                if target == nil then
                    return
                end

                local cam = workspace.CurrentCamera
                cam.CFrame = CFrame.new(cam.CFrame.Position, target.PrimaryPart.Position)
            end)
        end,
    },
}

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
        Position = UDim2.new(),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Text = default_hub_name,
        Font = Enum.Font.Fondamento,
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
        if input.KeyCode == toggle_ui_keybind then
            background.Visible = not background.Visible
        end
    end)

    back.Activated:Connect(function()
        if open_page ~= nil then
            open_page.Visible = false
            main.Visible = true
        end
    end)

    local exploits_with_keybinds = {}
    local function new_button(info)
        local button = new("TextButton", main, {
            Size = UDim2.new(1, -10, 0, 25),
            Position = UDim2.fromOffset(5, 5 + buttons * 30),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Text = info.title,
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

        local page_buttons = 1

        if info.exec ~= nil then
            local execute = new("TextButton", page, {
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.fromOffset(5, 5),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                Text = info.execute_text or "execute",
                RichText = true,
                Font = Enum.Font.SourceSansSemibold,
                TextSize = 18,
                TextColor3 = Color3.new(1, 1, 1),
            })

            new("UICorner", execute, { CornerRadius = UDim.new(0, 5) })

            execute.Activated:Connect(function()
                info:exec()
            end)
        else
            page_buttons -= 1
        end

        info.data = {}
        if info.init ~= nil then
            info:init()
        end

        for setting, setting_type in info.settings do
            if setting_type == "boolean" then
                if info.data[setting] == nil then
                    info.data[setting] = false
                end

                local setting_tab = new("TextButton", page, {
                    Size = UDim2.new(1, -10, 0, 25),
                    Position = UDim2.fromOffset(5, 5 + page_buttons * 30),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    Text = setting,
                    Font = Enum.Font.SourceSansSemibold,
                    TextSize = 18,
                    TextColor3 = Color3.new(1, 1, 1),
                })
                
                new("UICorner", setting_tab, { CornerRadius = UDim.new(0, 5) })

                local enabled = new("Frame", setting_tab, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(10, 10),
                    BackgroundColor3 = Color3.new(1, 0, 0),
                })

                new("UICorner", enabled, { CornerRadius = UDim.new(0, 10) })

                setting_tab.Activated:Connect(function()
                    info.data[setting] = not info.data[setting]

                    if info.data[setting] then
                        enabled.BackgroundColor3 = Color3.new(0, 1, 0)
                    else
                        enabled.BackgroundColor3 = Color3.new(1, 0, 0)
                    end
                end)
            elseif setting_type == "string" or setting_type == "number" then
                if info.data[setting] == nil then
                    info.data[setting] = setting_type == "string" and "" or 0
                end

                local setting_tab = new("TextBox", page, {
                    Size = UDim2.new(1, -10, 0, 25),
                    Position = UDim2.fromOffset(5, 5 + page_buttons * 30),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    PlaceholderText = string.format("%s (%s)", setting, setting_type),
                    Text = "",
                    Font = Enum.Font.SourceSansSemibold,
                    TextSize = 18,
                    TextColor3 = Color3.new(1, 1, 1),
                    PlaceholderColor3 = Color3.fromRGB(200, 200, 200),
                    ClearTextOnFocus = false,
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
                    info.data[setting] = s
                end)

                if setting == "keybind" then
                    table.insert(exploits_with_keybinds, info)
                end
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

    new_button {
        title = "settings",
        execute_text  = "apply",
        settings = {
            hub_title = "string",
            hide_keybind = "string",
        },
        exec = function(self)
            local s, kb = pcall(function()
                return Enum.KeyCode[self.data.hide_keybind]
            end)

            if s then
                toggle_ui_keybind = kb
            end

            if self.data.hub_title ~= "" then
                topbar.Text = self.data.hub_title
            end
        end,
    }

    for _, exploit in data do
        new_button(exploit)
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        for _, info in exploits_with_keybinds do
            local s, keybind = pcall(function() return Enum.KeyCode[info.data.keybind] end)
            if not s then
                return
            end

            if input.KeyCode == keybind then
                info.data.enabled = not info.data.enabled
                if info.toggle ~= nil then
                    info:toggle()
                end
            end
        end
    end)

    top.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

init()
return nil
