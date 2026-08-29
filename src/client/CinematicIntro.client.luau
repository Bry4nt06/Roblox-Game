local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RIG_NAME = "Rig"
local CAMERA_FOV = 50
local CAMERA_OFFSET = Vector3.new(11, 5.5, 16)
local LOOK_OFFSET = Vector3.new(0, 1.75, 0)
local DRIFT_YAW_DEGREES = 1.6
local DRIFT_HEIGHT = 0.18
local TRANSITION_TIME = 0.55

local function getRigPivot(rig: Instance): CFrame?
	if rig:IsA("Model") then
		return rig:GetPivot()
	end
	if rig:IsA("BasePart") then
		return rig.CFrame
	end
	return nil
end

local function getCharacterRoot(): BasePart?
	local character = player.Character or player.CharacterAdded:Wait()
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setControlsEnabled(enabled: boolean)
	local playerScripts = player:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return
	end

	local playerModule = playerScripts:FindFirstChild("PlayerModule")
	if not playerModule or not playerModule:IsA("ModuleScript") then
		return
	end

	local ok, module = pcall(require, playerModule)
	if not ok or type(module) ~= "table" or type(module.GetControls) ~= "function" then
		return
	end

	local controls = module:GetControls()
	if enabled then
		controls:Enable()
	else
		controls:Disable()
	end
end

local rig = workspace:WaitForChild(RIG_NAME, 15)
if not rig then
	warn("[CinematicIntro] Workspace.Rig was not found; intro skipped")
	return
end

local rigPivot = getRigPivot(rig)
if not rigPivot then
	warn("[CinematicIntro] Rig must be a Model or BasePart; intro skipped")
	return
end

setControlsEnabled(false)

local originalFov = camera.FieldOfView
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = CAMERA_FOV

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CinematicIntroGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.ZIndex = 20
fade.Parent = screenGui

local topBar = Instance.new("Frame")
topBar.Name = "TopLetterbox"
topBar.Size = UDim2.fromScale(1, 0.075)
topBar.Position = UDim2.fromScale(0, 0)
topBar.BackgroundColor3 = Color3.new(0, 0, 0)
topBar.BorderSizePixel = 0
topBar.ZIndex = 5
topBar.Parent = screenGui

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomLetterbox"
bottomBar.Size = UDim2.fromScale(1, 0.075)
bottomBar.Position = UDim2.fromScale(0, 0.925)
bottomBar.BackgroundColor3 = Color3.new(0, 0, 0)
bottomBar.BorderSizePixel = 0
bottomBar.ZIndex = 5
bottomBar.Parent = screenGui

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.AnchorPoint = Vector2.new(0.5, 0.5)
playButton.Position = UDim2.fromScale(0.5, 0.82)
playButton.Size = UDim2.fromOffset(240, 62)
playButton.AutoButtonColor = false
playButton.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
playButton.BackgroundTransparency = 0.22
playButton.BorderSizePixel = 0
playButton.Font = Enum.Font.GothamBold
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.TextSize = 24
playButton.TextTransparency = 0
playButton.ZIndex = 10
playButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = playButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.35
stroke.Thickness = 1
stroke.Parent = playButton

local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 8)),
})
gradient.Parent = playButton

local introStart = os.clock()
local renderStepName = "CinematicIntroCamera"

local function computeCameraCFrame(now: number): CFrame
	local pivot = getRigPivot(rig) or rigPivot
	local target = pivot.Position + LOOK_OFFSET
	local yaw = math.rad(math.sin((now - introStart) * 0.35) * DRIFT_YAW_DEGREES)
	local height = math.sin((now - introStart) * 0.5) * DRIFT_HEIGHT
	local drift = CFrame.Angles(0, yaw, 0)
	local cameraPosition = (pivot * drift * CFrame.new(CAMERA_OFFSET + Vector3.new(0, height, 0))).Position
	return CFrame.lookAt(cameraPosition, target)
end

RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value + 1, function()
	camera.CFrame = computeCameraCFrame(os.clock())
end)

local function tweenButton(targetTransparency: number)
	TweenService:Create(
		playButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = targetTransparency,
			TextTransparency = math.clamp(targetTransparency, 0, 1),
		}
	):Play()
end

playButton.MouseEnter:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.12), {
		Size = UDim2.fromOffset(252, 66),
		BackgroundTransparency = 0.1,
	}):Play()
end)

playButton.MouseLeave:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.12), {
		Size = UDim2.fromOffset(240, 62),
		BackgroundTransparency = 0.22,
	}):Play()
end)

local finishing = false
playButton.Activated:Connect(function()
	if finishing then
		return
	end
	finishing = true
	playButton.Active = false

	TweenService:Create(fade, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()
	tweenButton(1)

	task.wait(0.24)
	RunService:UnbindFromRenderStep(renderStepName)

	local root = getCharacterRoot()
	if root then
		local destination = CFrame.lookAt(
			(root.CFrame * CFrame.new(7, 4.5, 12)).Position,
			root.Position + Vector3.new(0, 2, 0)
		)
		local cameraTween = TweenService:Create(
			camera,
			TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{
				CFrame = destination,
				FieldOfView = originalFov,
			}
		)
		cameraTween:Play()
		cameraTween.Completed:Wait()
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = originalFov
	setControlsEnabled(true)

	TweenService:Create(fade, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	task.wait(0.36)
	screenGui:Destroy()
end)
