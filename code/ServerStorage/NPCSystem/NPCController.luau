--[[
    NPCSystem / NPCController
    Per-NPC behaviour state machine.  Runs a 10 Hz server-side loop to:
      • Wander to random points within WANDER_RADIUS of the spawn position
      • Smoothly turn toward the nearest player within LOOK_AT_RANGE studs
      • Occasionally play random idle actions (wave, point, laugh…)
      • Return to idle when nothing interesting is nearby

    States:
        IDLE        → standing still, plays base idle animation
        WANDER      → walking to a random nearby point
        LOOK_PLAYER → turning body to face a nearby player
        IDLE_ACTION → playing a random emote (wave, dance, etc.)
--]]

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local Config     = require(script.Parent.Config)
local AnimCtrl   = require(script.Parent.AnimationController)

local SETTINGS    = Config.Settings
local ANIMS       = Config.Animations

-- State constants
local STATE = {
    IDLE        = "IDLE",
    WANDER      = "WANDER",
    LOOK_PLAYER = "LOOK_PLAYER",
    IDLE_ACTION = "IDLE_ACTION",
}

local NPCController = {}
NPCController.__index = NPCController

-- ── Constructor ───────────────────────────────────────────────────────────────
function NPCController.new(model, npcDef, spawnPos)
    local self = setmetatable({}, NPCController)

    self._model       = model
    self._npcDef      = npcDef
    self._spawnPos    = spawnPos   -- Vector3, origin for wander bounds
    self._active      = true
    self._state       = STATE.IDLE

    -- Wander state
    self._wanderTarget   = nil
    self._wanderTimeout  = 0

    -- Timing
    self._nextWander     = self:_randTime(4, 10)
    self._nextIdleAction = self:_randTime(8, 18)
    self._nextLookCheck  = 0
    self._idleActionEnd  = 0
    self._conn           = nil

    -- Grab key model parts
    self._hrp       = model:FindFirstChild("HumanoidRootPart")
    self._humanoid  = model:FindFirstChildOfClass("Humanoid")
    self._animCtrl  = self._humanoid and AnimCtrl.new(self._humanoid) or nil

    if self._humanoid then
        -- Never let the Humanoid fall over
        self._humanoid.AutoRotate = false
        self._humanoid.WalkSpeed  = math.random(npcDef.minSpeed or 8, npcDef.maxSpeed or 14)
    end

    self:_playIdle()
    return self
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

function NPCController:_randTime(minT, maxT)
    return tick() + minT + math.random() * (maxT - minT)
end

function NPCController:_playIdle()
    if not self._animCtrl then return end
    self._animCtrl:stopAll(0.3)
    self._animCtrl:play(ANIMS.Idle, { fadeTime = 0.3, looped = true })
end

function NPCController:_playWalk()
    if not self._animCtrl then return end
    self._animCtrl:stop(ANIMS.Idle, 0.2)
    self._animCtrl:play(ANIMS.Walk, { fadeTime = 0.2, looped = true })
end

function NPCController:_playIdleAction()
    if not self._animCtrl then return end
    local actions = ANIMS.IdleActions
    local keys = {}
    for k in pairs(actions) do table.insert(keys, k) end
    local chosen = actions[keys[math.random(#keys)]]

    self._animCtrl:stopAll(0.2)
    local track = self._animCtrl:play(chosen, { fadeTime = 0.2, looped = false })
    if track then
        self._idleActionEnd = tick() + (track.Length > 0 and track.Length or 2.5)
    else
        self._idleActionEnd = tick() + 2.5
    end
end

-- Nearest player within range; returns (player, dist) or (nil, math.huge).
function NPCController:_nearestPlayer()
    if not self._hrp then return nil, math.huge end
    local pos = self._hrp.Position
    local best, bestDist = nil, SETTINGS.LOOK_AT_RANGE

    for _, p in Players:GetPlayers() do
        local char = p.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - pos).Magnitude
            if d < bestDist then
                best      = hrp
                bestDist  = d
            end
        end
    end
    return best, bestDist
end

-- Smoothly rotate model to face target XZ position.
function NPCController:_faceToward(targetPos, dt, turnSpeed)
    if not self._hrp then return end
    turnSpeed = turnSpeed or 5
    local current = self._hrp.CFrame
    local goalDir = (Vector3.new(targetPos.X, current.Position.Y, targetPos.Z) - current.Position)
    if goalDir.Magnitude < 0.05 then return end
    local goal = CFrame.lookAt(current.Position, current.Position + goalDir)
    self._hrp.CFrame = current:Lerp(goal, math.min(1, dt * turnSpeed))
end

-- Pick a random point near the spawn origin (flat, within WANDER_RADIUS).
function NPCController:_pickWanderTarget()
    local r     = SETTINGS.WANDER_RADIUS
    local angle = math.random() * math.pi * 2
    local dist  = math.random() * r
    return self._spawnPos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

-- ── Start the behaviour loop ──────────────────────────────────────────────────
function NPCController:start()
    if self._conn then return end

    local lastTick = tick()
    self._conn = RunService.Heartbeat:Connect(function()
        if not self._active then return end

        local now = tick()
        local dt  = now - lastTick
        lastTick  = now

        -- Safety guard: model or parts removed
        if not self._model.Parent or not self._hrp then
            self:stop()
            return
        end

        self:_tick(now, dt)
    end)
end

function NPCController:stop()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
end

-- ── Per-frame state machine ───────────────────────────────────────────────────
function NPCController:_tick(now, dt)
    local state = self._state

    -- ── IDLE_ACTION: wait for emote to finish ──
    if state == STATE.IDLE_ACTION then
        if now >= self._idleActionEnd then
            self._state       = STATE.IDLE
            self._nextIdleAction = self:_randTime(10, 22)
            self:_playIdle()
        end
        return
    end

    -- ── LOOK_PLAYER: turn to face nearby player ──
    if state == STATE.LOOK_PLAYER then
        local targetHRP, dist = self:_nearestPlayer()
        if targetHRP and dist < SETTINGS.LOOK_AT_RANGE then
            self:_faceToward(targetHRP.Position, dt, 4)
        else
            -- Player left range → back to idle
            self._state = STATE.IDLE
            self:_playIdle()
        end

        -- Still allow idle-action interrupts while looking
        if now >= self._nextIdleAction then
            self._state = STATE.IDLE_ACTION
            self:_playIdleAction()
        end
        return
    end

    -- ── WANDER: move toward target ──
    if state == STATE.WANDER then
        if not self._npcDef.wander then
            self._state = STATE.IDLE
            self:_playIdle()
            return
        end

        local target = self._wanderTarget
        if target then
            local pos  = self._hrp.Position
            local diff = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
            local dist = diff.Magnitude

            if dist < 1.5 or now > self._wanderTimeout then
                -- Arrived or timed out
                self._humanoid:MoveTo(self._hrp.Position)
                self._state = STATE.IDLE
                self._nextWander = self:_randTime(4, 10)
                self:_playIdle()
            else
                self:_faceToward(target, dt, 5)
                -- Check for nearby player; interrupt wander to look at them
                local playerHRP, pDist = self:_nearestPlayer()
                if playerHRP and pDist < SETTINGS.LOOK_AT_RANGE * 0.6 then
                    self._humanoid:MoveTo(self._hrp.Position)
                    self._state = STATE.LOOK_PLAYER
                    self:_playIdle()
                end
            end
        end
        return
    end

    -- ── IDLE: check for transitions ──
    -- Priority 1: player nearby → look at them
    local playerHRP, pDist = self:_nearestPlayer()
    if playerHRP and pDist < SETTINGS.LOOK_AT_RANGE then
        self._state = STATE.LOOK_PLAYER
        return
    end

    -- Priority 2: time for a random idle action
    if now >= self._nextIdleAction then
        self._state = STATE.IDLE_ACTION
        self:_playIdleAction()
        return
    end

    -- Priority 3: time to wander
    if self._npcDef.wander and now >= self._nextWander then
        local target = self:_pickWanderTarget()
        self._wanderTarget  = target
        self._wanderTimeout = now + 12   -- give up after 12 seconds
        self._humanoid:MoveTo(target)
        self._state = STATE.WANDER
        self:_playWalk()
    end
end

-- ── LOD helper: pause/resume AI ───────────────────────────────────────────────
function NPCController:setPaused(paused)
    if paused then
        self:stop()
        if self._humanoid then
            self._humanoid:MoveTo(self._hrp.Position)
        end
    else
        self:start()
    end
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────
function NPCController:cleanup()
    self._active = false
    self:stop()
    if self._animCtrl then
        self._animCtrl:cleanup()
    end
end

return NPCController
