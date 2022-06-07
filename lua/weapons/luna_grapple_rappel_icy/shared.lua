-- Swep info
SWEP.Base = "luna_grapple_rappel"
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Primary to launch\nReload to detach"
SWEP.Spawnable = true

-- Swep config
SWEP.launchForce = 150000
SWEP.reelSpeed = 4
SWEP.hookClass = "luna_hook_icy"
SWEP.weaponColor = Color(79, 137, 255)

-- Functions
function SWEP:SecondaryAttack()
    -- This function will cause the hook to expand
    if !SERVER then return end
    if !self.hook or !self.hook:IsValid() or !self.hook.hookAttached then return end
    if !self:GetOwner() then return end

    -- Expand the book
    local ply = self:GetOwner()
    luna.playSound("reel_sound", self, false, nil)
    self.direction = -1

    self.hook:HookDetach()
    self.hook.attached = true

    -- Create hook to wait for end
    hook.Add("KeyRelease", "hookExpandEnd" .. tostring(self.hook:EntIndex()), function(_ply, key)
        -- Error checking
        if _ply != ply then return end
        if key != IN_ATTACK2 then return end
        if !self:IsValid() or !self:GetOwner():IsValid() then return end

        -- Stop reel
        self.direction = 0
        luna.stopSound("reel_sound", self, nil)

        -- Stop listening for a release
        hook.Remove("KeyRelease", "hookExpandEnd" .. tostring(self.hook:EntIndex()))
    end )
end