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