-- DogeMorph.lua
-- Place this as a LocalScript inside StarterPlayer > StarterPlayerScripts
-- (or anywhere that runs client-side per player, e.g. StarterGui/StarterCharacterScripts).

local Players = game:GetService(""Players"")
local player  = Players.LocalPlayer

local DOGE_ASSET_ID = ""257489726""

local ANIM_IDS = {
	idle = ""180435571"",
	walk = ""180426354"",
	jump = ""125750702"",
	fall = ""180436148"",
}

local function morphCharacter(oldChar)
	local plrRoot = oldChar:FindFirstChild(""HumanoidRootPart"") or oldChar:FindFirstChild(""Torso"")
	local spawnCF = plrRoot and plrRoot.CFrame or CFrame.new(0, 5, 0)

	local ok, objects = pcall(function()
		return game:GetObjects(""rbxassetid://"" .. DOGE_ASSET_ID)
	end)

	if not ok then
		-- pcall failed: `objects` here is actually the error string
		warn(""[MORPH] GetObjects errored: "" .. tostring(objects))
		return
	end

	if not objects or #objects == 0 then
		warn(""[MORPH] GetObjects returned no items for rbxassetid://"" .. DOGE_ASSET_ID
			.. "" -- the asset is likely private, deleted, not a Model, or Studio API access is disabled."")
		return
	end

	local charClone = objects[1]:Clone()
	charClone.Name = player.Name

	local hum = charClone:FindFirstChildOfClass(""Humanoid"")
	if not hum then
		hum = Instance.new(""Humanoid"")
		hum.Parent = charClone
	end

	local cloneRoot = charClone:FindFirstChild(""HumanoidRootPart"") or charClone:FindFirstChild(""Torso"")

	-- Parent BEFORE destroying the old character, and BEFORE reassigning
	-- player.Character, so nothing ever points at a nil/destroyed instance.
	charClone.Parent = workspace
	if cloneRoot then
		cloneRoot.CFrame = spawnCF
	end

	player.Character = charClone
	oldChar:Destroy()

	-- Camera: keep default third-person follow behavior instead of forcing
	-- CameraType.Follow (which locks rotation and feels broken to most players).
	local camera = workspace.CurrentCamera
	camera.CameraSubject = hum
	camera.CameraType = Enum.CameraType.Custom

	local animator = hum:FindFirstChildOfClass(""Animator"")
	if not animator then
		animator = Instance.new(""Animator"")
		animator.Parent = hum
	end

	local function makeTrack(id, looped)
		local anim = Instance.new(""Animation"")
		anim.AnimationId = ""rbxassetid://"" .. id
		local track = animator:LoadAnimation(anim)
		track.Looped = looped
		return track
	end

	local tracks = {
		idle = makeTrack(ANIM_IDS.idle, true),
		walk = makeTrack(ANIM_IDS.walk, true),
		jump = makeTrack(ANIM_IDS.jump, false),
		fall = makeTrack(ANIM_IDS.fall, true),
	}

	local current = nil
	local function play(name)
		if current == name then
			return
		end
		for k, t in pairs(tracks) do
			if k ~= name then
				pcall(function() t:Stop() end)
			end
		end
		pcall(function() tracks[name]:Play() end)
		current = name
	end

	play(""idle"")

	hum.Running:Connect(function(speed)
		if speed > 0.5 then
			play(""walk"")
		else
			play(""idle"")
		end
	end)

	hum.Jumping:Connect(function(active)
		if active then
			play(""jump"")
		end
	end)

	hum.FreeFalling:Connect(function(active)
		if active then
			play(""fall"")
		end
	end)

	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed then
			play(""idle"")
		end
	end)

	print(""[MORPH] Done - animations running"")
end

-- Run on current character, and again every time the player respawns.
if player.Character then
	morphCharacter(player.Character)
end
player.CharacterAdded:Connect(morphCharacter);