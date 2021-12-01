-- Swep info
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Primary to launch and reel\nSecondary to expand\nReload to detach"

SWEP.Spawnable = false
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

-- Ammo
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
    -- This function will reel the hook in depending on the direction given
    self:Reel()
end

function SWEP:Reel()
    -- This function starts reeling in the direction supplied
    -- Error checking
    if !SERVER then return end
    if game.SinglePlayer() and gameUIVisible then return end
    if !self.hook or !self.hook:IsValid() then return end
    if self.direction == 0 then return end

    -- Start changing values
    self.hook.targetDistance = math.Clamp(self.hook.targetDistance - self.reelSpeed * self.direction, 1, self.hook.maxDistance)
end

function SWEP:Initialize()
    -- Create model to render on gun
    self.direction = 0

    -- Only create model on client
    if !CLIENT then return end
    local ent = ents.CreateClientside(self.hookClass)
    ent:SetNoDraw(true)
    self.hookMdl = ent
end

function SWEP:Cleanup()
    -- Detaches the hook
    -- Error checking
    if !SERVER then return end
    if !self.hook or !self.hook:IsValid() then return end

    -- Sounds
    if self:GetOwner():IsValid() then
        self:GetOwner():StopSound("reel_sound")
        self:GetOwner():EmitSound("release_sound")
    end

    -- Make sure the hook is detached from forces
    self.hook:SetHookAttached(false)
    self.hook:SetHookActive(false)

    -- Keep reference for deletion
    local _hook = self.hook
    self.hook = NULL

    -- Remove hook after 3 seconds
    timer.Simple(3, function()
        if !_hook or !_hook:IsValid() then return end
        _hook:Remove()
    end )
end

function SWEP:Reload()
    -- Reload detaches the hook if its deployed
    self:Cleanup()
end

function SWEP:PrimaryAttack()
    -- This function will launch the hook and wait for it to grapple
    -- or it will reel the grapple in depending on the status of it
    if !SERVER then return end
    if !self:GetOwner():IsValid() then return end

    -- Collect variables
    local ply = self:GetOwner()
    local vm = ply:GetViewModel()
    local lookDirection = ply:GetAimVector()

    -- Logic
    if self.hook and self.hook:IsValid() and self.hook.hookAttached then
        -- Hook already launched, reel it in
        ply:EmitSound("reel_sound")
        self.direction = 1

        -- Create hook to wait for end
        hook.Add("KeyRelease", "hookReelEnd" .. tostring(self.hook:EntIndex()), function(_ply, key)
            -- Error checking
            if _ply != ply then return end
            if key != IN_ATTACK then return end
            if !self:IsValid() or !self:GetOwner():IsValid() then return end

            -- Stop reel
            self.direction = 0
            ply:StopSound("reel_sound")

            -- Stop listening for a release
            hook.Remove("KeyRelease", "hookReelEnd" .. tostring(self.hook:EntIndex()))
        end )
    elseif !self.hook or !self.hook:IsValid() or !self.hook.hookAttached then
        -- Hook has not been launched, launch it.
        self:SetNextPrimaryFire(CurTime() + 0.2)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        ply:EmitSound("firing_sound")

        -- Get positional data
        local boneTransform = self:GetAttachment(1)

        if vm:IsValid() and boneTransform then
            -- Spawn the hook at the end of the muzzle
            local ent = ents.Create(self.hookClass)
            ent:SetPos(boneTransform.Pos + vm:GetForward() * ent.positionOffset.x)
            ent:SetAngles(vm:LocalToWorldAngles(ent.angleOffset))
            ent:Spawn()
            ent:SetHookLauncher(self:GetOwner())
            ent:SetHookAttached(true)
            ent:SetColor(self.weaponColor)

            -- Launch the hook
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            -- Save references to new data
            self.hook = ent
            self:SetNWEntity("hook", ent)

            -- Setup the launch function to activate once the key is released
            hook.Add("KeyRelease", "hookLaunchActive" .. tostring(ent:EntIndex()), function(_ply, key)
                -- Error checking
                if _ply != ply then return end
                if key != IN_ATTACK then return end
                if !self:IsValid() or !self:GetOwner():IsValid() then return end

                -- Send data to the hook
                local distance = self:GetOwner():GetPos():Distance(ent:GetPos())
                ent.lastDistance = math.Clamp(distance, 1, ent.maxDistance)
                ent.targetDistance = math.Clamp(distance, 1, ent.maxDistance)
                ent:SetHookActive(true)

                -- Stop listening for a release
                hook.Remove("KeyRelease", "hookLaunchActive" .. tostring(ent:EntIndex()))
            end )
        end
    end
end

function SWEP:SecondaryAttack()
    -- This function will cause the hook to expand
    if !SERVER then return end
    if !self.hook or !self.hook:IsValid() or !self.hook.hookAttached then return end
    if !self:GetOwner() then return end

    -- Expand the book
    local ply = self:GetOwner()
    ply:EmitSound("reel_sound")
    self.direction = -1

    -- Create hook to wait for end
    hook.Add("KeyRelease", "hookExpandEnd" .. tostring(self.hook:EntIndex()), function(_ply, key)
        -- Error checking
        if _ply != ply then return end
        if key != IN_ATTACK2 then return end
        if !self:IsValid() or !self:GetOwner():IsValid() then return end

        -- Stop reel
        self.direction = 0
        ply:StopSound("reel_sound")

        -- Stop listening for a release
        hook.Remove("KeyRelease", "hookExpandEnd" .. tostring(self.hook:EntIndex()))
    end )
end

function SWEP:ViewModelDrawn(ent)
    -- Draw the beam for the viewmodel
    if !CLIENT then return end
    if !self:GetOwner():IsValid() then return end
    if !ent:IsValid() then return end
    if !self.hookMdl:IsValid() then return end

    -- Get information to render
    local vm = self:GetOwner():GetViewModel()
    local attachmentPoint = vm:GetAttachment(1)
    local _hook = self:GetNWEntity("hook", NULL)

    -- Make the color match the setting
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

function SWEP:DrawWorldModel(flags)
    -- Draw the gun and rope to the hook
    if !CLIENT then return end

    -- Make sure the default model is rendered
    self:DrawModel(flags)

    -- Get positional data for the hook
    local boneTransform = self:GetAttachment(1)

    -- Get location to attach to
    if self.hookMdl:IsValid() and boneTransform then
        -- Draw the hook since there is none launched
        local pos, ang = LocalToWorld(self.hookMdl.positionOffset, self.hookMdl.angleOffset, boneTransform.Pos, boneTransform.Ang)
        self.hookMdl:SetRenderOrigin(pos)
        self.hookMdl:SetRenderAngles(ang)
        self.hookMdl:SetPos(pos)
        self.hookMdl:SetAngles(ang)
        self.hookMdl:DrawModel()
    end
end

function SWEP:Holster()
    -- Weapon was holstered, fix colors
    if self:IsValid() and self:GetOwner():IsValid() and self:GetOwner():GetViewModel():IsValid() then
        self:GetOwner():GetViewModel():SetColor(Color(255, 255, 255))
    end

    return true
end

function SWEP:OnRemove()
    -- Weapon was removed, make sure to delete the clientside models
    -- and to detach the hook
    if CLIENT and self.hookMdl:IsValid() then
        self.hookMdl:Remove()
    end

    self:Cleanup()
    self:Holster()
end