-- Entity information
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Basic hook"
ENT.Author = "AlicornLunaa"

ENT.Spawnable = false
ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

ENT.attachPosition = Vector(0, 0, 0)
ENT.positionOffset = Vector(-8, -0.5, 0)
ENT.angleOffset = Angle(90, 0, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.12
ENT.lerp = 1000
ENT.cableMaterial = Material("cable/cable2")

-- Utility functions
local function sign(a)
    -- This function returns a -1 0 or 1 depending on the sign on the variable supplied
    if a < 0 then
        return -1
    elseif a > 0 then
        return 1
    else
        return 0
    end
end

-- Shared functions
-- Setters
function ENT:SetHookLauncher(ply)
    -- Sets the launcher of the hook
    if !ply:IsValid() then return end
    self.launcher = ply
    self:SetNWEntity("launcher", ply)
end

function ENT:SetHookAttached(attached)
    -- Sets the value of the attachment status
    self.hookAttached = attached
    self:SetNWBool("hookAttached", attached)
end

-- Getters
function ENT:GetHookLauncher()
    -- Gets the launcher of the hook
    return self:GetNWEntity("launcher", NULL)
end

function ENT:GetHookAttached()
    return self:GetNWBool("hookAttached", false)
end

-- Functions
function ENT:ForceCalculation(physObj)
    -- This function will add the velocities to move the players together
    if !SERVER then return end

    -- Get locations and directions
    local hookPosition = self:LocalToWorld(self.attachPosition)
    local ownerPosition = self.launcher:GetPos()
    local ownerToHook = (hookPosition - ownerPosition):GetNormalized()

    -- Get the distance to hold the player in at
    local currentDistance = self.launcher:GetPos():Distance(hookPosition)
    local distanceSign = sign(currentDistance - self.lastDistance)
    self.lastDistance = currentDistance

    -- Apply forces
    local compensation = math.Clamp(self.launcher:GetVelocity():Length(), -self.lerp, self.lerp) * distanceSign
    local force = math.max(currentDistance - self.targetDistance + compensation, 0)

    self.launcher:SetVelocity(ownerToHook * self.pullForce * force)
    physObj:ApplyForceCenter(ownerToHook * self.pullForce * force * -100)
end

function ENT:Think()
    -- This function runs all the hook physics calculations
    -- Error checking
    if !SERVER then return end
    if !self.launcher or !self.launcher:IsValid() then return end
    if game.SinglePlayer() and gameUIVisible then return end

    -- Run force calculations
    local physObj = self:GetPhysicsObject()

    -- Keep the player in by the specificed distance
    if physObj:IsValid() and self.hookAttached then
        self:ForceCalculation(physObj)
    end
end