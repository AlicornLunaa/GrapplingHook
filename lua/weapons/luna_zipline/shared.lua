-- Swep info
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Primary to launch\nReload to detach"

SWEP.Spawnable = true
SWEP.ViewModel = "models/weapons/v_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- Swep config
SWEP.launchForce = 6000000
SWEP.maxDistance = 100000
SWEP.reelSpeed = 4
SWEP.pullForce = 0.12
SWEP.maxLerp = 1000
SWEP.cableMaterial = Material("cable/cable2")
SWEP.hookClass = "luna_hook_heavy"
SWEP.weaponColor = Color(255, 255, 255)

-- Functions
function SWEP:Think()
    -- Serverside code
    if SERVER then
        -- Get variables
        local isLaunched = self:GetNWBool("launched", false)
        local ply = self:GetOwner()
        local _start = self:GetNWEntity("start")
        local _hook = self:GetNWEntity("hook")

        -- Slide player along the rope
        if isLaunched and _hook:IsValid() and _hook.attached and self:GetOwner():IsValid() then
            -- Get directions for hooks
            local startPos = _start:LocalToWorld(Vector(0, 0, 52))
            local hookPos = _hook:LocalToWorld(_hook.attachPosition)
            local newPos = LerpVector(self.distance, startPos, hookPos)
            local plyPos = ply:GetPos() + Vector(0, 0, 70)
            local deviance = newPos:GetNormalized():Dot(plyPos:GetNormalized())
            print(deviance)

            ply:SetVelocity((newPos - plyPos):GetNormalized() * (50 * deviance) - (ply:GetVelocity() * 0.05))
            self.distance = self.distance + 0.001

            if self.distance >= 1 then
                self:Cleanup()
            end
        end
    end
end

function SWEP:Initialize()
    -- Create sounds
    sound.Add({
        name = "firing_sound",
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 60,
        pitch = { 80, 100 },
        sound = "ambient/materials/clang1.wav"
    })

    sound.Add({
        name = "release_sound",
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 60,
        pitch = { 80, 100 },
        sound = "ambient/tones/elev2.wav"
    })

    sound.Add({
        name = "reel_sound",
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 80,
        pitch = 100,
        sound = "ambient/tones/fan2_loop.wav"
    })

    -- Create model to render on gun
    if CLIENT then
        local ent = ents.CreateClientside(self.hookClass)
        ent:SetNoDraw(true)

        self.hookMdl = ent
    end
end

function SWEP:Cleanup()
    -- Detaches hook
    local isLaunched = self:GetNWBool("launched", false)
    local _start = self:GetNWEntity("start")
    local _hook = self:GetNWEntity("hook")

    if isLaunched then
        -- Hook exists, remove it after 3 seconds and also detach it within code
        self:SetNWBool("launched", false)
        self:EmitSound("release_sound")

        timer.Simple(3, function()
            -- Only server can remove the hook
            if SERVER and _hook:IsValid() then
                _start:Remove()
                _hook:Remove()
            end
        end )
    end
end

function SWEP:Reload()
    -- Reload detaches the hook if its deployed
    self:Cleanup()
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

        -- Serverside only
        if SERVER then
            -- Spawn the hook at hand and launch it in the look direction
            local viewModel = self:GetOwner():GetViewModel()
            local attachmentPoint = self:GetAttachment(2)
            local ent = ents.Create(self.hookClass)
            ent:SetPos(attachmentPoint.Pos + viewModel:GetForward() * ent.positionOffset.x)
            ent:SetAngles(viewModel:LocalToWorldAngles(ent.angleOffset))
            ent:SetOwner(self:GetOwner())
            ent:Spawn()
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            -- Create the starting point
            local ent2 = ents.Create("luna_zipline_start")
            ent2:SetPos(self:GetOwner():GetPos() + Vector(0, 0, 30))
            ent2:SetAngles(Angle(0, 0, 0))
            ent2:SetOwner(self:GetOwner())
            ent2:SetNWEntity("hook", ent)
            ent2:Spawn()

            self:SetNWEntity("hook", ent)
            self:SetNWEntity("start", ent2)
            self:SetNWBool("launched", true)

            self.distance = 0
        end
    end
end

function SWEP:ViewModelDrawn(ent)
    if CLIENT then
        -- Draw the beam for the viewmodel
        -- Get networked information
        local attachmentPoint = self:GetOwner():GetViewModel():GetAttachment(1)
        local _hook = self:GetNWEntity("hook")

        ent:SetColor(self.weaponColor)
        self.hookMdl:SetColor(self.weaponColor)

        -- Get location to attach to
        if !_hook:IsValid() then
            -- Draw hook on the gun because it's not launched
            cam.Start3D()
                self.hookMdl:SetRenderOrigin(attachmentPoint.Pos - ent:GetForward() * self.hookMdl.positionOffset.x)
                self.hookMdl:SetRenderAngles(ent:LocalToWorldAngles(self.hookMdl.angleOffset))
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
        local _hook = self:GetNWEntity("hook")

        -- Get location to attach to
        if !_hook:IsValid() and self.hookMdl:IsValid() and attachmentPoint then
            -- Draw the hook since there is none launched
            local pos, ang = LocalToWorld(Vector(-8, -0.5, 0), self.hookMdl.angleOffset, attachmentPoint.Pos, attachmentPoint.Ang)
            self.hookMdl:SetRenderOrigin(pos)
            self.hookMdl:SetRenderAngles(ang)
            self.hookMdl:DrawModel()
        end
    end
end

function SWEP:Holster()
    -- Weapon was holstered, fix colors
    self:GetOwner():GetViewModel():SetColor(Color(255, 255, 255))
    self:Cleanup()
    return true
end