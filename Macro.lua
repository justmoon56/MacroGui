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

    -- Menggunakan penanda waktu berbasis tick()
    local PressStartTime = 0
    local MoveCancelThreshold = 10 -- Diperlonggar sedikit agar getaran jari tidak membatalkan lock
    local HoldTime = 5.0
    local HasLockedThisPress = false

    object:SetAttribute("Locked", locked or false)

    local function Update(input)
        if object:GetAttribute("Locked") then return end
        local delta = input.Position - DragStart
        object.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end

    local function ToggleLock()
        local newState = not object:GetAttribute("Locked")
        object:SetAttribute("Locked", newState)

        if object.Name == "EmoteBtn" then _G.GuiLock["emote"] = newState end
        if object.Name == "CrouchBtn" then _G.GuiLock["crouch"] = newState end

        if Fluent then
            Fluent:Notify({
                Title = newState and "Button Locked" or "Button Unlocked",
                Content = newState and "This button is now locked in place." or "This button can now be moved.",
                Duration = 2
            })
        else
            print(object.Name .. " Locked: " .. tostring(newState))
        end
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        Dragging = not object:GetAttribute("Locked")
        DragStart = input.Position
        StartPosition = object.Position
        
        PressStartTime = tick() -- Catat waktu awal ditekan
        HasLockedThisPress = false

        -- Menggunakan loop terpisah untuk mengecek apakah sudah lewat 5 detik
        task.spawn(function()
            while Dragging or PressStartTime > 0 do
                task.wait(0.1)
                -- Jika waktu tekan sudah lewat 5 detik dan belum ke-lock di sesi tekan ini
                if PressStartTime > 0 and (tick() - PressStartTime) >= HoldTime and not HasLockedThisPress then
                    HasLockedThisPress = true
                    ToggleLock()
                    Dragging = false -- Matikan drag karena sudah terkunci
                    break
                end
            end
        end)
    end)

    topbarobject.InputChanged:Connect(function(input)
        if not DragStart or PressStartTime == 0 then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            -- Jika digeser terlalu jauh dari posisi awal tekan, batalkan timer lock
            if (input.Position - DragStart).Magnitude > MoveCancelThreshold then
                PressStartTime = 0 -- Reset penanda, artinya user berniat nge-drag bukan nge-lock
            end
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging and not object:GetAttribute("Locked") then
            Update(input)
            if object.Name == "EmoteBtn" then _G.GuiPosition["emote"] = object.Position end
            if object.Name == "CrouchBtn" then _G.GuiPosition["crouch"] = object.Position end
        end
    end)

    -- Reset semua state saat tombol dilepas
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
            PressStartTime = 0
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

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStartPos = input.Position
            startTime = tick()
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragStartPos then
                local dragDistance = (input.Position - dragStartPos).Magnitude
                local holdDuration = tick() - startTime

                -- Hanya eksekusi macro jika tidak sedang mencoba melakukan lock (di bawah 5 detik)
                if holdDuration < 5.0 and dragDistance < 15 then
                    callback()
                end
                dragStartPos = nil
            end
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

_G.CreateMacroUI = createMacroUIlocal function createMacroUI()
    if macroLoaded then return end
    macroLoaded = true

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer
    local guiPlayer = player:WaitForChild("PlayerGui")

    local function fire(a,b)
        player.PlayerScripts.Events.KeybindUsed:Fire(a,b)
    end

    -- EMOTE
    emoteGui = Instance.new("ScreenGui", guiPlayer)
    emoteGui.Name = "EmoteGui"
    emoteGui.ResetOnSpawn = false

    local emoteBtn = Instance.new("ImageButton", emoteGui)
    emoteBtn.Size = UDim2.new(0,BtnSize,0,BtnSize)
    emoteBtn.Position = UDim2.new(1,-100,0.5,0)
    emoteBtn.BackgroundTransparency = 1
    emoteBtn.Image = "rbxassetid://16803802267"
    emoteBtn.ImageTransparency = 1

    local emoteIcon = Instance.new("TextLabel", emoteBtn)
    emoteIcon.BackgroundTransparency = 1
    emoteIcon.Size = UDim2.new(1,0,1,0)
    emoteIcon.Text = "☻"
    emoteIcon.TextScaled = true
    emoteIcon.TextTransparency = textTransparency
    emoteIcon.Font = Enum.Font.GothamBold
    emoteIcon.TextColor3 = Color3.new(1,1,1)

    local last = 0

local emoteLock = holdSystem(emoteBtn,function()
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
			fire("Crouch",not char:GetAttribute("Crouching"))
		end
	end)

end,"emote")

drag(emoteBtn,emoteLock,"emote")

    -- CROUCH
    crouchGui = Instance.new("ScreenGui", guiPlayer)
    crouchGui.Name = "CrouchGui"
    crouchGui.ResetOnSpawn = false

    local crouchBtn = Instance.new("ImageButton", crouchGui)
    crouchBtn.Size = UDim2.new(0,BtnSize,0,BtnSize)
    crouchBtn.Position = UDim2.new(0,20,0.5,0)
    crouchBtn.BackgroundTransparency = 1
    crouchBtn.Image = "rbxassetid://16803802267"
    crouchBtn.ImageTransparency = 1

    local crouchIcon = Instance.new("ImageLabel", crouchBtn)
    crouchIcon.BackgroundTransparency = 1
    crouchIcon.Size = UDim2.new(0.6,0,0.6,0)
    crouchIcon.Position = UDim2.new(0.2,0,0.2,0)
    crouchIcon.Image = "rbxassetid://10238983204"
    crouchIcon.ImageTransparency = iconTransparency

local crouchLock = holdSystem(crouchBtn,function()
	local char = player.Character
	if char then
		fire("Crouch",not char:GetAttribute("Crouching"))
	end
end,"crouch")

drag(crouchBtn,crouchLock,"crouch")

    updateAllTransparency()
end

_G.CreateMacroUI=createMacroUI
