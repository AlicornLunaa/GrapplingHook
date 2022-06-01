-- Entity information
ENT.Base = "luna_hook_sticky"
ENT.PrintName = "Heavy hook"

-- Render config
ENT.attachPosition = Vector(0, 0, 0)
ENT.positionOffset = Vector(-8, -0.5, 0)
ENT.angleOffset = Angle(90, 0, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.12
ENT.lerp = 1000
ENT.cableMaterial = Material("cable/cable2")
ENT.requiredSpeed = 100

-- Functions
function ENT:HookAttach()
    -- This function will attach the hook to any surface it touches
    if !SERVER then return end

    if self.parent and !self.attached then
        -- Parent exists but not attached, weld it
        local direction = self:GetVelocity():GetNormalized()
        self:SetPos(self.lastCollision.HitPos + direction * 15)
        self:SetAngles(self.lastCollision.HitNormal:Angle() + Angle(90, 0, 0))

        -- Different constraints based on different objects
        if self.parent:IsPlayer() then
            -- Its a player
            self:SetParent(self.parent)
        else
            -- Its a prop/entity
            constraint.Weld(self, self.parent, 0, 0, 0, 1, true)
        end

        -- Finish attach
        self.attached = true
    end

    -- Detach if parents are dead :(
    if self.attached and !self.parent then
        self.parent = false
        self.attached = false
    end
end