-- UI State
local emoteGui, crouchGui
local macroLoaded = false

-- Settings
local textTransparency = 0.6
local iconTransparency = 0.6
local BtnSize = 80

_G.GuiPosition = _G.GuiPosition or {}
_G.GuiLock = _G.GuiLock or {}
-- Pastikan default lock di-load dengan benar (jika nil, set false)
_G.GuiLock["emote"] = _G.GuiLock["emote"] or false
_G.GuiLock["crouch"] = _G.GuiLock["crouch"] or false
_G.EmoteNumber = _G.EmoteNumber or 1

local UserInputService = game:GetService("UserInputService")

local function MakeDraggable(topbarobject, object, lockToggleBtn)
    local Dragging = false
    local DragStart
    local StartPosition
    local ActiveInput = nil
    local DragConnection = nil

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

    -- Pantau status perubahan lock secara real-time
    local function CheckLockState()
        local isLocked = object:GetAttribute("Locked")
        if isLocked then
            DisconnectDragListener()
            Dragging = false
            ActiveInput = nil
            lockToggleBtn.Image = "rbxassetid://10723434711" -- ID Gembok Terkunci
        else
            lockToggleBtn.Image = "rbxassetid://10747366027" -- ID Gembok Terbuka
        end
    end

    -- Daftarkan fungsi perubahan atribut agar gembok langsung merespon saat di-toggle
    object:GetAttributeChangedSignal("Locked"):Connect(CheckLockState)
    CheckLockState() -- Jalankan pengecekan awal saat UI dibuat

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if IsInBounds(input.Position) and not ActiveInput and not object:GetAttribute("Locked") then
            ActiveInput = input
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            ConnectDragListener()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == ActiveInput then
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
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == clickInput then
            if dragStartPos then
                local dragDistance = (input.Position - dragStartPos).Magnitude
                -- Klik macro hanya terpicu jika tombol tidak sedang digeser sejauh > 15 pixel
                if dragDistance < 15 then
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

    -- ==========================================
    -- EMOTE BUTTON SETUP
    -- ==========================================
    emoteGui = Instance.new("ScreenGui", guiPlayer)
    emoteGui.Name = "EmoteGui"
    emoteGui.ResetOnSpawn = false

    local emoteBtn = Instance.new("ImageButton", emoteGui)
    emoteBtn.Name = "EmoteBtn"
    emoteBtn.Size = UDim2.new(0, BtnSize, 0, BtnSize)
    emoteBtn.Position = _G.GuiPosition["emote"] or UDim2.new(1, -140, 0.5, 0)
    emoteBtn.BackgroundTransparency = 1
    emoteBtn.Image = "rbxassetid://16803802267"
    emoteBtn.ImageTransparency = 1
    emoteBtn:SetAttribute("Locked", _G.GuiLock["emote"])

    local emoteIcon = Instance.new("TextLabel", emoteBtn)
    emoteIcon.BackgroundTransparency = 1
    emoteIcon.Size = UDim2.new(1, 0, 1, 0)
    emoteIcon.Text = "☻"
    emoteIcon.TextScaled = true
    emoteIcon.TextTransparency = textTransparency
    emoteIcon.Font = Enum.Font.GothamBold
    emoteIcon.TextColor3 = Color3.new(1, 1, 1)

    -- Tombol Toggle Lock di Sebelah Kanan (Emote)
    local emoteLockToggle = Instance.new("ImageButton", emoteBtn)
    emoteLockToggle.Name = "LockToggle"
    emoteLockToggle.Size = UDim2.new(0, 28, 0, 28)
    emoteLockToggle.Position = UDim2.new(1, 6, 0.5, -14) -- Di kanan luar tombol utama
    emoteLockToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    emoteLockToggle.BackgroundTransparency = 0.3
    emoteLockToggle.ScaleType = Enum.ScaleType.Fit

    local emoteLockCorner = Instance.new("UICorner", emoteLockToggle)
    emoteLockCorner.CornerRadius = UDim.new(1, 0)

    local emoteLockPadding = Instance.new("UIPadding", emoteLockToggle)
    emoteLockPadding.PaddingTop = UDim.new(0, 4)
    emoteLockPadding.PaddingBottom = UDim.new(0, 4)
    emoteLockPadding.PaddingLeft = UDim.new(0, 4)
    emoteLockPadding.PaddingRight = UDim.new(0, 4)

    MakeDraggable(emoteBtn, emoteBtn, emoteLockToggle)

    emoteLockToggle.MouseButton1Click:Connect(function()
        local currentLock = emoteBtn:GetAttribute("Locked")
        local newLock = not currentLock
        emoteBtn:SetAttribute("Locked", newLock)
        _G.GuiLock["emote"] = newLock

        if Fluent then
            Fluent:Notify({
                Title = newLock and "Emote Locked" or "Emote Unlocked",
                Content = newLock and "Fungsi geser dimatikan." or "Tombol bisa digeser kembali.",
                Duration = 2
            })
        end
    end)

    local lastEmote = 0
    SetupMacroClick(emoteBtn, function()
        if tick() - lastEmote < 0.1 then return end
        lastEmote = tick()
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

    -- ==========================================
    -- CROUCH BUTTON SETUP
    -- ==========================================
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
    crouchBtn:SetAttribute("Locked", _G.GuiLock["crouch"])

    local crouchIcon = Instance.new("ImageLabel", crouchBtn)
    crouchIcon.BackgroundTransparency = 1
    crouchIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
    crouchIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
    crouchIcon.Image = "rbxassetid://10238983204"
    crouchIcon.ImageTransparency = iconTransparency

    -- Tombol Toggle Lock di Sebelah Kanan (Crouch)
    local crouchLockToggle = Instance.new("ImageButton", crouchBtn)
    crouchLockToggle.Name = "LockToggle"
    crouchLockToggle.Size = UDim2.new(0, 28, 0, 28)
    crouchLockToggle.Position = UDim2.new(1, 6, 0.5, -14) -- Di kanan luar tombol utama
    crouchLockToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    crouchLockToggle.BackgroundTransparency = 0.3
    crouchLockToggle.ScaleType = Enum.ScaleType.Fit

    local crouchLockCorner = Instance.new("UICorner", crouchLockToggle)
    crouchLockCorner.CornerRadius = UDim.new(1, 0)

    local crouchLockPadding = Instance.new("UIPadding", crouchLockToggle)
    crouchLockPadding.PaddingTop = UDim.new(0, 4)
    crouchLockPadding.PaddingBottom = UDim.new(0, 4)
    crouchLockPadding.PaddingLeft = UDim.new(0, 4)
    crouchLockPadding.PaddingRight = UDim.new(0, 4)

    MakeDraggable(crouchBtn, crouchBtn, crouchLockToggle)

    crouchLockToggle.MouseButton1Click:Connect(function()
        local currentLock = crouchBtn:GetAttribute("Locked")
        local newLock = not currentLock
        crouchBtn:SetAttribute("Locked", newLock)
        _G.GuiLock["crouch"] = newLock

        if Fluent then
            Fluent:Notify({
                Title = newLock and "Crouch Locked" or "Crouch Unlocked",
                Content = newLock and "Fungsi geser dimatikan." or "Tombol bisa digeser kembali.",
                Duration = 2
            })
        end
    end)

    SetupMacroClick(crouchBtn, function()
        local char = player.Character
        if char then
            fire("Crouch", not char:GetAttribute("Crouching"))
        end
    end)

    updateAllTransparency()
end

_G.CreateMacroUI = createMacroUI
