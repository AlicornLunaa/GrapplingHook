-- Initialize files
if SERVER then
    AddCSLuaFile("luna_grapple_init.lua")
    AddCSLuaFile("luna_grapple/cl_init.lua")
    include("luna_grapple/sv_init.lua")
else
    include("luna_grapple/cl_init.lua")
end