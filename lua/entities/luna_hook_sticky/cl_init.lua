include("shared.lua")

function ENT:CreateModels()
    -- This function will create the clientside models to
    -- create the hook
    -- Plunger model
    local ent = ClientsideModel("models/hunter/misc/shell2x2a.mdl", RENDERGROUP_OPAQUE)

    -- Transform the hook
    local matrix = Matrix()
    matrix:Scale(Vector(0.09, 0.09, 0.09))
    ent:EnableMatrix("RenderMultiply", matrix)
    ent:SetNoDraw(true)

    self.plungerMdl = ent

    -- Handle model
    ent = ClientsideModel("models/hunter/tubes/tube1x1x1.mdl", RENDERGROUP_OPAQUE)

    -- Transform the hook
    matrix = Matrix()
    matrix:Scale(Vector(0.04, 0.04, 0.3))
    ent:EnableMatrix("RenderMultiply", matrix)
    ent:SetNoDraw(true)

    self.handleMdl = ent
end

function ENT:Draw()
    -- Make sure models exist
    if !self.handleMdl or !self.handleMdl:IsValid() then self:CreateModels() end

    -- Draw the model
    self.handleMdl:SetRenderOrigin(self:LocalToWorld(Vector(0, 0, 3.9)))
    self.handleMdl:SetRenderAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
    self.handleMdl:DrawModel()

    -- Draw the plunger
    self.plungerMdl:SetRenderOrigin(self:LocalToWorld(Vector(0, 0, 0)))
    self.plungerMdl:SetRenderAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
    self.plungerMdl:DrawModel()
end


function ENT:OnRemove()
    -- This function removes the fake models, as a garbage collection
    self.handleMdl:Remove()
    self.plungerMdl:Remove()
end