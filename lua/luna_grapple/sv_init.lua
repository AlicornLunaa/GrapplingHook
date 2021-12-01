-- Server initialization
util.AddNetworkString("luna:grapple:uiVisibleChanged")
util.AddNetworkString("luna:grapple:playSound")
util.AddNetworkString("luna:grapple:stopSound")

-- Library variables and functions
luna = luna or {}
luna.gameUIVisible = false

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

-- Net messages
net.Receive("luna:grapple:uiVisibleChanged", function(len, ply)
    -- Change the serverside variable
    luna.gameUIVisible = net.ReadBool()
end )