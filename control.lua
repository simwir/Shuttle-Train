require "util"
require "defines"

function init()
	global.version = "0.0.1"
	global.trainStations = global.trainStations or game.get_surface(1).find_entities_filtered{area = {{-10000,-10000}, {10000,10000}}, name="train-stop"} or {}
end

script.on_init(init)
currentPage = 1
stations = {}

script.on_event(defines.events.on_player_driving_changed_state, function(event) 
	local player = game.players[event.player_index]
	if (player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
		if (player.gui.left.shuttleTrain == nil) then
			createGui(player)
		end
	end
	if (player.vehicle == nil and player.gui.left.shuttleTrain ~= nil) then
		player.gui.left.shuttleTrain.destroy()
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]
	if (player.gui.left.shuttleTrain == nil) then
		return
	end

	if (event.element.name == "nextPage") then
		if (currentPage < math.floor(#stations / 10) + 1) then
			currentPage = currentPage + 1
			addStations(player, currentPage)
		end
	end

	if (event.element.name == "prevPage") then
		if (currentPage > 1) then
			currentPage = currentPage -1
			addStations(player, currentPage)
		end
	end

	--if(event.element.parent == player.gui.left.shuttleTrain)then

	if (event.element.parent == player.gui.left.shuttleTrain.flow) then

		for key, station in pairs(global.trainStations) do
			if (event.element.name == station.backer_name) then
				if(player.vehicle ~= nil and player.vehicle.name == "shuttleTrain") then
					local schedule = {current = 1, records = {[1] = {time_to_wait = 30, station = event.element.name}}}
					player.vehicle.train.schedule= schedule
					player.vehicle.train.manual_mode = false
				end
			end
		end
	end
end)

entityBuilt = function(event)
	local entity = event.created_entity
	if (entity.type == "train-stop") then
		table.insert(global.trainStations, entity)
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
			end
		end
	end
end

script.on_event(defines.events.on_entity_died, entityDestroyed)
script.on_event(defines.events.on_preplayer_mined_item, entityDestroyed)
script.on_event(defines.events.on_robot_pre_mined, entityDestroyed)

createGui = function(player)
	if player.gui.left.shuttleTrain ~= nil then return end
	player.gui.left.add{type = "frame", name = "shuttleTrain", direction = "vertical"}
	player.gui.left.shuttleTrain.add{type = "flow", name = "title", direction = "horizontal"}
	player.gui.left.shuttleTrain.title.add{type = "label", name = "label", caption = "Shuttle Train", style = "st_label_title"}
	player.gui.left.shuttleTrain.add{type = "flow", name = "header", direction = "horizontal"}
	player.gui.left.shuttleTrain.header.add{type = "button", name = "prevPage", caption = "<", style = "st-nav-button"}
	player.gui.left.shuttleTrain.header.add{type = "button", name = "pageNumber", caption = "1", style = "st-nav-button"}
	player.gui.left.shuttleTrain.header.add{type = "button", name = "nextPage", caption = ">", style = "st-nav-button"}
	--player.gui.left.shuttleTrain.add{type="flow", name="flow", direction="vertical" }

	currentPage = 1
	prevStations = {}

	indexStations(player)
	addStations(player, 1)

end

nextPage = function(player)

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