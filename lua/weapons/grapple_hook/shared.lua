-- Swep info
SWEP.Author	= "AlicornLunaa"
SWEP.Instructions = "Left click to launch a hook. Once the hook is taken, hold left click to retract and right click to expand. R to detach the hook."

SWEP.Spawnable			= true

SWEP.ViewModel			= "models/weapons/v_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize	= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

-- Functionality
local firingSound = Sound("garrysmod/balloon_pop_cute.wav")

function SWEP:Think()

end

function SWEP:Reload()

end

function SWEP:PrimaryAttack()
    -- This function will launch the hook and wait for it to grapple
    -- or it will reel the grapple in depending on the status of it
    if SERVER then
        -- Serverside code
        self.weapon:EmitSound(firingSound)
    else
        -- Clientside code

    end
end

function SWEP:SecondaryAttack()

end