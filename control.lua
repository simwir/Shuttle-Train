require "util"
require "defines"

function init()
    global.version = "0.0.1"
end

script.on_init(init)
--script.on_load(function()
--    if #game.players > 0 then
--        for _, player in ipairs(game.players) do
--            
--        end
--    end
--    shuttleTrainGUI = GUI.add()
--end)

script.on_event(defines.events.on_player_driving_changed_state, function(event) 
    local player = game.players[event.player_index]
    if(player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
        if(player.gui.left.shuttleTrain == nil)then
            createGui(player)
        end
    end
    if(player.vehicle == nil and player.gui.left.shuttleTrain ~= nil) then
        player.gui.left.shuttleTrain.destroy()
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    if(player.gui.left.shuttleTrain==nil)then return end
    if(event.element.parent == player.gui.left.shuttleTrain)then
        --TODO: Debug remove
        if(event.element == player.gui.left.shuttleTrain.bStop1)then
            player.print("Stop 1 button pressed")
            if(player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
                local schedule = {current=1, records={[1]={time_to_wait=30,station="Stop1"}} }
                player.vehicle.train.schedule= schedule
                player.vehicle.train.manual_mode = false
            end
        end
        if(event.element == player.gui.left.shuttleTrain.bStop2)then
            player.print("Stop 2 button pressed")
            if(player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
                local schedule = {current=1, records={[1]={time_to_wait=30,station="Stop2"}} }
                player.vehicle.train.schedule= schedule
                player.vehicle.train.manual_mode = false
            end
        end
        --Debug end
    end
end)

createGui = function(player)
    if player.gui.left.shuttleTrain ~= nil then return end
    player.gui.left.add{type="frame", name="shuttleTrain", direction="vertical" }
    player.gui.left.shuttleTrain.add{type="label", name="label", caption="Shuttle Train" }


    --FOR TESTING TODO: REMOVE THIS
    player.gui.left.shuttleTrain.add{type="button", name="bStop1", caption="Stop 1" }
    player.gui.left.shuttleTrain.add{type="button", name="bStop2", caption="Stop 2"}

end