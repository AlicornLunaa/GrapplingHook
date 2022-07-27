-- Holds custom derma panel for the custom grappling hook
if SERVER then

end

if CLIENT then
    local function openCustomMenu()
        -- Opens the derma panel to adjust custom settings on the gun
        local frame = vgui.Create("DFrame")
        frame:SetTitle("Luna's Grappling Hook Customizer")
        frame:SetSize(640, 480)
        frame:Center()
        frame:SetVisible(true)
        frame:SetDraggable(false)
        frame:ShowCloseButton(true)
        frame:MakePopup()
    end
    concommand.Add("luna_cm", openCustomMenu)
end