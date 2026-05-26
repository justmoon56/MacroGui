-- Macro

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

-- Hold Lock System
local function holdSystem(button,callback,name)
    local HoldTime = 5
    local locked = _G.GuiLock[name] or false
    local holding = false
    local holdStart = 0
    local holdTriggered = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        holding = true
        holdStart = tick()
        holdTriggered = false

        callback()
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        holding = false
    end)

    game:GetService("RunService").RenderStepped:Connect(function()
        if holding and not holdTriggered then
            if tick() - holdStart >= HoldTime then
                holdTriggered = true
                locked = not locked
                _G.GuiLock[name] = locked

            end
        end
    end)

    return function()
        return locked
    end
end

-- Drag System
local function drag(button,isLocked,name)
    local UIS = game:GetService("UserInputService")

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    if _G.GuiPosition[name] then
        button.Position = _G.GuiPosition[name]
    end

    button.InputBegan:Connect(function(input)
        if isLocked and isLocked() then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    button.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            button.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )

            _G.GuiPosition[name] = button.Position
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            dragInput = nil
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
