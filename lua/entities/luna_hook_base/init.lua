-- Includes
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

    self.hookAttached = false -- To draw rope or not
    self.hookActive = false -- To use physics calculations or not
    self.lastDistance = 1
    self.targetDistance = 1

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass(100)
        phys:Wake()
    end
end