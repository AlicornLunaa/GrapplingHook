ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Zipline start"
ENT.Author = "AlicornLunaa"
ENT.Purpose = "Entity to serve as the start point of the zipline"

ENT.Spawnable = false
ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

ENT.cableMaterial = Material("cable/cable2")

-- Shared functions
-- Setters
function ENT:SetHookLauncher(ply)
    -- Sets the launcher of the hook
    if !ply:IsValid() then return end
    self.launcher = ply
    self:SetNWEntity("launcher", ply)
end

-- Getters
function ENT:GetHookLauncher()
    -- Gets the launcher of the hook
    return self:GetNWEntity("launcher", NULL)
end

-- Functions
function ENT:ForceCalculation(physObj, _hook)
    -- This function will add the velocities to move the players together
    if !SERVER then return end

    -- Get locations and directions
    local startPosition = self:LocalToWorld(Vector(0, 0, 52))
    local hookPosition = _hook:LocalToWorld(_hook.attachPosition)
    local interpPosition = LerpVector(self.distance, startPosition, hookPosition)
    local playerPosition = self.launcher:GetPos() + Vector(0, 0, 70)
    local forceDirection = (interpPosition - playerPosition):GetNormalized()

    self.playerDistance = interpPosition:DistToSqr(playerPosition)

    -- Apply forces
    local compensation = (self.launcher:GetVelocity() * 0.075) + Vector(0, 0, -10)

    self.launcher:SetVelocity(forceDirection * 50 - compensation)
    physObj:ApplyForceCenter(forceDirection * 50 - compensation * -1)
end

function ENT:Think()
    -- This function runs all the hook physics calculations
    -- Error checking
    if !SERVER then return end
    if !self.launcher or !self.launcher:IsValid() then return end
    if game.SinglePlayer() and gameUIVisible then return end

    -- Run force calculations
    local physObj = self:GetPhysicsObject()
    local _hook = self:GetNWEntity("hook", NULL)
    local _wep = self:GetNWEntity("wep", NULL)

    -- Start changing values
    self.distance = math.Clamp(self.distance + 0.002, 0, 1)

    if _wep:IsValid() and self.distance >= 1 and self.playerDistance < 300 * 300 then
        _wep:Cleanup()
    end

    -- Keep the player in by the specificed distance
    if physObj:IsValid() and _hook:IsValid() and _hook.attached and _hook.zipActive then
        self:ForceCalculation(physObj, _hook)
    end

    -- Think faster
    self:NextThink(CurTime())
    return true
end