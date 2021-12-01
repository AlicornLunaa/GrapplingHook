AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:PhysicsCollide(collision, collider)
    -- This function will embed the hook into a wall if it hits fast enough
    if !self.parent and !self.attached and collision.Speed >= self.requiredSpeed then
        -- Ready for attachment
        self.parent = collision.HitEntity
        self.collision = collision

        -- Feedback
        self:EmitSound("phx/epicmetal_hard7.wav")
        self.launcher:EmitSound("common/stuck1.wav", 120)
    end
end