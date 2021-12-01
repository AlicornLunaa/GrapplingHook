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
        phys:EnableGravity(false)
        phys:Wake()
    end
end