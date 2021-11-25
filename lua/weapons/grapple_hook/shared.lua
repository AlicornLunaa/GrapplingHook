-- Swep info
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Left click to launch a hook.\nOnce the hook is taken, hold left click to retract and right click to expand. R to detach the hook."

SWEP.Spawnable = true
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- Swep config
SWEP.launchForce = 150000
SWEP.pullForce = 10

-- Sounds
local firingSound = Sound("garrysmod/balloon_pop_cute.wav")

-- Functions
function SWEP:Think()
    -- Serverside code
    if SERVER then
        -- Get variables
        local reeling = self:GetNWBool("reeling", false)
        local _hook = self:GetNWEntity("hook")

        -- Pull the player AND hook together
        if reeling then
            if _hook:IsValid() and self:GetOwner():IsValid() then
                -- Get directions for hooks
                local ownerToHook = (_hook:GetPos() - self:GetOwner():GetPos()):GetNormalized()
                local hookToOwner = (self:GetOwner():GetPos() - _hook:GetPos()):GetNormalized()

                -- Forces for hooks and player
                self:GetOwner():SetVelocity(ownerToHook * self.pullForce)
                _hook:GetPhysicsObject():ApplyForceCenter(hookToOwner * self.pullForce * 10)
            end

            -- Check for a continuous hold of the reel button
            if not self:GetOwner():KeyDown(IN_ATTACK) then
                -- Primary attack was let go, stop reeling
                self:SetNWBool("reeling", false)
            end
        end
    end
end

function SWEP:Deploy()
    -- This function will create the hook at the end

end

function SWEP:Holster()

end

function SWEP:Reload()
    -- Serverside code
    if SERVER then
        -- Reload detaches the hook if its deployed
        local isLaunched = self:GetNWBool("launched", false)
        local _hook = self:GetNWEntity("hook")

        if isLaunched then
            -- Hook exists, remove it after 3 seconds and also detach it within code
            self:SetNWBool("launched", false)

            timer.Simple(3, function()
                if _hook:IsValid() then
                    _hook:Remove()
                end
            end )
        end
    end
end

function SWEP:PrimaryAttack()
    -- This function will launch the hook and wait for it to grapple
    -- or it will reel the grapple in depending on the status of it
    -- Store data in variables
    local lookDirection = self:GetOwner():GetAimVector()
    local isLaunched = self:GetNWBool("launched", false)

    -- Run functions
    if SERVER then
        -- Serverside code
        if isLaunched then
            -- Hook already launched, reel it in if its hooked.
            self:SetNWBool("reeling", true)
        else
            -- Hook has not been launched, launch it.
            self:EmitSound(firingSound)

            -- Spawn the hook at hand and launch it in the look direction
            local attachmentPoint = self:GetOwner():GetAttachment(5)
            local ent = ents.Create("hook")
            ent:SetPos(attachmentPoint.Pos)
            ent:SetAngles(attachmentPoint.Ang)
            ent:Spawn()

            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            self:SetNWEntity("hook", ent)
            self:SetNWBool("launched", true)
        end
    else
        -- Clientside code

    end
end

function SWEP:SecondaryAttack()

end

function SWEP:ViewModelDrawn()

end