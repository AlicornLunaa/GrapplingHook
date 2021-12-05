-- Entity information
ENT.Base = "luna_hook_sticky"
ENT.PrintName = "Springy hook"

-- Render config
ENT.attachPosition = Vector(0, 0, 18)
ENT.positionOffset = Vector(8, -0.5, 0)
ENT.angleOffset = Angle(90, 180, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.02
ENT.lerp = 1000
ENT.cableMaterial = Material("cable/cable2")

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
    local distanceSign = luna.sign(currentDistance - self.lastDistance)
    self.lastDistance = currentDistance

    -- Apply forces
    local compensation = math.Clamp(self.launcher:GetVelocity():Length(), -self.lerp, self.lerp) * distanceSign
    local force = currentDistance - self.targetDistance + compensation

    self.launcher:SetVelocity(ownerToHook * self.pullForce * force)
    physObj:ApplyForceCenter(ownerToHook * self.pullForce * force * -1000)
end