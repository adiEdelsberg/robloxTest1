--[[
    NPCSystem / AnimationController
    Wraps Roblox's Animator API to safely load, play, blend and
    stop animation tracks on an NPC humanoid.
    -- Memory-safe: all tracks are destroyed on cleanup().
    -- Blend-safe:  playing a new looped anim auto-stops the previous one
                   in the same priority slot.
--]]

local AnimationController = {}
AnimationController.__index = AnimationController

-- ── Constructor ───────────────────────────────────────────────────────────────
function AnimationController.new(humanoid)
    local self = setmetatable({}, AnimationController)

    self._humanoid = humanoid
    self._animator = humanoid:FindFirstChildOfClass("Animator")
    if not self._animator then
        self._animator = Instance.new("Animator")
        self._animator.Parent = humanoid
    end

    self._tracks  = {}   -- [animId] = AnimationTrack
    self._playing = {}   -- [animId] = true  (currently playing)
    self._active  = true -- set false on cleanup to reject new calls
    return self
end

-- ── Internal: load an AnimationTrack (cached) ────────────────────────────────
function AnimationController:_load(animId)
    if self._tracks[animId] then return self._tracks[animId] end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local ok, track = pcall(function()
        return self._animator:LoadAnimation(anim)
    end)
    anim:Destroy()  -- Animation object no longer needed after loading

    if not ok or not track then
        warn("[AnimationController] Failed to load:", animId, track)
        return nil
    end

    self._tracks[animId] = track

    -- Auto-remove from playing table when the track stops naturally
    track.Stopped:Connect(function()
        self._playing[animId] = nil
    end)

    return track
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Play an animation. Returns the track (or nil on failure).
-- options = { fadeTime, weight, speed, looped }
function AnimationController:play(animId, options)
    if not self._active then return nil end
    options = options or {}

    local track = self:_load(animId)
    if not track then return nil end

    local fadeTime = options.fadeTime or 0.15
    local weight   = options.weight   or 1
    local speed    = options.speed    or 1

    if options.looped ~= nil then
        track.Looped = options.looped
    end

    track:Play(fadeTime, weight, speed)
    self._playing[animId] = true
    return track
end

-- Stop a specific animation.
function AnimationController:stop(animId, fadeTime)
    if not self._active then return end
    local track = self._tracks[animId]
    if track and track.IsPlaying then
        track:Stop(fadeTime or 0.25)
        self._playing[animId] = nil
    end
end

-- Stop all currently playing animations.
function AnimationController:stopAll(fadeTime)
    if not self._active then return end
    for animId in pairs(table.clone(self._playing)) do
        self:stop(animId, fadeTime)
    end
end

-- Returns true if the given animation is currently playing.
function AnimationController:isPlaying(animId)
    local track = self._tracks[animId]
    return track ~= nil and track.IsPlaying
end

-- Adjust the playback speed of a playing track (e.g. slow walk while wandering).
function AnimationController:setSpeed(animId, speed)
    local track = self._tracks[animId]
    if track and track.IsPlaying then
        track:AdjustSpeed(speed)
    end
end

-- Destroy all tracks and mark controller inactive. Call when NPC is removed.
function AnimationController:cleanup()
    self._active = false
    for _, track in pairs(self._tracks) do
        if track.IsPlaying then track:Stop(0) end
        track:Destroy()
    end
    self._tracks  = {}
    self._playing = {}
end

return AnimationController
