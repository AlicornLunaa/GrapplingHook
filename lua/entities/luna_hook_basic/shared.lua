-- Entity information
ENT.Base = "luna_hook_base"
ENT.PrintName = "Basic hook"

-- Render config
ENT.attachPosition = Vector(0, 0, 0)
ENT.positionOffset = Vector(-8, -0.5, 0)
ENT.angleOffset = Angle(90, 0, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.12
ENT.lerp = 1000
ENT.cableMaterial = Material("cable/cable2")

ENT.vertices = {
    {
        Vector(-1, -0.4, -0.5),
        Vector(-1.1, -1.3, 1),
        Vector(-1, -1.5, 8),
        Vector(-0.2, -0.7, 10),
        Vector(-0.2, -0.7, 12),
    },
    {
        Vector(0, -1, 11),
        Vector(0, -2, 11.5),
        Vector(-0.5, -2, 12),
        Vector(-0.3, -0.5, 12),
        Vector(0, -0.5, 12.5),
        Vector(0, 0.5, 12),
        Vector(0, -3, 12.5),
        Vector(0.3, -3, 12.5),
        Vector(-0.3, -3, 12.5),
        Vector(0, -2, 11.5),
        Vector(0.5, -2, 12),
        Vector(0.3, -0.5, 12),
    },
    {
        Vector(0, -3, 12.5),
        Vector(0, -4, 11.5),
        Vector(0, -2, 11.5),
        Vector(0, -4.2, 10.5),
        Vector(-0.3, -3, 12.5),
        Vector(-0.3, -4, 11.5),
        Vector(-0.3, -2, 11.5),
        Vector(-0.3, -4.2, 10.5),
        Vector(0.3, -3, 12.5),
        Vector(0.3, -4, 11.5),
        Vector(0.3, -2, 11.5),
        Vector(0.3, -4.2, 10.5),
    },
    {
        Vector(0.3, -4.2, 10.5),
        Vector(0.1, -4, 9.5),
        Vector(0.1, -3.5, 9.5),
        Vector(0.3, -3.4, 11),
        Vector(-0.3, -4.2, 10.5),
        Vector(-0.1, -4, 9.5),
        Vector(-0.1, -3.5, 9.5),
        Vector(-0.3, -3.4, 11),
    }
}

-- Functions
function ENT:CreateCollisionMesh()
    -- This function will take the original outstanding vertices and
    -- rotate them accordingly to fit the entire model.
    -- Code is bad, dont care
    local base = table.Copy(self.vertices[1])
    for i, pos in pairs(base) do
        for k = 1, 7 do
            local newPos = Vector(pos)
            pos:Rotate(Angle(0, 45, 0))
            table.insert(self.vertices[1], newPos)
        end
    end

    for i = 2, 4 do
        base = table.Copy(self.vertices[i])

        for k = 1, 3 do
            local newBranch = table.Copy(base)

            for x, pos in pairs(newBranch) do
                local newPos = Vector(pos)
                newPos:Rotate(Angle(0, 120 * k, 0))
                newBranch[x] = newPos
            end

            table.insert(self.vertices, newBranch)
        end
    end
end

function ENT:Initialize()
    self:CreateCollisionMesh()

    if SERVER then
        -- Initialize model data
        self:SetModel("models/Items/combine_rifle_ammo01.mdl")
        self:PhysicsInitMultiConvex(self.vertices)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:EnableCustomCollisions(true)
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
end