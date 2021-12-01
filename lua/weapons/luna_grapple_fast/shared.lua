-- Swep info
SWEP.Base = "luna_grapple_basic"
SWEP.Instructions = "Primary to launch\nRelease to detach"
SWEP.Spawnable = true

-- Swep config
SWEP.launchForce = 2200000
SWEP.hookClass = "luna_hook_sticky"
SWEP.weaponColor = Color(100, 100, 250)

-- Functions
function SWEP:Reel()
    -- This function starts reeling in the direction supplied
    -- Error checking
    if !SERVER then return end
    if game.SinglePlayer() and luna.gameUIVisible then return end
    if !self.hook or !self.hook:IsValid() then return end

    -- Start changing values
    self.hook.targetDistance = self.hook.lastDistance - 200
end

function SWEP:Cleanup()
    -- Detaches the hook
    -- Error checking
    if !SERVER then return end
    if !self.hook or !self.hook:IsValid() then return end

    -- Sounds
    if self:GetOwner():IsValid() then
        luna.stopSound("reel_sound", self, nil)
        luna.playSound("release_sound", self, false, nil)
    end

    -- Make sure the hook is detached from forces
    self.hook:SetHookAttached(false)
    self.hook:SetHookActive(false)

    -- Remove hook now
    if self.hook and self.hook:IsValid() then self.hook:Remove() end
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
    if !self.hook or !self.hook:IsValid() or !self.hook.hookAttached then
        -- Hook has not been launched, launch it.
        self:SetNextPrimaryFire(CurTime() + 0.2)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        luna.playSound("firing_sound", self, false, nil)
        luna.playSound("reel_sound", self, false, nil)

        -- Get positional data
        local boneTransform = self:GetAttachment(1)

        if vm:IsValid() and boneTransform then
            -- Spawn the hook at the end of the muzzle
            local ent = ents.Create(self.hookClass)
            ent:SetPos(boneTransform.Pos + vm:GetForward() * ent.positionOffset.x)
            ent:SetAngles(vm:LocalToWorldAngles(ent.angleOffset))
            ent:Spawn()
            ent:SetHookLauncher(self:GetOwner())
            ent:SetHookActive(true)
            ent:SetColor(self.weaponColor)

            -- Launch the hook
            ent:GetPhysicsObject():ApplyForceCenter(lookDirection * self.launchForce)

            -- Save references to new data
            self.hook = ent
            self:SetNWEntity("hook", ent)

            -- Send data to the hook
            local distance = self:GetOwner():GetPos():Distance(ent:GetPos()) + ent:GetVelocity():Length() - ply:GetVelocity():Length()
            ent.lastDistance = math.Clamp(distance, 1, ent.maxDistance)
            ent.targetDistance = math.Clamp(distance, 1, ent.maxDistance)
            ent:SetHookAttached(true)

            -- Setup the launch function to activate once the key is released
            hook.Add("KeyRelease", "hookLaunchActive" .. tostring(ent:EntIndex()), function(_ply, key)
                -- Error checking
                if _ply != ply then return end
                if key != IN_ATTACK then return end
                if !self:IsValid() or !self:GetOwner():IsValid() then return end

                self:Cleanup()

                -- Stop listening for a release
                hook.Remove("KeyRelease", "hookLaunchActive" .. tostring(ent:EntIndex()))
            end )
        end
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end