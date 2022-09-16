-- Server initialization
util.AddNetworkString("luna:grapple:uiVisibleChanged")
util.AddNetworkString("luna:grapple:playSound")
util.AddNetworkString("luna:grapple:stopSound")

-- Library variables and functions
luna = luna or {}
luna.gameUIVisible = false

-- Convars
local damageFlag = CreateConVar("luna_grapple_nodamage", 0, FCVAR_LUA_SERVER, "Sets whether or not hooks can do damage to people/things. (1/0)", 0, 1)

function luna.playSound(name, entity, _local, target)
    -- Plays a sound at a specific entity
    net.Start("luna:grapple:playSound")

    net.WriteString(name)
    net.WriteEntity(entity)
    net.WriteBool(_local)

    if target == nil then
        net.Broadcast()
    else
        net.Send(target)
    end
end

function luna.stopSound(name, entity, target)
    -- Plays a sound at a specific entity
    net.Start("luna:grapple:stopSound")

    net.WriteString(name)
    net.WriteEntity(entity)

    if target == nil then
        net.Broadcast()
    else
        net.Send(target)
    end
end

function luna.sign(a)
    -- This function returns a -1 0 or 1 depending on the sign on the variable supplied
    if a < 0 then
        return -1
    elseif a > 0 then
        return 1
    else
        return 0
    end
end

-- Net messages
net.Receive("luna:grapple:uiVisibleChanged", function(len, ply)
    -- Change the serverside variable
    luna.gameUIVisible = net.ReadBool()
end )

-- Hooks
hook.Add("EntityTakeDamage", "luna:grapple:damageNullifier", function(target, info)
    if(string.StartWith(info:GetAttacker():GetClass(), "luna_") and damageFlag:GetBool()) then
        return true;
    end
end )