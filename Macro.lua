-- UI State
local emoteGui, crouchGui
local macroLoaded = false

-- Settings
local textTransparency = 0.6
local iconTransparency = 0.6
local BtnSize = 80

_G.GuiPosition = _G.GuiPosition or {}
_G.GuiLock = _G.GuiLock or {}
_G.EmoteNumber = _G.EmoteNumber or 1

local UserInputService = game:GetService("UserInputService")

local function MakeDraggable(topbarobject, object, locked)
    local Dragging = false
    local DragInput
    local DragStart
    local StartPosition
    local ActiveInput = nil

    local DragConnection = nil
    object:SetAttribute("Locked", locked or false)

    -- Membuat Tombol Gembok (Lock Toggle) Terpisah di Sebelah Kanan Tombol Macro
    local lockToggle = Instance.new("ImageButton")
    lockToggle.Name = "LockToggle"
    lockToggle.Size = UDim2.new(0, 28, 0, 28)
    lockToggle.Position = UDim2.new(1, 6, 0.5, -14) -- Posisinya di kanan persis
    lockToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    lockToggle.Image = object:GetAttribute("Locked") and "rbxassetid://10723434711" or "rbxassetid://10747366027"
    lockToggle.ScaleType = Enum.ScaleType.Fit
    lockToggle.Visible = false -- Awalnya disembunyikan
    lockToggle.Parent = object

    -- Mengatur Sudut Membulat & Padding Gembok
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = lockToggle

    local togglePadding = Instance.new("UIPadding")
    togglePadding.PaddingTop = UDim.new(0, 5)
    togglePadding.PaddingBottom = UDim.new(0, 5)
    togglePadding.PaddingLeft = UDim.new(0, 5)
    togglePadding.PaddingRight = UDim.new(0, 5)
    togglePadding.Parent = lockToggle

    -- Timer State untuk Menyembunyikan Tombol Gembok
    local holding = false
    local holdStart = 0
    local hideAt = 0

    local function IsInBounds(inputPosition)
        local absPos = topbarobject.AbsolutePosition
        local absSize = topbarobject.AbsoluteSize
        return inputPosition.X >= absPos.X and inputPosition.X <= (absPos.X + absSize.X)
           and inputPosition.Y >= absPos.Y and inputPosition.Y <= (absPos.Y + absSize.Y)
    end

    local function Update(input)
        local delta = input.Position - DragStart
        object.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end

    local function ConnectDragListener()
        if DragConnection then DragConnection:Disconnect() end
        DragConnection = UserInputService.InputChanged:Connect(function(input)
            if input == ActiveInput and Dragging then
                Update(input)
                hideAt = tick() -- Reset timer sembunyi gembok saat tombol digeser
                if object.Name == "EmoteBtn" then _G.GuiPosition["emote"] = object.Position end
                if object.Name == "CrouchBtn" then _G.GuiPosition["crouch"] = object.Position end
            end
        end)
    end

    local function DisconnectDragListener()
        if DragConnection then
            DragConnection:Disconnect()
            DragConnection = nil
        end
    end

    -- Sistem Aksi Klik Gembok Lock/Unlock
    lockToggle.MouseButton1Click:Connect(function()
        hideAt = tick() -- Reset timer 6 detik setiap kali gembok diklik
        local currentLock = not object:GetAttribute("Locked")
        object:SetAttribute("Locked", currentLock)

        if object.Name == "EmoteBtn" then _G.GuiLock["emote"] = currentLock end
        if object.Name == "CrouchBtn" then _G.GuiLock["crouch"] = currentLock end

        -- Perbarui Gambar Gembok (Locked / Unlocked)
        lockToggle.Image = currentLock and "rbxassetid://10723434711" or "rbxassetid://10747366027"

        if currentLock then
            DisconnectDragListener()
            Dragging = false
            ActiveInput = nil
        end

        if Fluent then
            Fluent:Notify({
                Title = currentLock and "Button Locked" or "Button Unlocked",
                Content = currentLock and "The button is locked in place." or "The button can now be slid freely.",
                Duration = 2
            })
        end
    end)

    -- Pengecekan Loop untuk Menyembunyikan Gembok Otomatis Selama 6 Detik
    task.spawn(function()
        while task.wait(0.25) do
            if lockToggle.Visible and (tick() - hideAt) >= 6 then
                lockToggle.Visible = false
            end
        end
    end)

    -- Input Dimulai (Bisa untuk Geser atau Deteksi Hold Munculkan Gembok)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if IsInBounds(input.Position) and not ActiveInput then
            ActiveInput = input
            DragStart = input.Position
            StartPosition = object.Position
            
            holding = true
            holdStart = tick()
            hideAt = tick() -- Reset timer gembok saat disentuh

            if not object:GetAttribute("Locked") then
                Dragging = true
                ConnectDragListener()
            end
        end
    end)

    -- Input Selesai (Mengecek jika ditahan 0.6 detik untuk memunculkan gembok)
    UserInputService.InputEnded:Connect(function(input)
        if input == ActiveInput then
            if holding then
                holding = false
                -- Jika tombol ditahan setidaknya 0.6 detik sebelum dilepas, munculkan tombol gembok
                if (tick() - holdStart) >= 0.6 then
                    lockToggle.Visible = true
                    hideAt = tick() -- Mulai hitung mundur 6 detik dari sekarang
                end
            end

            Dragging = false
            ActiveInput = nil
            DisconnectDragListener()
        end
    end)
end

local function updateAllTransparency()
    if emoteGui and crouchGui then
        local emoteBtn = emoteGui:FindFirstChild("EmoteBtn")
        local crouchBtn = crouchGui:FindFirstChild("CrouchBtn")
        if emoteBtn then
            emoteBtn.ImageTransparency = iconTransparency
            local txt = emoteBtn:FindFirstChild("TextLabel")
            if txt then txt.TextTransparency = textTransparency end
        end
        if crouchBtn then
            crouchBtn.ImageTransparency = iconTransparency
            local ico = crouchBtn:FindFirstChild("ImageLabel")
            if ico then ico.ImageTransparency = iconTransparency end
        end
    end
end

local function SetupMacroClick(button, callback)
    local dragStartPos = nil
    local startTime = 0
    local clickInput = nil

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local absPos = button.AbsolutePosition
            local absSize = button.AbsoluteSize
            if input.Position.X >= absPos.X and input.Position.X <= (absPos.X + absSize.X)
            and input.Position.Y >= absPos.Y and input.Position.Y <= (absPos.Y + absSize.Y) then
                if not clickInput then
                    clickInput = input
                    dragStartPos = input.Position
                    startTime = tick()
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == clickInput then
            if dragStartPos then
                local dragDistance = (input.Position - dragStartPos).Magnitude
                local holdDuration = tick() - startTime

                -- Macro klik biasa hanya berjalan jika ditekan kurang dari 0.6 detik (tidak bentrok dengan menu gembok)
                if holdDuration < 1 and dragDistance < 15 then
                    callback()
                end
            end
            dragStartPos = nil
            clickInput = nil
        end
    end)
end

-- Create UI
local function createMacroUI()
    if macroLoaded then return end
    macroLoaded = true

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    local guiPlayer = player:WaitForChild("PlayerGui")

    local function fire(a, b)
        player.PlayerScripts.Events.KeybindUsed:Fire(a, b)
    end

    -- EMOTE BUTTON
    emoteGui = Instance.new("ScreenGui", guiPlayer)
    emoteGui.Name = "EmoteGui"
    emoteGui.ResetOnSpawn = false

    local emoteBtn = Instance.new("ImageButton", emoteGui)
    emoteBtn.Name = "EmoteBtn"
    emoteBtn.Size = UDim2.new(0, BtnSize, 0, BtnSize)
    emoteBtn.Position = _G.GuiPosition["emote"] or UDim2.new(1, -100, 0.5, 0)
    emoteBtn.BackgroundTransparency = 1
    emoteBtn.Image = "rbxassetid://16803802267"
    emoteBtn.ImageTransparency = 1

    local emoteIcon = Instance.new("TextLabel", emoteBtn)
    emoteIcon.BackgroundTransparency = 1
    emoteIcon.Size = UDim2.new(1, 0, 1, 0)
    emoteIcon.Text = "☻"
    emoteIcon.TextScaled = true
    emoteIcon.TextTransparency = textTransparency
    emoteIcon.Font = Enum.Font.GothamBold
    emoteIcon.TextColor3 = Color3.new(1, 1, 1)

    MakeDraggable(emoteBtn, emoteBtn, _G.GuiLock["emote"] or false)

    local last = 0
    SetupMacroClick(emoteBtn, function()
        if tick() - last < 0.1 then return end
        last = tick()
        task.spawn(function()
            pcall(function()
                game.Workspace.Game.Players[player.Name].Equip:InvokeServer(2)
            end)
        end)
        task.spawn(function()
            pcall(function()
                ReplicatedStorage.Events.Emote:FireServer(tostring(_G.EmoteNumber))
            end)
        end)
        task.spawn(function()
            local char = player.Character
            if char then
                fire("Crouch", not char:GetAttribute("Crouching"))
            end
        end)
    end)

    -- CROUCH BUTTON
    crouchGui = Instance.new("ScreenGui", guiPlayer)
    crouchGui.Name = "CrouchGui"
    crouchGui.ResetOnSpawn = false

    local crouchBtn = Instance.new("ImageButton", crouchGui)
    crouchBtn.Name = "CrouchBtn"
    crouchBtn.Size = UDim2.new(0, BtnSize, 0, BtnSize)
    crouchBtn.Position = _G.GuiPosition["crouch"] or UDim2.new(0, 20, 0.5, 0)
    crouchBtn.BackgroundTransparency = 1
    crouchBtn.Image = "rbxassetid://16803802267"
    crouchBtn.ImageTransparency = 1

    local crouchIcon = Instance.new("ImageLabel", crouchBtn)
    crouchIcon.BackgroundTransparency = 1
    crouchIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
    crouchIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
    crouchIcon.Image = "rbxassetid://10238983204"
    crouchIcon.ImageTransparency = iconTransparency

    MakeDraggable(crouchBtn, crouchBtn, _G.GuiLock["crouch"] or false)

    SetupMacroClick(crouchBtn, function()
        local char = player.Character
        if char then
            fire("Crouch", not char:GetAttribute("Crouching"))
        end
    end)

    updateAllTransparency()
end

_G.CreateMacroUI = createMacroUI
