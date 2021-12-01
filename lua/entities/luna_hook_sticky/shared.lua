-- Entity information
ENT.Base = "luna_hook_base"
ENT.PrintName = "Sticky hook"

-- Render config
ENT.attachPosition = Vector(0, 0, 18)
ENT.positionOffset = Vector(8, -0.5, 0)
ENT.angleOffset = Angle(90, 180, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.12
ENT.lerp = 1000
ENT.cableMaterial = Material("cable/cable2")

-- Functions
function ENT:HookAttach()
    -- This function will attach the hook to any surface it touches
    if self.parent and !self.attached then
        -- Parent exists but not attached, weld it
        self:SetPos(self.lastCollision.HitPos)
        self:SetAngles(self.lastCollision.HitNormal:Angle() + Angle(-90, 0, 0))

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

    -- Detach is parents are dead :(
    if self.attached and !self.parent then
        self.parent = false
        self.attached = false
    end
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

    -- Make sticky hook attach
    self:HookAttach()

    -- Think faster
    self:NextThink(CurTime())
    return true
end