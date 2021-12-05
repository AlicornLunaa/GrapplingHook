include("shared.lua")

function ENT:CreateModels()
    -- This function will create the clientside models to
    -- create the hook
    -- Hook model
    local ent = ClientsideModel("models/props_junk/meathook001a.mdl", RENDERGROUP_OPAQUE)

    -- Transform the hook
    local matrix = Matrix()
    matrix:Scale(Vector(0.3, 0.3, 0.3))
    ent:EnableMatrix("RenderMultiply", matrix)
    ent:SetNoDraw(true)

    self.hookMdl = ent

    -- Base model
    ent = ClientsideModel("models/Items/combine_rifle_ammo01.mdl", RENDERGROUP_OPAQUE)

    -- Transform the hook
    matrix = Matrix()
    matrix:Scale(Vector(0.5, 0.5, 0.5))
    ent:EnableMatrix("RenderMultiply", matrix)
    ent:SetNoDraw(true)

    self.baseMdl = ent
end

function ENT:DebugCollider()
    -- This function will draw the shape of the collider
    if !self.vertices then return end
    for c, collider in pairs(self.vertices) do
        for i, p1 in pairs(collider) do
            for j, p2 in pairs(collider) do
                if i == j then continue end
                render.DrawLine(self:LocalToWorld(p1), self:LocalToWorld(p2), Color(255 - c * 50, 50 + c * 50, 0 + c * 50))
            end
        end
    end
end

function ENT:Draw()
    -- Make sure models exist
    if !self.baseMdl or !self.baseMdl:IsValid() then self:CreateModels() end

    -- Draw the model
    self.baseMdl:SetRenderOrigin(self:LocalToWorld(Vector(0, 0, 3)))
    self.baseMdl:SetRenderAngles(self:GetAngles())
    self.baseMdl:DrawModel()

    -- Draw the hooks rotated around
    local pos = Vector(0, -1.75, 6)
    local ang = Angle(180, 0, 0)

    for i = 1, 3 do
        self.hookMdl:SetRenderOrigin(self:LocalToWorld(pos))
        self.hookMdl:SetRenderAngles(self:LocalToWorldAngles(ang))
        self.hookMdl:SetupBones()
        self.hookMdl:DrawModel()

        -- ROtate the angle some more
        ang:RotateAroundAxis(Vector(0, 0, 1), 120)
        pos:Rotate(Angle(0, 120, 0))
    end

    self:DrawRope()
end

function ENT:OnRemove()
    -- This function removes the fake models, as a garbage collection
    if self.baseMdl:IsValid() then self.baseMdl:Remove() end
    if self.hookMdl:IsValid() then self.hookMdl:Remove() end
end