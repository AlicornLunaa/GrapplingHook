include("shared.lua")

function ENT:CreateModels()
    -- Create the custom model
    local ent = ClientsideModel("models/props_junk/harpoon002a.mdl", RENDERGROUP_OPAQUE)

    local matrix = Matrix()
    matrix:Scale(Vector(1, 1, 1))
    ent:EnableMatrix("RenderMultiply", matrix)
    ent:SetNoDraw(true)

    self.tripodMdl = ent
end

function ENT:Draw()
    if !self.tripodMdl or !self.tripodMdl:IsValid() then self:CreateModels() end

    -- Draw the tripod rotated around
    local pos = Vector(9, 0, 0)
    local ang = Angle(80, 0, 0)

    for i = 1, 3 do
        self.tripodMdl:SetRenderOrigin(self:LocalToWorld(pos))
        self.tripodMdl:SetRenderAngles(self:LocalToWorldAngles(ang))
        self.tripodMdl:SetColor(self:GetColor())
        self.tripodMdl:SetupBones()
        self.tripodMdl:DrawModel()

        -- ROtate the angle some more
        ang:RotateAroundAxis(Vector(0, 0, 1), 120)
        pos:Rotate(Angle(0, 120, 0))
    end
end