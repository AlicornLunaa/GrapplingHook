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
SWEP.maxDistance = 100000
SWEP.reelSpeed = 2
SWEP.pullForce = 0.08
SWEP.maxLerp = 1000

-- Sounds
local firingSound = Sound("garrysmod/balloon_pop_cute.wav")

-- Functions
function SWEP:Think()
    -- Serverside code
    if SERVER then
        -- Get variables
        local launched = self:GetNWBool("launched", false)
        local reeling = self:GetNWBool("reeling", false)
        local expanding = self:GetNWBool("expanding", false)
        local _hook = self:GetNWEntity("hook")

        -- Pull the player AND hook together
        if launched and _hook:IsValid() and self:GetOwner():IsValid() then
            -- Get directions for hooks
            local ownerToHook = (_hook:GetPos() - self:GetOwner():GetPos()):GetNormalized()
            local hookToOwner = (self:GetOwner():GetPos() - _hook:GetPos()):GetNormalized()

            -- Forces for hooks and player
            local distanceForce = self:GetOwner():GetPos():Distance(_hook:GetPos()) - self:GetNWFloat("distance", 1) + math.Clamp(self:GetOwner():GetVelocity():Length(), -self.maxLerp, self.maxLerp)
            self:GetOwner():SetVelocity(ownerToHook * self.pullForce * distanceForce)
            _hook:GetPhysicsObject():ApplyForceCenter(hookToOwner * self.pullForce * 100 * distanceForce)
        end

        -- Reduce the targeted distance
        if reeling then
            local distance = self:GetNWFloat("distance", 1)
            self:SetNWFloat("distance", math.Clamp(distance - self.reelSpeed, 1, self.maxDistance))

            -- Check for a continuous hold of the reel button
            if not self:GetOwner():KeyDown(IN_ATTACK) then
                -- Primary attack was let go, stop reeling
                self:SetNWBool("reeling", false)
            end
        end

        -- Increase the targeted distance
        if expanding then
            local distance = self:GetNWFloat("distance", 1)
            self:SetNWFloat("distance", math.Clamp(distance + self.reelSpeed, 1, self.maxDistance))

            -- Check for a continuous hold of the reel button
            if not self:GetOwner():KeyDown(IN_ATTACK2) then
                -- Secondary attack was let go, stop expanding
                self:SetNWBool("expanding", false)
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

            self:SetNWFloat("distance", math.Clamp(self:GetOwner():GetPos():Distance(ent:GetPos()), 1, self.maxDistance))
            self:SetNWEntity("hook", ent)
            self:SetNWBool("launched", true)
        end
    else
        -- Clientside code

    end
end

function SWEP:SecondaryAttack()
    -- This function will cause the hook to expand
    -- Get data
    local isLaunched = self:GetNWBool("launched", false)

    -- Serverside code
    if SERVER and isLaunched then
        self:SetNWBool("expanding", true)
    end
end

function SWEP:ViewModelDrawn()

end