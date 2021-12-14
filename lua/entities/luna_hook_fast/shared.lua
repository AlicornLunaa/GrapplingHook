-- Entity information
ENT.Base = "luna_hook_sticky"
ENT.PrintName = "Fast hook"

-- Render config
ENT.attachPosition = Vector(0, 0, 18)
ENT.positionOffset = Vector(8, -0.5, 0)
ENT.angleOffset = Angle(90, 180, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.165
ENT.lerp = 10000
ENT.cableMaterial = Material("cable/cable2")

-- Functions
function ENT:ForceCalculation(physObj)
    -- This function will add the velocities to move the players together
    if !SERVER then return end

    -- Get locations and directions
    local hookPosition = self:LocalToWorld(self.attachPosition)
    local ownerPosition = self.launcher:GetPos()
    local ownerToHook = (hookPosition - ownerPosition):GetNormalized()

    -- Apply forces
    self.launcher:SetVelocity(ownerToHook * self.pullForce * 125)
end