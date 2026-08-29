local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
if not camera then
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	camera = workspace.CurrentCamera
end
if not camera then
	warn("[CinematicIntro] Workspace.CurrentCamera was not available; intro skipped")
	return
end

local RIG_NAME = "Rig"
local CAMERA_MARKER_NAME = "IntroCamera"
local TARGET_MARKER_NAME = "IntroCameraTarget"
local CAMERA_FOV = 50
local TRANSITION_TIME = 0.55
local RENDER_STEP_NAME = "CinematicIntroCamera"

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

local function findMarker(name: string): BasePart?
	local marker = workspace:FindFirstChild(name)
	if marker and marker:IsA("BasePart") then
		return marker
	end
	return nil
end

local rig = workspace:WaitForChild(RIG_NAME, 15)
if not rig then
	warn("[CinematicIntro] Workspace.Rig was not found; intro skipped")
	return
end

local cameraMarker = findMarker(CAMERA_MARKER_NAME)
local targetMarker = findMarker(TARGET_MARKER_NAME)

if not cameraMarker or not targetMarker then
	warn("[CinematicIntro] IntroCamera and IntroCameraTarget must exist in Workspace; intro skipped")
	return
end

-- Markers remain visible in Studio edit mode but disappear for the local player during play.
cameraMarker.LocalTransparencyModifier = 1
targetMarker.LocalTransparencyModifier = 1

setControlsEnabled(false)

local originalFov = camera.FieldOfView
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = CAMERA_FOV

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("CinematicIntroGui")
if oldGui then
	oldGui:Destroy()
end

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

local function markerCameraCFrame(): CFrame
	local from = cameraMarker.Position
	local target = targetMarker.Position
	if (target - from).Magnitude < 0.05 then
		return cameraMarker.CFrame
	end
	return CFrame.lookAt(from, target)
end

RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function()
	camera.CFrame = markerCameraCFrame()
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
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)

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
