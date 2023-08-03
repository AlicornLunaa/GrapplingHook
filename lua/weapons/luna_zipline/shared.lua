-- Swep info
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Primary to launch\nReload to detach"

SWEP.Spawnable = true
SWEP.ViewModel = "models/weapons/v_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"

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
SWEP.launchForce = 600000
SWEP.reelSpeed = 4
SWEP.hookClass = "luna_hook_heavy"
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
    if !self:GetOwner():IsValid() then return end

    if self.start.distance >= 1 and self.start.playerDistance < 300 * 300 then
        self:Cleanup()
    end
end

function SWEP:Initialize()
    -- Create model to render on gun
    self.direction = 1

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
    if !self.start or !self.start:IsValid() then return end

    -- Sounds
    if self:GetOwner():IsValid() then
        luna.stopSound("reel_sound", self, nil)
        luna.playSound("release_sound", self, false, nil)
    end

    -- Make sure the hook is detached from forces
    self.hook:SetHookAttached(false)
    self.hook.zipActive = false

    -- Keep reference for deletion
    local _start = self.start
    local _hook = self.hook
    self.start = NULL
    self.hook = NULL

    -- Remove hook after 3 seconds
    timer.Simple(3, function()
        if _start:IsValid() then _start:Remove() end
        if _hook:IsValid() then _hook:Remove() end
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
    if !self.hook or !self.hook:IsValid() then
        -- Hook has not been launched, launch it.
        self:SetNextPrimaryFire(CurTime() + 0.2)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        luna.playSound("firing_sound", self, false, nil)

        -- Get positional data
        local boneTransform = self:GetAttachment(1)

        if vm:IsValid() and boneTransform then
            -- Spawn the hook at the end of the muzzle
            local ent = ents.Create(self.hookClass)
            ent:SetPos(boneTransform.Pos + vm:GetForward() * ent.positionOffset.x)
            ent:SetAngles(vm:LocalToWorldAngles(ent.angleOffset))
            ent:Spawn()
            ent:SetHookLauncher(self:GetOwner())
            ent:SetColor(self.weaponColor)
            ent.zipActive = true

            -- Spawn the start position of the zipline at the player
            local ent2 = ents.Create("luna_zipline_start")
            ent2:SetPos(self:GetOwner():GetPos() + Vector(0, 0, 30))
            ent2:SetAngles(Angle(0, 0, 0))
            ent2:SetNWEntity("hook", ent)
            ent2:SetNWEntity("wep", self)
            ent2:Spawn()
            ent2:SetHookLauncher(self:GetOwner())

            -- Launch the hook
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            -- Save references to new data
            self.hook = ent
            self.start = ent2
            self:SetNWEntity("hook", ent)
            self:SetNWEntity("start", ent2)

            -- Send data to the hook
            ent2.distance = 0
        end
    end
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