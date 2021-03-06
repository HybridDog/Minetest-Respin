--this needs to depend on all mods which have craftable items


--add cooking recipes

--[[
minetest.compress(data, method, ...)`: returns `compressed_data`
    * Compress a string of data.
    * `method` is a string identifying the compression method to be used.
    * Supported compression methods:
    *     Deflate (zlib): `"deflate"`
    * `...` indicates method-specific arguments.  Currently defined arguments are:
    *     Deflate: `level` - Compression level, `0`-`9` or `nil`.
* `minetest.decompress(compressed_data, method, ...)`: returns data
    * Decompress a string of data (using ZLib).
    * See documentation on `minetest.compress()` for supported compression methods.
    * currently supported.
    * `...` indicates method-specific arguments. Currently, no methods use this.
]]--

--create a table of all recipes - maybe compressed
too_many_items_table = {}

--go through each mod after everything is online
--organize all the recipes into each mod it's from





---make table for item groups and then cycle through the groups while the player is looking at them





--THIS NEEDS TO BE ORGANIZED BY NAME IN ALPHABETICAL ORDER
total_items = 0
too_many_items_group_items = {}
minetest.after(0, function()
	local count = 1
	for _,mods in pairs(minetest.get_modnames()) do
		for key,value in pairs(minetest.registered_items) do
			--don't put it in the table if it doesn't have a recipe
			if minetest.get_craft_recipe(key).items ~= nil then
				if string.match(key, mods) then
					--add it to the search if shouldn't be in creative
					--if not value.groups.not_in_creative_inventory then
						too_many_items_table[count] = key
						--add the item to it's respective groups if it has a recipe
						for group,_ in pairs(minetest.registered_items[key].groups) do
							if not too_many_items_group_items[group] then
								too_many_items_group_items[group] = {}
							end
							table.insert(too_many_items_group_items[group], key)
							--too_many_items_group_items[group] = too_many_items_group_items[group]+key
						end
						count = count + 1
					--end
				end
			end
		end
	end
	total_items = count
end)


--access all the recipes
if too_many_items_table then
	print(dump(too_many_items_table))
end
--print(dump(minetest.get_all_craft_recipes("default:glass")))

--add too many items to the default formspec
player_pages = {}
recipe_page  = {}
player_item_recipe = {}
player_item_recipe_cyle = {}
player_item_recipe_table = {}
minetest.register_on_joinplayer(function(player)
	player_pages[player:get_player_name()] = 0
	recipe_page[player:get_player_name()] = 1
	update_too_many_items(player)
	player_item_recipe[player:get_player_name()] = ""
	player_item_recipe_cyle[player:get_player_name()] = 0
	player_item_recipe_table[player:get_player_name()] = {}
end)


--cycle through items in the sidebar and allow for recipes to be read out
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local playsound = 0
	if fields.quit then
		playsound = 1
		player_item_recipe[player:get_player_name()] = ""
		player_item_recipe_cyle[player:get_player_name()] = 0
		player_item_recipe_table[player:get_player_name()] = {}
		update_too_many_items(player, nil)
	end
	if fields.PREV then
		playsound = 1
		player_pages[player:get_player_name()] = player_pages[player:get_player_name()] - 1
		if player_pages[player:get_player_name()] < 0 then
			 player_pages[player:get_player_name()] = (math.ceil(total_items/((8*6) + 1)))-1
		end
		update_too_many_items(player)
		player_item_recipe_table[player:get_player_name()] = {}
	end
	if fields.NEXT then
		playsound = 1
		player_pages[player:get_player_name()] = player_pages[player:get_player_name()] + 1
		if (math.ceil(total_items/((8*6) + 1)))-1 < player_pages[player:get_player_name()] then
			player_pages[player:get_player_name()] = 0
		end
		update_too_many_items(player)
		player_item_recipe_table[player:get_player_name()] = {}
	end
	--cycle recipes --FIX
	if fields.PREVRECIPE then
		playsound = 1
		recipe_page[player:get_player_name()] = recipe_page[player:get_player_name()] - 1
		if recipe_page[player:get_player_name()] < 1 then
			recipe_page[player:get_player_name()] = table.getn(minetest.get_all_craft_recipes(player_item_recipe[player:get_player_name()]))
		end
		update_too_many_items(player)
	end
	if fields.NEXTRECIPE then
		playsound = 1
		recipe_page[player:get_player_name()] = recipe_page[player:get_player_name()] + 1
		if recipe_page[player:get_player_name()] > table.getn(minetest.get_all_craft_recipes(player_item_recipe[player:get_player_name()])) then
			recipe_page[player:get_player_name()] = 1
		end
		update_too_many_items(player)
	end
	
	if fields.CLOSERECIPE then
		playsound = 1
		player_item_recipe[player:get_player_name()] = ""
		player_item_recipe_cyle[player:get_player_name()] = 0
		player_item_recipe_table[player:get_player_name()] = {}
		update_too_many_items(player, nil)
	end
	
	--show the recipes to the player -- THIS IS WHAT GETS RUN ON EACH ITEM BUTTON PRESS
	for item,_ in pairs(fields) do
		playsound = 1
		if item ~= "" then
			if minetest.get_all_craft_recipes(item) then
				--reset the recipe selection when selecting new item
				recipe_page[player:get_player_name()] = 1
				update_too_many_items(player,item)
			end
		end
	end
	
	--button sound for menu, can also help feel for server lag
	--make this a toggleable setting for the player
	--[[
	if playsound == 1 then
		minetest.sound_play("too_many_items_button", {
			to_player = player,
			gain = 1.0,
		})		
	end
	]]--

end)

local default_formspec = "size[14,8.5]bgcolor[#080808BB;true]background[5,5;1,1;gui_formbg.png;true]listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]list[current_player;main;0,4.25;8,1;]list[current_player;main;0,5.5;8,3;8]list[current_player;craft;1.75,0.5;3,3;]list[current_player;craftpreview;5.75,1.5;1,1;]image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]listring[current_player;main]listring[current_player;craft]image[0,4.25;1,1;gui_hb_bg.png]image[1,4.25;1,1;gui_hb_bg.png]image[2,4.25;1,1;gui_hb_bg.png]image[3,4.25;1,1;gui_hb_bg.png]image[4,4.25;1,1;gui_hb_bg.png]image[5,4.25;1,1;gui_hb_bg.png]image[6,4.25;1,1;gui_hb_bg.png]image[7,4.25;1,1;gui_hb_bg.png]"


function update_too_many_items(player, item)
	--this is the side bar of items
	local formspec = default_formspec
	local count = player_pages[player:get_player_name()] * (8*6) + 1
	for y = 0,7 do
		for x = 1,6 do
			--create a partial display of items to not crash
			if not too_many_items_table[count] then
				break
			end
			formspec = formspec.."item_image_button["..tostring(x+7)..","..tostring(y)..";1,1;"..too_many_items_table[count]..";"..too_many_items_table[count]..";]"
			count = count + 1
		end
	end
	--navigation buttons
	--page length 
	local page = (player_pages[player:get_player_name()]+1).."/"..(math.ceil(total_items/((8*6) + 1)))
	formspec = formspec.."label[10.75,8.25;"..page.."]"
	formspec = formspec.."button[9,8;1.5,1;PREV;PREV]"
	formspec = formspec.."button[12,8;1.5,1;NEXT;NEXT]"
	---
	if item ~= nil then
		player_item_recipe[player:get_player_name()] = item
	end
	
	--this is the display of recipes
	local player_item = player_item_recipe[player:get_player_name()]
	if (item ~= "" and item ~= nil) or (player_item ~= "" and player_item ~= nil) then
		local count  = 1
		local recipe = minetest.get_all_craft_recipes(player_item)
		
		
		--show the number of recipes
		formspec = formspec.."label[3,0;"..recipe_page[player:get_player_name()].."/"..table.getn(recipe).."]"

		for y = 1,3 do
			for x = 1,3 do
				if recipe[recipe_page[player:get_player_name()]] then
					local wide = recipe[recipe_page[player:get_player_name()]].width
					if wide == 0 then
						wide = 3
					end
					if x <= wide then
						
						
						if recipe[recipe_page[player:get_player_name()]]["items"][count] then
							
							local group_test = recipe[recipe_page[player:get_player_name()]]["items"][count]:gsub("group:", "")
							
							local item = recipe[recipe_page[player:get_player_name()]]["items"][count]
						
							if too_many_items_group_items[group_test] then
								
								if not player_item_recipe_table[player:get_player_name()][group_test] then
									player_item_recipe_table[player:get_player_name()][group_test] = 1
								end
								item = too_many_items_group_items[group_test][player_item_recipe_table[player:get_player_name()][group_test]]
							end
							formspec = formspec.."item_image_button["..tostring(x + 0.75)..","..tostring(y-0.5)..";1,1;"..item..";"..item..";]"
						else
							--do a blank space to preserve shape
							formspec = formspec.."item_image_button["..tostring(x + 0.75)..","..tostring(y-0.5)..";1,1;;;]"
						end
						count = count + 1
					else
						--do a blank space to preserve shape
						formspec = formspec.."item_image_button["..tostring(x + 0.75)..","..tostring(y-0.5)..";1,1;;;]"
					end
				end
			end
		end
		--output
		formspec = formspec.."item_image_button["..tostring(5.75)..","..tostring(1.5)..";1,1;"..player_item..";"..player_item..";]"
		--navigate recipes
		formspec = formspec.."button[1.5,3.4;1.5,1;PREVRECIPE;PREV]"
		formspec = formspec.."button[3.5,3.4;1.5,1;NEXTRECIPE;NEXT]"
		--remove craft recipe
		formspec = formspec.."button[6,3.4;1.5,1;CLOSERECIPE;CLOSE]"	
	end
	----
	
	
	player:set_inventory_formspec(formspec)	
end


player_cycle_timer_update = 1

print("make player_item_recipe_cyle[player:get_player_name()] a setting inside of the player's craft formspec")
--cycle the group items in the player's craft recipe table
minetest.register_globalstep(function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		player_item_recipe_cyle[player:get_player_name()] = player_item_recipe_cyle[player:get_player_name()] + dtime
		if player_item_recipe_cyle[player:get_player_name()] > player_cycle_timer_update then
			--print(player_item_recipe[player:get_player_name()])
			for group,listnumber in pairs(player_item_recipe_table[player:get_player_name()]) do
				--player_item_recipe_table[player:get_player_name()][group_test]
				player_item_recipe_table[player:get_player_name()][group] = player_item_recipe_table[player:get_player_name()][group] + 1
				if player_item_recipe_table[player:get_player_name()][group] > table.getn(too_many_items_group_items[group]) then
					player_item_recipe_table[player:get_player_name()][group] = 1
				end	
			end
			
			---table.getn(too_many_items_group_items[group_test])
			if player_item_recipe[player:get_player_name()] ~= "" then
				update_too_many_items(player, player_item_recipe[player:get_player_name()])
			end
			player_item_recipe_cyle[player:get_player_name()] = 0
			
		end
	end
end)
