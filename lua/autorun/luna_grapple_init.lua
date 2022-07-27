-- Initialize files
if SERVER then
    AddCSLuaFile("luna_grapple_init.lua")
    AddCSLuaFile("luna_grapple/cl_init.lua")
    AddCSLuaFile("luna_grapple/luna_custom_menu.lua")
    include("luna_grapple/sv_init.lua")
    include("luna_grapple/luna_custom_menu.lua")
else
    include("luna_grapple/cl_init.lua")
    include("luna_grapple/luna_custom_menu.lua")
end