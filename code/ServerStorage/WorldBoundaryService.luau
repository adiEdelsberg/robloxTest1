local RunService = game:GetService("RunService")

local BoundaryService = {}

local DEFAULT_MARGIN = 4
local DEFAULT_INTERVAL = 0.12

local function getPivot(model)
	if model:IsA("Model") then
		return model:GetPivot()
	elseif model:IsA("BasePart") then
		return model.CFrame
	end
	return nil
end

local function setPivot(model, cf)
	if model:IsA("Model") then
		model:PivotTo(cf)
	elseif model:IsA("BasePart") then
		model.CFrame = cf
	end
end

function BoundaryService.clampPosition(position, bounds, margin, minY, maxY)
	margin = margin or 0
	local minX = (bounds.minX or position.X) + margin
	local maxX = (bounds.maxX or position.X) - margin
	local minZ = (bounds.minZ or position.Z) + margin
	local maxZ = (bounds.maxZ or position.Z) - margin

	if minX > maxX then
		local middle = ((bounds.minX or position.X) + (bounds.maxX or position.X)) * 0.5
		minX, maxX = middle, middle
	end
	if minZ > maxZ then
		local middle = ((bounds.minZ or position.Z) + (bounds.maxZ or position.Z)) * 0.5
		minZ, maxZ = middle, middle
	end

	return Vector3.new(
		math.clamp(position.X, minX, maxX),
		minY and maxY and math.clamp(position.Y, minY, maxY) or position.Y,
		math.clamp(position.Z, minZ, maxZ)
	)
end

function BoundaryService.clampCFrame(cf, bounds, options)
	options = options or {}
	local clamped = BoundaryService.clampPosition(cf.Position, bounds, options.margin or DEFAULT_MARGIN, options.minY, options.maxY)
	if (clamped - cf.Position).Magnitude <= 0.001 then
		return cf, false
	end
	return cf + (clamped - cf.Position), true
end

function BoundaryService.bindModel(model, bounds, options)
	options = options or {}
	local interval = options.interval or DEFAULT_INTERVAL
	local alive = true

	local ancestryConn
	ancestryConn = model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			alive = false
			if ancestryConn then ancestryConn:Disconnect() end
		end
	end)

	task.spawn(function()
		local elapsed = 0
		while alive and model.Parent do
			elapsed += RunService.Heartbeat:Wait()
			if elapsed < interval then continue end
			elapsed = 0

			local cf = getPivot(model)
			if not cf then break end
			local clamped, changed = BoundaryService.clampCFrame(cf, bounds, options)
			if changed then
				setPivot(model, clamped)
				local root = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")) or model
				if root and root:IsA("BasePart") then
					root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
					root.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
		if ancestryConn then ancestryConn:Disconnect() end
	end)
end

return BoundaryService
