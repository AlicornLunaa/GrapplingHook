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

    self.parent = nil
    self.attached = false
    self.lastCollision = nil

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass(100)
        phys:Wake()
    end
end

function ENT:Think()
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

    if self.attached and !self.parent then
        self.parent = false
        self.attached = false
    end
end

function ENT:PhysicsCollide(collision, collider)
    -- This function makes the plunger stick when it hits something
    if !self.parent then
        -- Only attach if there is no parent already attached
        self.parent = collision.HitEntity
        self.lastCollision = collision

        self:EmitSound("garrysmod/balloon_pop_cute.wav")
        self.parent:EmitSound("common/stuck1.wav", 120)
    end
end