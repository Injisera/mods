
local meth = require("mat")--matrix stuff
global.system = {}

global.tab = global.tab or 2
--remember which tab we were on

global.scroll = global.scroll or 0 
--remember how far down we scrolled

global.location = global.location or {x=200,y=200} 
--remember where the window was

local function copy_object(obj)
  if type(obj) == "table" then
    local copy = {}
    for key,val in pairs(obj) do
      copy[key] = copy_object(val)
    end
    return copy
  else
    return obj
  end
end

local function class_system(id1)
  local system = {}
  
  function system:init(id2)
    self.name = id1 or id2 or "Temp"
    self.recipe = {}
    self.item = {}
    self.constraint = {}
  end

  system:init(id1)
  return system
end

function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function class_gui(event)
  local player = game.players[event.player_index]
  local gui = {}
  
  function gui:event_func(event,element,func)
    self.events = self.events+1
    local name = "construction-planner-" .. self.events
    element.name = name
    event[name]=func
    return element
  end

  function gui:add_choose_event(element,func)
    return self:event_func(self.choose_event,element,func)
  end

  function gui:add_text_event(element,func)
    return self:event_func(self.text_event,element,func)
  end

  function gui:add_button_event(element,func)
    return self:event_func(self.button_event,element,func)
  end



  function gui:add_system(event)
    local name = "Temp"
    table.insert(global.system,class_system(name))
    return name
  end

  function gui:calc()
    
    if next(global.system[global.tab-1].constraint) then 

      --missing 
      --move the calc thing somewhere else maybe >_> or deal with the least squares properly

      local A = {}
      
      for _,element in pairs(self.x) do
        element.clear()
      end
      for recipe_name,machines in pairs(global.system[global.tab-1].recipe) do
        local row = {}
        for key,item in pairs(global.system[global.tab-1].constraint) do
          local value = 0
          if not machines.factory or not machines.factory.name then
            game.print("exited gui:calc due to no machines.factory or no machines.factory.name")
            return nil
          end

          local machine = game.entity_prototypes[machines.factory.name]
          local recipe = game.recipe_prototypes[recipe_name]
          local productivity_fraction = 1
          local fraction = 1

          if machine.crafting_speed and recipe.energy then
            fraction = machine.crafting_speed
            local speed = 1
            if machines.factory.module then 
              for _,module in pairs(machines.factory.module) do
                local m = game.item_prototypes[module]
                if m and m.module_effects then
                  if m.module_effects.speed then
                    speed = speed+m.module_effects.speed.bonus
                  end
                  if m.module_effects.productivity then
                    productivity_fraction = productivity_fraction+m.module_effects.productivity.bonus
                  end
                end
              end
            end
            fraction = fraction*speed/recipe.energy
          end

          
          local value

          for _,product in pairs(recipe.products) do
            if product.name == key then
              local amount = 1
              if product.amount then 
                amount = product.amount
              elseif product.amount_min and product.amount_max then 
                amount = (product.amount_min+product.amount_max)/2
              end
              if product.probability then 
                amount = amount * product.probability
              end
              amount = amount*fraction*productivity_fraction
              if value then
                value = value + amount
              else
                value = amount
              end
            end
          end

          for _,ingredient in pairs(recipe.ingredients) do
            if ingredient.name == key then
              local amount = -ingredient.amount*fraction
              if value then --if it is also part of the output... subtract the input then
                value = value + amount
              else 
                value = amount
              end
            end
          end

          if not value then
            value = 0
          end
          table.insert(row,value)
        end
        table.insert(A,row)
      end

      local b = {}
      local i = 1
      for key,val in pairs(global.system[global.tab-1].constraint) do
        b[i] = val
        i = i+1
      end

      --Ax=b
      --AtAx=Atb
      --inv(AtA)AtAx = inv(AtA)Atb
      --1*x = inv(AtA)Atb

      -- x = inv(AAt)Ab (A is already pre-transposed)
      -- (inv((AAt))(Ab)) <-- order

      local part1 = meth.Ab(A,b)
      local part2 = meth.AAt(A)
      local part3 = meth.inv(part2)
      if part3 then --if we successfully calculated an inverse, let's continue
        local x = meth.Ab(part3,part1)
        for i,element in ipairs(x) do
          self.x[i].add({type="label",caption=round(element,3)})
        end
      end
    end
  end

  function gui:add_recipe_row(recipe)

    local output = self.recipe_table.add({type="flow",direction="horizontal"})
    local input = self.recipe_table.add({type="flow",direction="horizontal"})
    local factory = self.recipe_table.add({type="flow",direction="horizontal"})
    local beacon = self.recipe_table.add({type="flow",direction="horizontal"})
    local x =  self.recipe_table.add({type="flow",direction="horizontal"})

    --Ax = B 
    --x = B/A


    --game.print(type(temp_system_items))

    for _,item in pairs(recipe.products) do
      local button
      button = output.add(
        self:add_button_event({
          type="choose-elem-button",elem_type=item.type
        },function(event)
          if event.button == defines.mouse_button_type.right then

            global.system[global.tab-1].recipe[recipe.name]=nil
            for _,const in pairs(recipe.products) do
              global.system[global.tab-1].item[const.name]=global.system[global.tab-1].item[const.name]-1
              if global.system[global.tab-1].item[const.name] == 0 then
                global.system[global.tab-1].item[const.name] = nil
                global.system[global.tab-1].constraint[const.name] = nil
              end
            end

            for _,const in pairs(recipe.ingredients) do
              global.system[global.tab-1].item[const.name]=global.system[global.tab-1].item[const.name]-1
              if global.system[global.tab-1].item[const.name] == 0 then
                global.system[global.tab-1].item[const.name] = nil
                global.system[global.tab-1].constraint[const.name] = nil
              end
            end
            output.destroy()
            input.destroy()
            factory.destroy()
            beacon.destroy()
            x.destroy()
          elseif event.button == defines.mouse_button_type.left then
            game.print("LMB OI M8!")
          end
        end
        )
      )

      button.elem_value=item.name
      button.locked=true

    end

    for _,item in pairs(recipe.ingredients) do
      local button
      local filter = {
        {
          filter = "has-product-" .. item.type, --item/fluid
          elem_filters = {
            {
              filter = "name", 
              name = item.name
            }
          }
        },{
          filter = "category",
          category ="handcrafting",
          mode = "and",
          invert = true
        }
      }

      local temp = game.get_filtered_recipe_prototypes(filter)

      local recipes = 0
      for key,val in pairs(temp) do
        recipes = recipes + 1
      end

      local value
      for key,val in pairs(temp) do
        --not sure how to get the first element in a table... 
        -- very strange that I have to do this weird for thingy 
        value = val
        break--yup, begin a for loop and break out of it straight away. Dumbest thing ever.
      end

      if recipes == 0 then --should NEVER occur
        game.print("There is no recipe that can craft your item O_o")
      elseif recipes == 1 then--ONLY ONE RECIPE, just add that one! 
                
        button = input.add(
          self:add_button_event({
            type="choose-elem-button",elem_type="recipe"
          },function(event)
            if event.button == defines.mouse_button_type.left then
              self:add_recipe(value)
              --add the item you just clicked to the constraint list, you probably want to do that   
              global.system[global.tab-1].constraint[item.name]=0          
              self:destroy()
              self:init()
              --missing
              --update the constraint list instead
              --then do the calc

            end
          end
          )
        )
        button.elem_value=value.name
        button.locked=true
      else
        local old_value = value.name
        button = input.add(
          self:add_choose_event({
            type="choose-elem-button",elem_type="recipe"
          },function(event)
              if button.elem_value then 
                self:add_recipe(game.recipe_prototypes[button.elem_value])

                global.system[global.tab-1].constraint[item.name]=0
                --missing
                --update the constraint window
                --calc

                old_value = button.elem_value
              else --I just right clicked
                button.elem_value = old_value
              end
          end
          )
        )
        button.elem_filters = filter
        button.elem_value=value.name

        local num_value = button.add({type="label",caption=recipes})
        num_value.ignored_by_interaction=true
        num_value.style.font="count-font"
      end
    end
    
    local factories = {}

    local my_recipe = global.system[global.tab-1].recipe[recipe.name]

    --[
    if my_recipe.factory then
      local factory_button 
      factory_button = factory.add(
        self:add_choose_event({
          type="choose-elem-button",elem_type="entity"
        },function(event)
            if factory_button.elem_value then 
              global.system[global.tab-1].recipe[recipe.name].factory.name=factory_button.elem_value
              self:calc()
            else
              --I just rightclicked... put this shit in my hand as well!
              factory_button.elem_value = global.system[global.tab-1].recipe[recipe.name].factory.name

              local player = game.players[event.player_index]
              player.clean_cursor()--put things back into inventory so we don't destroy them
              player.cursor_ghost = factory_button.elem_value

              --[[
              player.cursor_stack.set_stack({name="blueprint", count = 1})
              player.cursor_stack.set_blueprint_entities({
                {
                  entity_number=1,
                  name="assembling-machine-1",
                  position={
                    x=0,
                    y=0
                  }
                }
              })
              --]]
              --missing 
              --building should have correct recipe already set

              --player.cursor_stack.set_stack()
              --player.cursor_ghost.recipe = "inserter"
              --missing 
              --ghost in hand
            end
          end
        )
      )
      
      factory_button.elem_filters = {
        {
          filter = "crafting-category",
          crafting_category = recipe.category
        },
      }
      
      factory_button.elem_value=my_recipe.factory.name


      local f_modules = factory.add({type="flow",direction="horizontal"})
      if my_recipe.factory.module then
        for _,module in pairs(my_recipe.factory.module) do
          
          local module_button = factory.add(
            self:add_button_event({
                type="choose-elem-button",elem_type="item"
              },function(event)
                game.print("DROPDOWN MODULES DUUUUDE!")
              end
            )
          )
          module_button.elem_value = module
          module_button.locked=true
        end
      end
    else
      game.print("error, missing factory or something yo")
    end



    if my_recipe.beacon then
      for _,beacon_obj in pairs(my_recipe.beacon) do
        beacon.add({type="sprite-button",sprite="entity/" .. beacon_obj.name, number=beacon_obj.amount })
        local b_modules = beacon.add({type="flow",direction="horizontal"})
        if beacon_obj.module then
          for _,module in pairs(beacon_obj.module) do
              b_modules.add({type="sprite-button",sprite="item/" .. module})
          end
        end
      end
    end 

    table.insert(self.x,x)
  end

  function gui:add_recipe(recipe) 

    if not global.system[global.tab-1].recipe[recipe.name] then

      local function add_item_to_system(items)
        for _,item in pairs(items) do
          if global.system[global.tab-1].item[item.name] then
            global.system[global.tab-1].item[item.name]=global.system[global.tab-1].item[item.name]+1
          else 
            global.system[global.tab-1].item[item.name] = 1
          end
        end
      end

      local temp = game.get_filtered_entity_prototypes({
        {
          filter = "crafting-category",
          crafting_category = recipe.category
        }
      })
      
      for key,value in pairs(temp) do
        temp = key
        break
      end

      global.system[global.tab-1].recipe[recipe.name]={
        factory={
          name=temp,--get the 1st machine that can craft this recipe
          module = {
          }
        }
      }


      add_item_to_system(recipe.products)
      add_item_to_system(recipe.ingredients)
      --update constraint list
      --populate_recipe
      self:add_recipe_row(recipe)
      --missing 
      --executing this function for no reason when adding
      --recipes through the top recipe-adder
    end
  end

  function gui:populate_system_tab()

    for _,tab in pairs(self.tabs) do
      tab.window.clear()--clear all windows
    end
    
    self.x = {}
    local window = self.tabs[global.tab-1].window
    window = window.add({type="scroll-pane"})
    window.style.maximal_height=600
    window = window.add({type="flow",direction="horizontal"})
    self.recipe_table = window.add({type="frame"})
    self.recipe_table = self.recipe_table.add({type="table", column_count=5})
    self.recipe_table.style.horizontal_align="center"
  
    local constrain_table = window.add({type="frame"})
    constrain_table = constrain_table.add({type="table",column_count=2, vertical_centering=false})

    self.recipe_table.add({type="sprite",sprite="item/iron-plate"})

    local input_window = self.recipe_table.add({type="flow",direction="horizontal"})
    input_window.add({type="sprite",sprite="item/iron-ore"})
    
    local recipe_choose_button
    recipe_choose_button = input_window.add(
      self:add_choose_event({
        type="choose-elem-button",elem_type="recipe"
      },function(event)
        local recipe_name = recipe_choose_button.elem_value
        if recipe_name then
          
          local new_name = "[recipe=" .. recipe_name .. "]"
          global.system[global.tab-1].name = "[font=default-large]" .. new_name .. "[/font]"
          local recipe = game.recipe_prototypes[recipe_name]   
          self:add_recipe(recipe)
          
          local prod

          for _,p in pairs(recipe.products) do
            prod = p--I don't know how to get the first item in a table other than this. Bleh.
            break
          end
          
          global.system[global.tab-1].constraint[prod.name]=1--set it to be 1 item per second 

          
          self:destroy()
          self:init()
        end
      end
      )
    )

    recipe_choose_button.elem_filters = {
      {
        filter = "category",
        category ="handcrafting",
        invert = true
      }
    }

    self.recipe_table.add({type="sprite",sprite="entity/assembling-machine-1"})
    self.recipe_table.add({type="sprite",sprite="entity/beacon"})
    self.recipe_table.add({type="sprite",sprite="entity/programmable-speaker"})

    constrain_table.add({type="sprite",sprite="constrained", size = 32})
    constrain_table.add({type="sprite",sprite="unconstrained", size = 32})

    local constrained = constrain_table.add({type="flow",direction="vertical"})
    local unconstrained = constrain_table.add({type="flow",direction="vertical"})
    
    for key,recipe in pairs(global.system[global.tab-1].recipe) do




      
      if game.recipe_prototypes[key] then
        self:add_recipe_row(game.recipe_prototypes[key])
      else
        --missing
        --recipe doesn't exist -> stop everything, mark global.system[global.tab-1] as bad
      end
    end
    
    for key,_ in pairs(global.system[global.tab-1].item) do
      local kind = "item"--figure out if it is an item or a fluid
      if game.fluid_prototypes[key] then
        kind="fluid"
      end

      local button
      local num_value

      if global.system[global.tab-1].constraint[key] then
        button = constrained.add(
          self:add_button_event({
              type="choose-elem-button",elem_type = kind
            },function(event)
              if event.button then
                if event.button == defines.mouse_button_type.right then
                  global.system[global.tab-1].constraint[key]=nil

                  
                  self:destroy()
                  self:init()
                  --missing 
                  --just update the constraint window instead of destroying + initializing the gui window
                  --and then execute self:calc()
                elseif event.button == defines.mouse_button_type.left then
                  local textfield
                  textfield = button.add(
                    self:add_text_event({
                        type="textfield",
                        text=global.system[global.tab-1].constraint[key],
                        numeric=true,
                        allow_decimal=true,
                        allow_negative=true,
                        clear_and_focus_on_right_click=true,

                      },function(event)
                        local val = tonumber(textfield.text)
                        if not val then 
                          val = 0
                        end
                        global.system[global.tab-1].constraint[key] = val
                        textfield.destroy()
                        num_value.caption = val
                        self:calc()

                        --missing
                        --we should just update the constraint window
                        --we should just call calc
                      end
                    )
                  )
                  textfield.style.width=32
                  textfield.style.height=32
                  textfield.focus()
                end
              end
            end
          )
        )
        
      else
        button = unconstrained.add(
          self:add_button_event({
              type="choose-elem-button",elem_type = kind
            },function(event)
              if event.button then
                if event.button == defines.mouse_button_type.right then
                  global.system[global.tab-1].constraint[key]=0
                  self:destroy()
                  self:init()
                  --missing 
                  --just update the constraint window
                end
              end
            end
          )
        )
      end
      num_value = button.add({type="label"})
      num_value.caption = global.system[global.tab-1].constraint[key]
      num_value.ignored_by_interaction=true
      num_value.style.font="count-font"
      button.style.width=36
      button.style.height=36
      button.elem_value = key
      button.locked=true
    end
    self:calc()--do all the magic! 
    --missing
    --calc should be split into parts...
    --one for CALCULATING 
    --one for showing the calculations
  end

  function gui:add_system_tab(name)
    local tab

    tab = self.tab.add(
      self:add_button_event({
        --missing i tooltip icon
        type="tab", caption=name,tooltip = "LMB = Select\nLMB + Shift = Rename\nLMB + Ctrl = Copy\nRMB = Remove tab"
        --[img=virtual-signal/signal-info] = i
      },function(event)
        if event.button then
          if event.button == defines.mouse_button_type.left then
            global.tab = self.tab.selected_tab_index
            if event.control then
              global.system[#global.system+1]=copy_object(global.system[global.tab-1])
              global.tab=#global.system+1
              self:destroy()
              self:init()
            end
            self:populate_system_tab()
          elseif event.button == defines.mouse_button_type.right then
            
            for i=self.tab.selected_tab_index,#global.system do
              global.system[i-1]=global.system[i]
            end

            global.system[#global.system]=nil

            if self.tab.selected_tab_index <= global.tab then
              global.tab = global.tab-1
            end

            if global.tab == 1 then 
              global.tab = 2
            end

            if not next(global.system) then
              self:add_system(event)
            end
            self:destroy()
            self:init()
          end
        end
      end
      )
    )
    tab.style.minimal_width=40

    local window = self.tab.add({type="flow", direction="horizontal"})
    self.tab.add_tab(tab,window)
    table.insert(self.tabs,{tab=tab,window=window})
  end
  
  function gui:init()
    if player.gui.screen["constructor_tool_gui"] then
      self.window = player.gui.screen["constructor_tool_gui"].destroy()
    end --if it exists... beforehand, due to an earlier save/load then just destroy it


    self.window = player.gui.screen.add({ --or just make it from scratch
      type="frame", 
      direction = "vertical", 
      name = "constructor_tool_gui",
      caption = "Construction Planner"
    })

    self.window.location = global.location
    self.window.visible=true
    self.tab = self.window.add{type="tabbed-pane"}
    self.tabs = {}
    self.choose_event = {}
    self.text_event = {}
    self.button_event = {}
    self.events = 0

    if not self.assembling_machines then
      self.assembling_machines = {}
      for _,building in pairs(game.entity_prototypes) do
        if building.type == "assembling-machine" then
          table.insert(self.assembling_machines,building)
        end
      end
    end

    local add_tab = self.tab.add(
      self:add_button_event(
        {type="tab",caption="Add",tooltip="LMB = Add tab"},
        function(event)
          if event.button and event.button == defines.mouse_button_type.left then
            self:add_system(event)
            global.tab = #global.system+1
            self:destroy()
            self:init()
          else
            self.tab.selected_tab_index = global.tab
          end 
        end
      )
    )

    self.tab.add_tab(add_tab,self.tab.add({type="label",caption="Hello there fellow traveler!"}))
    if next(global.system) then--if we do have any systems, add their tabs
      for key,system in ipairs(global.system) do
          self:add_system_tab(system.name)
      end
    else --if we got no systems, then make one! 
      self:add_system_tab(self:add_system(event))
    end
    
    self.tab.selected_tab_index=global.tab
    self:populate_system_tab()
  end

  function gui:visible()
    if self.visible == 0 then
      return false
    else
      return true
    end
  end

  function gui:destroy()
    self.window.destroy()
    self.window = nil
  end
  gui:init()
  return gui
end

local function on_gui_hotkey(event)

  if gui then 
    if gui.window.visible == true then
      gui.window.visible = false
    else
      gui.window.visible = true
    end 
  else
    gui = class_gui(event)
  end
end

local function on_gui_location_changed(event)
  if gui 
  and event 
  and event.element 
  and event.element.name == "constructor_tool_gui" then
    global.location = gui.window.location
  end
end

local function on_gui_text_confirmed(event)
  if event 
  and event.element 
  and event.element.name 
  and gui 
  and gui.text_event 
  and gui.text_event[event.element.name] then
    gui.text_event[event.element.name](event)
  end
end

local function on_gui_button_click(event)
  if event 
  and event.element 
  and event.element.name 
  and gui 
  and gui.button_event 
  and gui.button_event[event.element.name] then
    gui.button_event[event.element.name](event)
  end
end

local function on_gui_elem_changed(event)
  if event 
  and event.element 
  and event.element.name 
  and gui 
  and gui.choose_event 
  and gui.choose_event[event.element.name] then
    gui.choose_event[event.element.name](event)
  end
end

script.on_event("construction-planner-gui-hotkey", on_gui_hotkey)
script.on_event(defines.events.on_gui_location_changed,on_gui_location_changed)
script.on_event(defines.events.on_gui_click,on_gui_button_click)
script.on_event(defines.events.on_gui_elem_changed,on_gui_elem_changed)
script.on_event(defines.events.on_gui_confirmed,on_gui_text_confirmed)