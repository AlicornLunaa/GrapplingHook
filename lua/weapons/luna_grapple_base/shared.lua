-- Swep info
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Primary to launch and reel\nSecondary to expand\nReload to detach"

SWEP.Spawnable = false
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
SWEP.reelSpeed = 4
SWEP.hookClass = "luna_hook_basic"
SWEP.weaponColor = Color(255, 255, 255)

-- Functions
function SWEP:Think()
    -- Serverside code
    if SERVER then
        -- Only run when the game is running
        if !self:IsValid() then return end
        if game.SinglePlayer() and gameUIVisible then return end

        -- Get variables
        local reeling = self:GetNWBool("reeling", false)
        local expanding = self:GetNWBool("expanding", false)

        -- Reduce the targeted distance
        if reeling and self:GetOwner():IsValid() then
            self.hook.targetDistance = math.Clamp(self.hook.targetDistance - self.reelSpeed, 1, self.hook.maxDistance)

            -- Check for a continuous hold of the reel button
            if !self:GetOwner():KeyDown(IN_ATTACK) then
                -- Primary attack was let go, stop reeling
                self:SetNWBool("reeling", false)
                self:StopSound("reel_sound")
            end
        end

        -- Increase the targeted distance
        if expanding and self:GetOwner():IsValid() then
            self.hook.targetDistance = math.Clamp(self.hook.targetDistance + self.reelSpeed, 1, self.hook.maxDistance)

            -- Check for a continuous hold of the reel button
            if !self:GetOwner():KeyDown(IN_ATTACK2) then
                -- Secondary attack was let go, stop expanding
                self:SetNWBool("expanding", false)
                self:StopSound("reel_sound")
            end
        end
    end
end

function SWEP:Initialize()
    -- Create model to render on gun
    if CLIENT then
        local ent = ents.CreateClientside(self.hookClass)
        ent:SetNoDraw(true)

        self.hookMdl = ent
    end
end

function SWEP:Cleanup()
    -- Detaches the hook
    if !SERVER then return end
    if !self.hook or !self.hook.hookAttached then return end

    -- Play sounds
    self:EmitSound("release_sound")
    self:StopSound("reel_sound")
    self.hook:SetHookAttached(false)

    -- Remove hook after 3 seconds
    timer.Simple(3, function()
        if self.hook and self.hook:IsValid() then
            self.hook:Remove()
        end
    end )
end

function SWEP:Reload()
    -- Reload detaches the hook if its deployed
    self:Cleanup()
end

function SWEP:PrimaryAttack()
    -- This function will launch the hook and wait for it to grapple
    -- or it will reel the grapple in depending on the status of it
    -- Store data in variables
    if !self:GetOwner():IsValid() then return end

    -- Save data
    local lookDirection = self:GetOwner():GetAimVector()

    -- Run functions
    if self.hook and self.hook.hookAttached then
        -- Hook already launched, reel it in if its hooked.
        self:SetNWBool("reeling", true)
        self:EmitSound("reel_sound")
    else
        -- Hook has not been launched, launch it.
        self:SetNextPrimaryFire(CurTime() + 0.2)
        self:EmitSound("firing_sound")
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

        -- Serverside only
        if SERVER then
            -- Spawn the hook at hand and launch it in the look direction
            local viewModel = self:GetOwner():GetViewModel()
            local attachmentPoint = self:GetAttachment(1)

            local ent = ents.Create(self.hookClass)
            ent:SetPos(attachmentPoint.Pos + viewModel:GetForward() * ent.positionOffset.x)
            ent:SetAngles(viewModel:LocalToWorldAngles(ent.angleOffset))
            ent:Spawn()
            ent:SetHookLauncher(self:GetOwner())
            ent:SetColor(self.weaponColor)
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            self.hook = ent
            self:SetNWEntity("hook", ent)

            -- Setup the launch function to activate once the key is released
            hook.Add("KeyRelease", "hookLaunchActive", function(ply, key)
                if key == IN_ATTACK and self:IsValid() and self:GetOwner():IsValid() then
                    local distance = self:GetOwner():GetPos():Distance(ent:GetPos())

                    ent.lastDistance = math.Clamp(distance, 1, ent.maxDistance)
                    ent.targetDistance = math.Clamp(distance, 1, ent.maxDistance)
                    ent:SetHookAttached(true)
                end

                hook.Remove("KeyRelease", "hookLaunchActive")
            end )
        end
    end
end

function SWEP:SecondaryAttack()
    -- This function will cause the hook to expand
    if SERVER and self.hook.hookAttached then
        self:SetNWBool("expanding", true)
        self:EmitSound("reel_sound")
    end
end

function SWEP:ViewModelDrawn(ent)
    if CLIENT then
        -- Draw the beam for the viewmodel
        -- Get networked information
        if !self:GetOwner():IsValid() or !ent:IsValid() or !self.hookMdl:IsValid() then return end

        -- Save data
        local vm = self:GetOwner():GetViewModel()
        local attachmentPoint = vm:GetAttachment(1)
        local _hook = self:GetNWEntity("hook", NULL)

        ent:SetColor(self.weaponColor)
        self.hookMdl:SetColor(self.weaponColor)

        -- Get location to attach to
        if !_hook:IsValid() or !_hook:GetHookAttached() then
            -- Draw hook on the gun because it's not launched
            cam.Start3D()
                local pos, ang = LocalToWorld(self.hookMdl.positionOffset, self.hookMdl.angleOffset + Angle(-10, 90, 90), attachmentPoint.Pos, attachmentPoint.Ang)
                self.hookMdl:SetRenderOrigin(pos)
                self.hookMdl:SetRenderAngles(ang)
                self.hookMdl:SetPos(pos)
                self.hookMdl:SetAngles(ang)
                self.hookMdl:DrawModel()
            cam.End3D()
        end
    end
end

function SWEP:DrawWorldModel(flags)
    if CLIENT then
        -- Draw the gun and rope to the hook
        self:DrawModel(flags)

        -- Get networked information
        local attachmentPoint = self:GetAttachment(1)

        -- Get location to attach to
        if self.hookMdl:IsValid() and attachmentPoint then
            -- Draw the hook since there is none launched
            local pos, ang = LocalToWorld(self.hookMdl.positionOffset, self.hookMdl.angleOffset, attachmentPoint.Pos, attachmentPoint.Ang)
            self.hookMdl:SetRenderOrigin(pos)
            self.hookMdl:SetRenderAngles(ang)
            self.hookMdl:SetPos(pos)
            self.hookMdl:SetAngles(ang)
            self.hookMdl:DrawModel()
        end
    end
end

function SWEP:Holster()
    -- Weapon was holstered, fix colors
    self:Cleanup()

    if self:IsValid() and self:GetOwner():IsValid() and self:GetOwner():GetViewModel():IsValid() then
        self:GetOwner():GetViewModel():SetColor(Color(255, 255, 255))
    end

    return true
end

function SWEP:OnRemove()
    if CLIENT and self.hookMdl:IsValid() then self.hookMdl:Remove() end
    self:Holster()
end