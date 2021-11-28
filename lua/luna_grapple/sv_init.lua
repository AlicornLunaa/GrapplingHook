-- Server initialization
util.AddNetworkString("luna:grapple:uiVisibleChanged")

gameUIVisible = false

net.Receive("luna:grapple:uiVisibleChanged", function(len, ply)
    -- Change the serverside variable
    gameUIVisible = net.ReadBool()
end )