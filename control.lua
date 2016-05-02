require "util"
require "defines"

function init()
	global.trainStations = global.trainStations or game.get_surface(1).find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, type="train-stop"} or {}
	global.shuttleTrains = global.shuttleTrains or game.get_surface(1).find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, name="shuttleTrain"} or {}
    load()
end

function load()
    global.version = "1.0.1"
    global.filters = global.filters or {}
    global.filters.meta_data = {force_update = false }
    global.filtered_stations = global.filtered_stations or {}
    global.trainStations = global.trainStations or {}
    global.shuttleTrains = global.shuttleTrains or {}
end

script.on_init(init)
script.on_load(load)
currentPage = 1
stations = {}

script.on_configuration_changed(function()
    init()
    for player_id, player in ipairs(game.players)do
        addPlayerGui(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    addPlayerGui(game.players[event.player_index])
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event) 
	local player = game.players[event.player_index]
	if (player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
		if (player.gui.left.shuttleTrain == nil) then
			createGui(player, event)
		end
	end
	if (player.vehicle == nil and player.gui.left.shuttleTrain ~= nil) then
		player.gui.left.shuttleTrain.destroy()
	end
end)

function addPlayerGui(player)
    if (player.vehicle == nil or player.vehicle ~= nil and player.vehicle.name ~= "shuttleTrain") and player.gui.top.shuttleFrame == nil then
        player.gui.top.add{type="frame", name="shuttleFrame", direction = "vertical"}
        player.gui.top.shuttleFrame.add{type="button", name="shuttleTop", style="st_top_image_button_style" }
    end
end

function on_tick(event)
	if event.tick % 60 == 0 then -- every second
		local count = 0
		for player_id,player in ipairs(game.players) do
			if player.gui.left.shuttleTrain then
				count = count + 1
				if global.filters[player_id] ~= player.gui.left.shuttleTrain.filter.filter_txfield.text or global.filters.meta_data.force_update then
					global.filters.meta_data.force_update = false
					currentPage = 1
					global.filters[player_id] = player.gui.left.shuttleTrain.filter.filter_txfield.text or ""
					global.filtered_stations[player_id] = {}
					local names = {}
					for _,station in ipairs(global.trainStations) do
						if string.find(string.upper(station.backer_name), string.upper(global.filters[player_id]), 1, true) and not names[station.backer_name] then -- case-insensitive
							names[station.backer_name] = true -- allows to keep track of which station has already been added
							table.insert(global.filtered_stations[player_id], station)
						end
					end
					table.sort(global.filtered_stations[player_id], function (a, b) return a.backer_name < b.backer_name end)
					updateStationsGUI(player, currentPage)
				end
			end
		end
		if count == 0 then script.on_event(defines.events.on_tick, nil) end -- if no-one has the GUI open we remove the event handler
	end
end


script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]

    if event.element.name == "shuttleTop" then
        if player.gui.left.shuttleTrain == nil then
            createGui(player, event)
        else
            player.gui.left.shuttleTrain.destroy()
        end
    end

	if (player.gui.left.shuttleTrain == nil) then
		return
	end

	if (event.element.name == "nextPage") then
		if (currentPage < math.floor((#global.filtered_stations[player.index] -1) / 10) + 1) then 
			currentPage = currentPage + 1
			updateStationsGUI(player, currentPage)
		end
	end

	if (event.element.name == "prevPage") then
		if (currentPage > 1) then
			currentPage = currentPage -1
			updateStationsGUI(player, currentPage)
		end
	end

	if (event.element.parent == player.gui.left.shuttleTrain.flow) then

		for key, station in pairs(global.trainStations) do
			if (event.element.name == station.backer_name) then
                local schedule = {current = 1, records = {[1] = {time_to_wait = 30, station = event.element.name}}}
				if(player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
					player.vehicle.train.schedule= schedule
					player.vehicle.train.manual_mode = false
				elseif global.shuttleTrains ~= nil or global.shuttleTrains ~= {} then
                    if global.shuttleTrains[1] == nil then
                        global.shuttleTrains = game.get_surface(1).find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, name="shuttleTrain"}
                    end
                    local closestTrain
                    local distanceToClosestTrain = 99999999999999999999999999
                    for key, train in ipairs(global.shuttleTrains)do
                        local distance = util.distance(train.position, station.position)
                        if distance < distanceToClosestTrain then
                            if train.train.state == defines.trainstate.no_schedule or train.train.state == defines.trainstate.no_path or train.train.state == defines.trainstate.wait_station or train.train.state == defines.trainstate.manual_control then
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

entityBuilt = function(event)
	local entity = event.created_entity
	if (entity.type == "train-stop") then
		table.insert(global.trainStations, entity)

		global.filters.meta_data.force_update = true
		on_tick(event) -- force an update of the GUI (in case someone is in the GUI)

    elseif entity.name == "shuttleTrain" then
        table.insert(global.shuttleTrains, entity)
	end
end

script.on_event(defines.events.on_built_entity, entityBuilt)
script.on_event(defines.events.on_robot_built_entity, entityBuilt)

entityDestroyed = function(event)
	local entity = event.entity
	if (entity.type == "train-stop" and global.trainStations ~= nil) then
		for key, value in pairs(global.trainStations) do
			if (entity == value) then
				table.remove(global.trainStations, key)
				global.filters.meta_data.force_update = true
				on_tick(event) -- force an update of the GUI (in case someone is in the GUI)
			end
        end
    elseif entity.name == "shuttleTrain" and global.shuttleTrains ~= nil then
        for key, value in ipairs(global.shuttleTrains) do
            if entity == value then
                table.remove(global.shuttleTrains, key)
            end
        end
	end
end

script.on_event(defines.events.on_entity_died, entityDestroyed)
script.on_event(defines.events.on_preplayer_mined_item, entityDestroyed)
script.on_event(defines.events.on_robot_pre_mined, entityDestroyed)

createGui = function(player, event)
	if player.gui.left.shuttleTrain ~= nil then return end
    script.on_event(defines.events.on_tick, function(event) on_tick(event) end) -- register update function
    global.filters.meta_data.force_update = true
    on_tick(event) -- force an update of the GUI
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


	currentPage = 1
	prevStations = {}

	if global.filters[player.index] then -- retrieve filter from data
		player.gui.left.shuttleTrain.filter.filter_txfield.text = global.filters[player.index]
		global.filters.meta_data.force_update = true
	end

	--indexStations(player)
	--addStations(player, 1)

end

nextPage = function(player)

end


function updateStationsGUI(player, page)
	local stationsAdded = 0
	
	if (page == 1) then
		player.gui.left.shuttleTrain.header.prevPage.style = "st-nav-button-arrow-disabled"
	else
		player.gui.left.shuttleTrain.header.prevPage.style = "st-nav-button-arrow"
	end

	
	if (page == math.floor((#global.filtered_stations[player.index] -1) / 10) + 1 or math.floor((#global.filtered_stations[player.index] -1) / 10) + 1 == 0) then
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
		player.gui.left.shuttleTrain.header.pageNumber.caption = page .. "/" .. math.floor((#global.filtered_stations[player.index] -1) / 10) + 1
	end


	if (global.filtered_stations[player.index] ~= nil or #global.filtered_stations[player.index] ~= 0) then
		local startIndex = (page -1) * 10 + 1
		while stationsAdded < 10 and global.filtered_stations[player.index][startIndex + stationsAdded] ~= nil do
			local name = global.filtered_stations[player.index][startIndex + stationsAdded].backer_name
			player.gui.left.shuttleTrain.flow.add{type = "button", name = name, caption = name, style = "st-station-button"}
			stationsAdded = stationsAdded + 1
		end
	end
end

indexStations = function(player)
	if (global.trainStations ~= nil) then
		stations = {}
		for key, station in pairs(global.trainStations) do
			local stationAlreadyAdded = false
			--for key2, value in pairs(player.gui.left.shuttleTrain.children_names)do
			for key2, value in pairs(stations) do
				if (station.backer_name == value.backer_name) then
					stationAlreadyAdded = true
				end
			end
			--for key2, value in pairs(prevStations)do
			--	if(station.backer_name == value.backer_name)then
			--		stationAlreadyAdded = true
			--	end
			--end
			if (stationAlreadyAdded == false) then
				--player.gui.left.shuttleTrain.add{type="button", name=station.backer_name, caption=station.backer_name }
				--table.insert(prevStations, station)
				--player.gui.left.shuttleTrain.flow.add{type="button", name=station.backer_name, caption=station.backer_name }
				table.insert(stations, station)
			end

		end
		local function compare(a,b)
			return a.backer_name < b.backer_name
		end

		table.sort(stations, compare)

	end
	--player.print(table.tostring(stations))
end

addStations = function(player, page)
	local stationsAdded = 0
	
	if (page == 1) then
		player.gui.left.shuttleTrain.header.prevPage.style = "st-nav-button-disabled"
	else
		player.gui.left.shuttleTrain.header.prevPage.style = "st-nav-button"
	end

	player.gui.left.shuttleTrain.header.pageNumber.caption = page .. "/" .. math.floor(#stations / 10) + 1
	
	if (page == math.floor(#stations / 10) + 1) then
		player.gui.left.shuttleTrain.header.nextPage.style = "st-nav-button-disabled"
	else
		player.gui.left.shuttleTrain.header.nextPage.style = "st-nav-button"
	end

	if(player.gui.left.shuttleTrain.flow ~= nil) then
		player.gui.left.shuttleTrain.flow.destroy()
	end

	player.gui.left.shuttleTrain.add{type = "flow", name = "flow", direction = "vertical"}

	if (stations ~= nil or stations ~= {}) then
		local startIndex = 10 * page - 9
		while stationsAdded < 10 do
			if (stations[startIndex + stationsAdded] ~= nil) then
				local name = stations[startIndex + stationsAdded].backer_name
				player.gui.left.shuttleTrain.flow.add{type = "button", name = name, caption = name, style = "st-station-button"}
			end
			stationsAdded = stationsAdded + 1
		end
	end

	--if(global.trainStations~=nil)then
	--	for key, station in pairs(global.trainStations)do
	--		local stationAlreadyAdded = false
	--		--for key2, value in pairs(player.gui.left.shuttleTrain.children_names)do
	 --	   for key2, value in pairs(player.gui.left.shuttleTrain.flow.children_names)do
	--			if(station.backer_name == value )then
	--				stationAlreadyAdded = true
	--			end
	--		end
	--		for key2, value in pairs(prevStations)do
	--			if(station.backer_name == value.backer_name)then
	--				stationAlreadyAdded = true
	--			end
	--		end
	--		if(stationAlreadyAdded ==false)then
				--player.gui.left.shuttleTrain.add{type="button", name=station.backer_name, caption=station.backer_name }
	--			table.insert(prevStations, station)
	--			player.gui.left.shuttleTrain.flow.add{type="button", name=station.backer_name, caption=station.backer_name }
	--			stationsAdded = stationsAdded+1
	--		end
	--		if(stationsAdded>9)then
	--			currentPageFull = true
	--			break
	--		end
	--	end
   --	 currentPageFull = false
   -- end
end

findAllStations = function()

end

function sendMessageToAllPlayers(message)
    for _,player in ipairs(game.players)do
        player.print(message)
    end
end