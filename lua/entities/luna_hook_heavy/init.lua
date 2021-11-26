AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Initialize model data
    self:SetModel("models/Items/combine_rifle_ammo01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:DrawShadow(false)

    self.requiredSpeed = 100
    self.parent = nil
    self.attached = false
    self.collision = nil

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass(1000)
        phys:Wake()
    end
end

function ENT:Think()
    if self.parent and !self.attached then
        -- Parent exists but not attached, weld it
        local direction = self:GetVelocity():GetNormalized()
        self:SetPos(self.collision.HitPos + direction * 15)
        self:SetAngles(self.collision.HitNormal:Angle() + Angle(90, 0, 0))

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

    if self.attached and !self.parent then
        self.parent = false
        self.attached = false
    end
end

function ENT:PhysicsCollide(collision, collider)
    -- This function will embed the hook into a wall if it hits fast enough
    if !self.parent and !self.attached and collision.Speed >= self.requiredSpeed then
        -- Ready for attachment
        self.parent = collision.HitEntity
        self.collision = collision

        -- Feedback
        self:EmitSound("phx/epicmetal_hard7.wav")
        self:GetOwner():EmitSound("common/stuck1.wav", 120)
    end
end