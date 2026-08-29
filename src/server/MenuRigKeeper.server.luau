local RIG_NAME = "Rig"

local rig = workspace:WaitForChild(RIG_NAME, 15)
if not rig then
	warn("[MenuRigKeeper] Workspace.Rig was not found")
	return
end

local savedPivot: CFrame?
if rig:IsA("Model") then
	savedPivot = rig:GetPivot()
elseif rig:IsA("BasePart") then
	savedPivot = rig.CFrame
end

for _, descendant in rig:GetDescendants() do
	if descendant:IsA("BasePart") then
		descendant.Anchored = true
		descendant.AssemblyLinearVelocity = Vector3.zero
		descendant.AssemblyAngularVelocity = Vector3.zero
	elseif descendant:IsA("Humanoid") then
		descendant.AutoRotate = false
		descendant.BreakJointsOnDeath = false
		descendant.Health = math.max(descendant.Health, descendant.MaxHealth)
	end
end

if savedPivot and rig:IsA("Model") then
	rig:PivotTo(savedPivot)
elseif savedPivot and rig:IsA("BasePart") then
	rig.CFrame = savedPivot
end

print("[MenuRigKeeper] Rig frozen for cinematic display")
