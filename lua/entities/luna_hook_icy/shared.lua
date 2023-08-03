-- Entity information
ENT.Base = "luna_hook_basic"
ENT.PrintName = "Icy hook"

-- Functions
function ENT:HookAttach()
    -- This function will attach the hook to any surface it touches
    if !SERVER then return end

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
        self.attached = true
    end
end

function ENT:HookDetach()
    -- This function will detach the hook
    if !SERVER then return end

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(true)
        phys:Wake()
        self.attached = false
    end
end

function ENT:Think()
    -- This function runs all the hook physics calculations
    -- Error checking
    if !SERVER then return end
    if !self.launcher or !self.launcher:IsValid() then return end
    if game.SinglePlayer() and gameUIVisible then return end

    -- Run reel logic
    if self.selfReeling then
        -- Start changing values
        self.targetDistance = self.lastDistance + 100
    end

    -- Run force calculations
    local physObj = self:GetPhysicsObject()

    -- Keep the player in by the specificed distance
    if physObj:IsValid() and self.hookActive and self.hookAttached then
        self:ForceCalculation(physObj)
    end

    -- Make icy hook attach if released primary fire
    if self:GetHookActive() and !self.attached then
        self:HookAttach()
    end
    
    if !self:GetHookAttached() and self.attached then
        self:HookDetach()
    end

    -- Think faster
    self:NextThink(CurTime())
    return true
end