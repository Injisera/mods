
local function on_tool_hotkey(event)
  local player = game.players[event.player_index]
	player.clean_cursor()--put things back into inventory so we don't destroy them
  if player.cursor_stack ~= nil then --being an observer sets it to nil
		player.cursor_stack.clear()
		player.cursor_stack.set_stack({name="construction-planner-item", count = 1})
	end
end

local function dead_print(num,str)
  if num>0 then
    local is,s
    if num == 1 then
      s = ""
      is = "is"
    else
      is = "are"
      s = "s"
    end
    game.print("There " .. is .. " ".. num .. " " .. str .. s .. " missing a recipe")
  end
end


local function on_selection(event)
  if event.item == "construction-planner-item" then
    local player = game.players[event.player_index]
    player.clean_cursor() --throw away the planner

    -- reset all entries for some table
    local dead_miner = 0
    local dead_furnace = 0
    local dead_assembling_machine = 0

    for _,e in pairs(event.entities) do
      local recipe = nil
      local input 
      local output
      local speed 
      local time

      local type
      if e.type == "mining-drill" then
        recipe = e.mining_target
        if recipe == nil then
          dead_miner = dead_miner+1
        else 
          speed = 1 -- mining_speed doesn't exist? :S 
          time = 1  --mining_time doesn't exist :S
          --mining_target.prototype.mineable_properties.mining_time
          --LOL
          --hmm.. speed kanske är.... e.prototype.mining_speed? 
          output = {recipe}--need to encapsulate due to for loop later
          input = {{name= 0}}
        end
        --game.print(recipe.name)//iron ore
        
      elseif e.type == "entity-ghost" then --unghost ghosts
        type = e.ghost_type
      else 
        type = e.type
      end

      if type == "furnace" then
        recipe = e.get_recipe()
        if recipe == nil then
          recipe = e.previous_recipe
        end
        if recipe == nil then
          dead_furnace = dead_furnace+1
        else 
          output = recipe.products
          input = recipe.ingredients
          speed = e.crafting_speed
          time = recipe.energy

        end
      elseif type == "assembling-machine" then
        recipe = e.get_recipe()
        if recipe == nil then
          dead_assembling_machine = dead_assembling_machine+1
        else 
          output = recipe.products
          input = recipe.ingredients
          speed = e.crafting_speed
          time = recipe.energy
        end
      end

      if recipe ~= nil then
        game.print("speed = " .. speed .. " time = " .. time)
        for _,s in pairs(output) do
          game.print(s.name)
        end
        for _,s in pairs(input) do
          game.print(s.name)
        end
        --måste fixa något så jag kan ta hand om minern...
      end
    end
    dead_print(dead_miner,"miner")
    dead_print(dead_furnace,"furnace")
    dead_print(dead_assembling_machine,"assembly machine")
  end
end

script.on_event(defines.events.on_player_selected_area, on_selection)
script.on_event("construction-planner-tool-hotkey", on_tool_hotkey)
script.on_event(defines.events.on_lua_shortcut, on_tool_hotkey) --let both go to the same function