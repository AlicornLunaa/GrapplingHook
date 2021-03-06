AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Server functions
function ENT:Initialize()
    -- Initialize model data
    self:SetModel("models/Items/combine_rifle_ammo01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:DrawShadow(false)

    self.hookAttached = false
    self.hookActive = false
    self.lastDistance = 1
    self.targetDistance = 1

    self.parent = nil
    self.attached = false
    self.lastCollision = nil

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass(100)
        phys:Wake()
    end
end

function ENT:PhysicsCollide(collision, collider)
    -- This function makes the plunger stick when it hits something
    if !self.launcher or !self.launcher:IsValid() then return end

    if !self.parent and self.launcher != collision.HitEntity then
        -- Only attach if there is no parent already attached
        self.parent = collision.HitEntity
        self.lastCollision = collision

        luna.playSound("garrysmod/balloon_pop_cute.wav", self, false, nil)
        luna.playSound("common/stuck1.wav", self, true, self.launcher)
    end
end