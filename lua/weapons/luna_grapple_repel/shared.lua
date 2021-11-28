-- Swep info
SWEP.Base = "luna_grapple_base"
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Primary to launch\nReload to detach"
SWEP.Spawnable = true

-- Swep config
SWEP.launchForce = 85000
SWEP.maxDistance = 100000
SWEP.reelSpeed = 4
SWEP.pullForce = 0.12
SWEP.maxLerp = 1000
SWEP.cableMaterial = Material("cable/cable2")
SWEP.hookClass = "luna_hook_basic"
SWEP.weaponColor = Color(255, 0, 255)

-- Utility functions
local function sign(a)
    -- This function returns a -1 0 or 1 depending on the sign on the variable supplied
    if a < 0 then
        return -1
    elseif a > 0 then
        return 1
    else
        return 0
    end
end

-- Functions
function SWEP:Think()
    -- Serverside code
    if SERVER then
        -- Only run when the game is running
        if game.SinglePlayer() and gameUIVisible then return end

        -- Get variables
        local launched = self:GetNWBool("launched", false)
        local _hook = self:GetNWEntity("hook")

        -- Pull the player AND hook together
        if launched and _hook:IsValid() and self:GetOwner():IsValid() then
            -- Get directions for hooks
            local hookPos = _hook:LocalToWorld(_hook.attachPosition)
            local ownerToHook = (hookPos - self:GetOwner():GetPos()):GetNormalized()
            local hookToOwner = (self:GetOwner():GetPos() - hookPos):GetNormalized()

            -- Get a variable to check if theyre moving towards or away the hook
            local currentDistance = self:GetOwner():GetPos():Distance(hookPos)
            local deltaDistance = currentDistance - self:GetNWFloat("lastDistance", 1)
            local distanceSign = sign(deltaDistance)
            self:SetNWFloat("lastDistance", currentDistance)
            self:SetNWFloat("distance", currentDistance + 100)

            -- Forces for hooks and player
            local distanceForce = math.max(currentDistance - self:GetNWFloat("distance", 1) + math.Clamp(self:GetOwner():GetVelocity():Length(), -self.maxLerp, self.maxLerp) * distanceSign, 0)
            self:GetOwner():SetVelocity(ownerToHook * self.pullForce * distanceForce)
            _hook:GetPhysicsObject():ApplyForceCenter(hookToOwner * self.pullForce * 100 * distanceForce)
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
    if !isLaunched then
        -- Hook has not been launched, launch it.
        self:EmitSound("firing_sound")
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

        self:SetNWBool("ropeAttached", true)

        -- Serverside only
        if SERVER then
            -- Spawn the hook at hand and launch it in the look direction
            local viewModel = self:GetOwner():GetViewModel()
            local attachmentPoint = self:GetAttachment(1)
            local ent = ents.Create(self.hookClass)
            ent:SetPos(attachmentPoint.Pos + viewModel:GetForward() * ent.positionOffset.x)
            ent:SetAngles(viewModel:LocalToWorldAngles(ent.angleOffset))
            ent:SetOwner(self:GetOwner())
            ent:Spawn()
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            self:SetNWEntity("hook", ent)

            -- Setup the launch function to activate once the key is released
            hook.Add("KeyRelease", "hookLaunchActive", function(ply, key)
                if key == IN_ATTACK then
                    local distance = self:GetOwner():GetPos():Distance(ent:GetPos())
                    self:SetNWFloat("lastDistance", distance)
                    self:SetNWFloat("distance", math.Clamp(distance, 1, self.maxDistance))
                    self:SetNWBool("launched", true)

                    hook.Remove("KeyRelease", "hookLaunchActive")
                end
            end )
        end
    end
end

function SWEP:SecondaryAttack()
end