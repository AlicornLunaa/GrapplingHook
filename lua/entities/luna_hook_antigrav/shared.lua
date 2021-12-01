-- Entity information
ENT.Base = "luna_hook_sticky"
ENT.PrintName = "Anti-gravity hook"

-- Render config
ENT.attachPosition = Vector(0, 0, 18)
ENT.positionOffset = Vector(8, -0.5, 0)
ENT.angleOffset = Angle(90, 180, 0)

-- Hook config
ENT.maxDistance = 100000
ENT.pullForce = 0.12
ENT.lerp = 1000
ENT.cableMaterial = Material("cable/cable2")