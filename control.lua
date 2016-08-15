require "util"

function init()
	global.trainStations = global.trainStations or game.surfaces[1].find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, type="train-stop"} or {}
	global.shuttleTrains = global.shuttleTrains or game.surfaces[1].find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, name="shuttleTrain"} or {}
    load()
end

function load()
    global.version = "1.1.3"
    global.filters = global.filters or {}
    global.current_page = global.current_page or {}
    global.filters.meta_data = {force_update = false }
    global.filtered_stations = global.filtered_stations or {}
    global.trainStations = global.trainStations or {}
    global.shuttleTrains = global.shuttleTrains or {}
    global.force_shuttle_call_GUI_update = true;
end

script.on_init(init)
script.on_configuration_changed(load)


script.on_event(defines.events.on_tick, function(event) on_tick(event) end) -- register update function

script.on_event(defines.events.on_player_created, function(event)
    UpdateShuttleCallButton(game.players[event.player_index])
end)

script.on_event(defines.events.on_research_finished, function(event)
    if event.research.name == "shuttleTrain_tech" then
        for _, player in pairs(event.research.force.players) do
            global.force_shuttle_call_GUI_update = true;
        end
    return
    end
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event) 
	local player = game.players[event.player_index]
	if (player.vehicle ~= nil and isShuttle(player.vehicle)) then
		if (player.gui.left.shuttleTrain == nil) then
			createGUI(player)
		end
	end
	if (player.vehicle == nil and player.gui.left.shuttleTrain ~= nil) then
		player.gui.left.shuttleTrain.destroy()
	end
end)

script.on_event(defines.events.on_train_changed_state, function(event)
    if  anyFrontMoverIsShuttle(event.train.locomotives["front_movers"]) and event.train.state == defines.train_state.wait_station and #event.train.schedule.records == 1 then
        event.train.manual_mode = true
    end
end)

function anyFrontMoverIsShuttle(front_movers)
    for _, loco in pairs(front_movers)do
        if isShuttle(loco) then
            return true
        end
    end
    return false
end

function isShuttle(locomotive)
    if locomotive.name == "shuttleTrain" then
        return true
    else
        return false
    end
end

function UpdateShuttleCallButton(player)
    if player.force.technologies["shuttleTrain_tech"].researched then
    	if not player.gui.top.shuttle_call_Frame then
            player.gui.top.add{type="frame", name="shuttle_call_Frame", direction = "vertical", style="st_top_button_frame_style"}
            player.gui.top.shuttle_call_Frame.add{type="button", name="shuttle_call_button", style="st_top_image_button_style" }
        end
    else
    	if player.gui.top.shuttle_call_Frame then
    		player.gui.top.shuttle_call_Frame.destroy()
    	end
    end
end

function on_tick(event)
    if global.force_shuttle_call_GUI_update then
        for _, player in pairs(game.players) do
            if player.gui.top.shuttleFrame then player.gui.top.shuttleFrame.destroy() end
            UpdateShuttleCallButton(player)
        end
        global.force_shuttle_call_GUI_update = nil
    end
	if event == null or (event.tick % 60 == 0) then -- every second or when the function is called without arg
        update_GUI_with_filter()
    end
end


function update_GUI_with_filter()
	for player_id,player in pairs(game.players) do
		if player.gui.left.shuttleTrain then
			if global.filters[player_id] ~= player.gui.left.shuttleTrain.filter.filter_txfield.text or global.filters.meta_data.force_update then
                global.current_page[player_id] = 1
				global.filters[player_id] = player.gui.left.shuttleTrain.filter.filter_txfield.text or ""
				global.filtered_stations[player_id] = {}
				local names = {}
				for _,station in pairs(global.trainStations) do
					if (station.valid == false) then
						removeTrainStopFromArray(station)
					elseif string.find(string.upper(station.backer_name), string.upper(global.filters[player_id]), 1, true) and not names[station.backer_name] then -- case-insensitive
						names[station.backer_name] = true -- allows to keep track of which station has already been added
						table.insert(global.filtered_stations[player_id], station)
					end
				end
				table.sort(global.filtered_stations[player_id], function (a, b) return a.backer_name < b.backer_name end)
				updateStationsGUI(player)
			end
		end
	end
	global.filters.meta_data.force_update = false
end


script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]

    if event.element.name == "shuttle_call_button" then
        if player.gui.left.shuttleTrain == nil then
            createGUI(player)
        else
            player.gui.left.shuttleTrain.destroy()
        end
	end

	if (player.gui.left.shuttleTrain == nil) then
		return
	end

	if (event.element.name == "nextPage") then
		if (global.current_page[player.index] < math.floor((#global.filtered_stations[player.index] -1) / 10) + 1) then 
			global.current_page[player.index] = global.current_page[player.index] + 1
			updateStationsGUI(player)
		end
	end

	if (event.element.name == "prevPage") then
		if (global.current_page[player.index] > 1) then
			global.current_page[player.index] = global.current_page[player.index] -1
			updateStationsGUI(player)
		end
	end

	if (event.element.parent == player.gui.left.shuttleTrain.flow) then

		for key, station in pairs(global.trainStations) do
			if (station.valid == false) then
				removeTrainStopFromArray(station)
			elseif (event.element.caption == station.backer_name) then
                local schedule = {current = 1, records = {[1] = {time_to_wait = 30, station = event.element.caption}}}
				if(player.vehicle ~= nil and isShuttle(player.vehicle)) then
					player.vehicle.train.schedule= schedule
					player.vehicle.train.manual_mode = false
				elseif global.shuttleTrains ~= nil or global.shuttleTrains ~= {} then
                    if global.shuttleTrains[1] == nil then
                        global.shuttleTrains = game.surfaces[1].find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, name="shuttleTrain"}
                    end
                    local closestTrain
                    local distanceToClosestTrain = 99999999999999999999999999
                    for key, train in pairs(global.shuttleTrains)do
                        local distance = util.distance(train.position, station.position)
                        if distance < distanceToClosestTrain then
                            if train.train.state == defines.train_state.no_schedule or train.train.state == defines.train_state.no_path or train.train.state == defines.train_state.wait_station or train.train.state == defines.train_state.manual_control then
                                closestTrain = train
                                distanceToClosestTrain = distance
                            end
                        end
                    end
                    if closestTrain == nil then
                        player.print("No unused shuttle train found")
                    else
                        player.print(string.format("Sent shuttle %q to station %q from %um away", closestTrain.backer_name, station.backer_name, distanceToClosestTrain))
                        closestTrain.train.schedule = schedule
                        closestTrain.train.manual_mode = false
                    end
                    break;
                end
            end
		end
	end
end)

function entityBuilt (event)
	local entity = event.created_entity
	if (entity.type == "train-stop") then
		table.insert(global.trainStations, entity)

		global.filters.meta_data.force_update = true
		on_tick(event) -- force an update of the GUI (in case someone is in the GUI)

    elseif isShuttle(entity) then
        table.insert(global.shuttleTrains, entity)
	end
end

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, entityBuilt)

function entityDestroyed (event)
	local entity = event.entity
	if (entity.type == "train-stop" and global.trainStations ~= nil) then
		removeTrainStopFromArray(entity)
    elseif isShuttle(entity) and global.shuttleTrains ~= nil then
        for key, value in pairs(global.shuttleTrains) do
            if entity == value then
                table.remove(global.shuttleTrains, key)
            end
        end
	end
end

function removeTrainStopFromArray(entity)
	for key, station in pairs(global.trainStations) do
		if entity == station then
			table.remove(global.trainStations, key)
			global.filters.meta_data.force_update = true
			on_tick() -- force an update of the GUI (in case someone is in the GUI)
		end
	end
end

script.on_event(defines.events.on_entity_died, entityDestroyed)
script.on_event(defines.events.on_preplayer_mined_item, entityDestroyed)
script.on_event(defines.events.on_robot_pre_mined, entityDestroyed)

function createGUI(player)
	if player.gui.left.shuttleTrain ~= nil then return end

	player.gui.left.add{type = "frame", name = "shuttleTrain", direction = "vertical"}
	player.gui.left.shuttleTrain.add{type = "flow", name = "title", direction = "horizontal"}
	player.gui.left.shuttleTrain.title.add{type = "label", name = "label", caption = "Shuttle Train", style = "st_label_title"}
	player.gui.left.shuttleTrain.add{type = "flow", name = "filter", direction = "horizontal"}
	player.gui.left.shuttleTrain.filter.add{type = "label", name = "filter_lbl", caption = "Filter:", style = "st_label_simple_text"}
	player.gui.left.shuttleTrain.filter.add{type = "textfield", name = "filter_txfield", style = "st_textfield"}
	player.gui.left.shuttleTrain.add{type = "flow", name = "header", direction = "horizontal"}
	player.gui.left.shuttleTrain.header.add{type = "button", name = "prevPage", caption = "<", style = "st-nav-button-arrow"}
	player.gui.left.shuttleTrain.header.add{type = "button", name = "pageNumber", caption = "1", style = "st-nav-button-pagination"}
	player.gui.left.shuttleTrain.header.add{type = "button", name = "nextPage", caption = ">", style = "st-nav-button-arrow"}

	player.gui.left.shuttleTrain.add{type="flow", name="flow", direction="vertical" }
	player.gui.left.shuttleTrain.flow.add{type = "label", name = "loading", caption = "Loading Stations", style = "st_label_title"}

    global.filters.meta_data.force_update = true
    update_GUI_with_filter() -- force an update of the GUI

	global.current_page[player.index] = 1
	if global.filters[player.index] then -- retrieve filter from data
		player.gui.left.shuttleTrain.filter.filter_txfield.text = global.filters[player.index]
		global.filters.meta_data.force_update = true
	end
end


function updateStationsGUI(player)
	
	if (global.current_page[player.index] == 1) then
		player.gui.left.shuttleTrain.header.prevPage.style = "st-nav-button-arrow-disabled"
	else
		player.gui.left.shuttleTrain.header.prevPage.style = "st-nav-button-arrow"
	end

	
	if (global.current_page[player.index] == math.floor((#global.filtered_stations[player.index] -1) / 10) + 1 or math.floor((#global.filtered_stations[player.index] -1) / 10) + 1 == 0) then
		player.gui.left.shuttleTrain.header.nextPage.style = "st-nav-button-arrow-disabled"
	else
		player.gui.left.shuttleTrain.header.nextPage.style = "st-nav-button-arrow"
	end

	if(player.gui.left.shuttleTrain.flow ~= nil) then
		player.gui.left.shuttleTrain.flow.destroy()
	end

	player.gui.left.shuttleTrain.add{type = "flow", name = "flow", direction = "vertical"}

	if #global.filtered_stations[player.index] == 0 then -- when no station match the search
		player.gui.left.shuttleTrain.flow.add{type = "label", name = "loading", caption = "No station found", style = "st_label_title"}
		player.gui.left.shuttleTrain.header.pageNumber.caption = "-/-"
	else
		player.gui.left.shuttleTrain.header.pageNumber.caption = global.current_page[player.index] .. "/" .. math.floor((#global.filtered_stations[player.index] -1) / 10) + 1
	end


	if (global.filtered_stations[player.index] ~= nil or #global.filtered_stations[player.index] ~= 0) then
		local stationsAdded = 0
		local startIndex = (global.current_page[player.index] -1) * 10 + 1
		while stationsAdded < 10 and global.filtered_stations[player.index][startIndex + stationsAdded] ~= nil do
			local name = global.filtered_stations[player.index][startIndex + stationsAdded].backer_name
			player.gui.left.shuttleTrain.flow.add{type = "button", name = stationsAdded+1, caption = name, style = "st-station-button"}
			stationsAdded = stationsAdded + 1
		end
	end
end

--#######   DEBUG   #######
function sendMessageToAllPlayers(message)
	for _,player in pairs(game.players)do
		player.print(message)
	end
end
