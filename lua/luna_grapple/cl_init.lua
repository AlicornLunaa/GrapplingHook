-- Client initialization
gameUIVisible = false

local function updateUIVisible()
    -- Update variables
    gameUIVisible = gui.IsGameUIVisible()

    net.Start("luna:grapple:uiVisibleChanged")
        net.WriteBool(gui.IsGameUIVisible())
    net.SendToServer()
end

hook.Add("InitPostEntity", "luna:grapple:init", function()
    -- Check if the game is singleplayer, if its not you dont need to send this
    updateUIVisible()
end )

hook.Add("Tick", "luna:grapple:think", function()
    -- Check if the UI visible variable was changed
    if game.SinglePlayer() and gui.IsGameUIVisible() != gameUIVisible then
        -- Update variables
        updateUIVisible()
    end
end )