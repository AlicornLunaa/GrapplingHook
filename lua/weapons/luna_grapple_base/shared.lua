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
SWEP.maxDistance = 100000
SWEP.reelSpeed = 4
SWEP.pullForce = 0.12
SWEP.maxLerp = 1000
SWEP.cableMaterial = Material("cable/cable2")
SWEP.hookClass = "luna_hook_basic"
SWEP.weaponColor = Color(255, 255, 255)

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
        local isLaunched = self:GetNWBool("launched", false)
        local reeling = self:GetNWBool("reeling", false)
        local expanding = self:GetNWBool("expanding", false)
        local _hook = self:GetNWEntity("hook")

        -- Pull the player AND hook together
        if isLaunched and _hook:IsValid() and self:GetOwner():IsValid() then
            -- Get directions for hooks
            local hookPos = _hook:LocalToWorld(_hook.attachPosition)
            local ownerToHook = (hookPos - self:GetOwner():GetPos()):GetNormalized()
            local hookToOwner = (self:GetOwner():GetPos() - hookPos):GetNormalized()

            -- Get a variable to check if theyre moving towards or away the hook
            local currentDistance = self:GetOwner():GetPos():Distance(hookPos)
            local deltaDistance = currentDistance - self:GetNWFloat("lastDistance", 1)
            local distanceSign = sign(deltaDistance)
            self:SetNWFloat("lastDistance", currentDistance)

            -- Forces for hooks and player
            local distanceForce = math.max(currentDistance - self:GetNWFloat("distance", 1) + math.Clamp(self:GetOwner():GetVelocity():Length(), -self.maxLerp, self.maxLerp) * distanceSign, 0)
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
                self:StopSound("reel_sound")
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
                self:StopSound("reel_sound")
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
    -- Detaches the hook
    local isLaunched = self:GetNWBool("launched", false)
    local _hook = self:GetNWEntity("hook")

    self:SetNWBool("ropeAttached", false)
    self:StopSound("reel_sound")

    if isLaunched then
        -- Hook exists, remove it after 3 seconds and also detach it within code
        self:SetNWBool("launched", false)
        self:EmitSound("release_sound")

        timer.Simple(3, function()
            -- Only server can remove the hook
            if SERVER and _hook:IsValid() then
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
    if isLaunched then
        -- Hook already launched, reel it in if its hooked.
        self:SetNWBool("reeling", true)
        self:EmitSound("reel_sound")
    else
        -- Hook has not been launched, launch it.
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
            ent:SetOwner(self:GetOwner())
            ent:Spawn()
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            self:SetNWEntity("hook", ent)
            self:SetNWBool("ropeAttached", true)

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
    -- This function will cause the hook to expand
    -- Get data
    local isLaunched = self:GetNWBool("launched", false)

    -- Serverside code
    if isLaunched then
        self:SetNWBool("expanding", true)
        self:EmitSound("reel_sound")
    end
end

function SWEP:ViewModelDrawn(ent)
    if CLIENT then
        -- Draw the beam for the viewmodel
        -- Get networked information
        local vm = self:GetOwner():GetViewModel()
        local attachmentPoint = vm:GetAttachment(1)
        local _hook = self:GetNWEntity("hook")

        ent:SetColor(self.weaponColor)
        self.hookMdl:SetColor(self.weaponColor)

        -- Get location to attach to
        if _hook:IsValid() and self:GetNWBool("ropeAttached", false) then
            _hook:SetColor(self.weaponColor)

            cam.Start3D()
                render.SetMaterial(self.cableMaterial)
                render.DrawBeam(attachmentPoint.Pos, _hook:LocalToWorld(_hook.attachPosition), 1, 1, 1, Color(255, 255, 255))
            cam.End3D()
        else
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
        local _hook = self:GetNWEntity("hook")

        -- Get location to attach to
        if _hook:IsValid() and self:GetNWBool("ropeAttached", false) then
            render.SetMaterial(self.cableMaterial)
            render.DrawBeam(attachmentPoint.Pos, _hook:LocalToWorld(self.hookMdl.attachPosition), 1, 1, 1, Color(255, 255, 255))
        elseif self.hookMdl:IsValid() and attachmentPoint then
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
    self:Holster()
end