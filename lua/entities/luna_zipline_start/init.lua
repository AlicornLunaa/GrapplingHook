AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_borealis/bluebarrel001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:DrawShadow(false)

    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    self.playerDistance = 0
    self.distance = 0

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
        phys:Wake()
    end
end