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
    local DragStart = nil
    local StartPosition = nil
    local ActiveInput = nil

    local PressStartTime = 0
    local HoldTime = 5.0
    local HasToggledThisPress = false
    local MoveThreshold = 10 -- Tombol baru mau bergerak jika digeser lebih dari 10 pixel

    object:SetAttribute("Locked", locked or false)

    -- Fungsi mengecek area tombol
    local function IsInBounds(inputPosition)
        local absPos = topbarobject.AbsolutePosition
        local absSize = topbarobject.AbsoluteSize
        return inputPosition.X >= absPos.X and inputPosition.X <= (absPos.X + absSize.X)
           and inputPosition.Y >= absPos.Y and inputPosition.Y <= (absPos.Y + absSize.Y)
    end

    local function ToggleLock()
        local newState = not object:GetAttribute("Locked")
        object:SetAttribute("Locked", newState)

        if object.Name == "EmoteBtn" then _G.GuiLock["emote"] = newState end
        if object.Name == "CrouchBtn" then _G.GuiLock["crouch"] = newState end

        -- Notifikasi Fluent UI sesuai permintaanmu
        if Fluent then
            Fluent:Notify({
                Title = newState and "Button Locked" or "Button Unlocked",
                Content = newState and "Ditahan 5 detik: Tombol Berhasil Dikunci!" or "Ditahan 5 detik: Tombol Sekarang Bisa Digeser!",
                Duration = 3
            })
        else
            print(object.Name .. " Status Lock: " .. tostring(newState))
        end
    end

    -- Input Dimulai
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if IsInBounds(input.Position) and not ActiveInput then
            ActiveInput = input
            DragStart = input.Position
            StartPosition = object.Position
            Dragging = false -- Belum di-drag sampai melewati threshold
            
            PressStartTime = tick()
            HasToggledThisPress = false

            -- Thread khusus menghitung durasi tahanan 5 detik
            task.spawn(function()
                while ActiveInput == input and PressStartTime > 0 do
                    task.wait(0.1)
                    if PressStartTime > 0 and (tick() - PressStartTime) >= HoldTime and not HasToggledThisPress then
                        HasToggledThisPress = true
                        
                        -- Jalankan fungsi Lock / Unlock
                        ToggleLock()
                        
                        -- Lepas paksa fungsi drag/seret saat itu juga
                        Dragging = false
                        ActiveInput = nil
                        PressStartTime = 0
                        break
                    end
                end
            end)
        end
    end)

    -- Pergerakan Input
    UserInputService.InputChanged:Connect(function(input)
        if input == ActiveInput and DragStart and StartPosition then
            -- Jika tombol sudah dikunci, jangan biarkan bergerak sama sekali
            if object:GetAttribute("Locked") then 
                Dragging = false
                return 
            end

            local delta = input.Position - DragStart
            
            -- Jika pergerakan melampaui batas threshold, aktifkan mode drag dan matikan timer lock
            if delta.Magnitude > MoveThreshold then
                Dragging = true
                PressStartTime = 0 -- Batalkan lock karena user berniat menggeser
            end

            if Dragging then
                object.Position = UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset + delta.X,
                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset + delta.Y
                )
                if object.Name == "EmoteBtn" then _G.GuiPosition["emote"] = object.Position end
                if object.Name == "CrouchBtn" then _G.GuiPosition["crouch"] = object.Position end
            end
        end
    end)

    -- Input Selesai
    UserInputService.InputEnded:Connect(function(input)
        if input == ActiveInput then
            Dragging = false
            PressStartTime = 0
            ActiveInput = nil
            DragStart = nil
            StartPosition = nil
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
        if crouchGui then
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

                -- Macro klik normal hanya aktif jika ditekan kurang dari 4 detik
                if holdDuration < 4.0 and dragDistance < 15 then
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

    -- EMOTE
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

    -- CROUCH
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
