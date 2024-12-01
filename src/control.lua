-- memoize recipes with fluid products

function fluid_products_for_recipe(recipe)
  local fluid_products = {}
  for _, product in ipairs(recipe.products) do
    if product.type == "fluid" and product.amount then
      fluid_products[#fluid_products + 1] = product
    end
  end
  return fluid_products
end

local recipes_with_fluid_products = {}

for recipe_name, recipe in pairs(prototypes.recipe) do
  local fluid_products = fluid_products_for_recipe(recipe)
  if fluid_products then
    recipes_with_fluid_products[recipe_name] = fluid_products
  end
end

-- set up and register event handlers

function calculate_and_insert_bonus_fluids(machine, recipe, quality, fluid_products, bonus_per_quality_level)
  local bonuses = 0
  local entity = machine.e
  if machine.r == recipe and machine.q == quality then
    if entity.crafting_progress < machine.c then
      bonuses = bonuses + 1
    end
    if entity.bonus_progress < machine.b then
      bonuses = bonuses + 1
    end
    bonuses = bonuses * quality.level
    if bonuses > 0 then
      for _, product in ipairs(fluid_products) do
        local amount_to_insert = bonus_per_quality_level * bonuses * product.amount
        entity.insert_fluid{
          name   = product.name,
          amount = amount_to_insert
        }
      end
    end
  end
end

function on_tick_assembling_machine(machine, bonus_per_quality_level)
  local entity = machine.e
  local recipe, quality = entity.get_recipe()
  if recipe and quality then
    local fluid_products = recipes_with_fluid_products[recipe.name]
    if fluid_products then
      calculate_and_insert_bonus_fluids(machine, recipe, quality, fluid_products, bonus_per_quality_level)
      update_assembling_machine(entity)
    end
  end
  return nil
end

function update_assembling_machine(entity)
  local recipe, quality = entity.get_recipe()
  storage.assembling_machines[entity.unit_number] = {
    e = entity,
    r = recipe,
    q = quality,
    c = entity.crafting_progress,
    b = entity.bonus_progress
  }
end

function on_built_event(event)
  update_assembling_machine(event.entity)
end

function on_mined_event(event)
  storage.assembling_machines[event.entity.unit_number] = nil
end

local event_filters = {{filter = "type", type = "assembling-machine"}}
script.on_event(defines.events.on_built_entity, on_built_event, event_filters)
script.on_event(defines.events.on_robot_built_entity, on_built_event, event_filters)
script.on_event(defines.events.on_space_platform_built_entity, on_built_event, event_filters)
script.on_event(defines.events.on_entity_died, on_mined_event, event_filters)
script.on_event(defines.events.on_player_mined_entity, on_mined_event, event_filters)
script.on_event(defines.events.on_robot_mined_entity, on_mined_event, event_filters)
script.on_event(defines.events.on_space_platform_mined_entity, on_mined_event, event_filters)

script.on_event(defines.events.on_tick,
  function(event)
    bonus_per_quality_level = settings.global["fluid-quality-bonus-percent"].value / 100
    if storage.assembling_machines then
      for _, machine in pairs(storage.assembling_machines) do
        on_tick_assembling_machine(machine, bonus_per_quality_level)
      end
    end
  end
)

script.on_configuration_changed(
  function(data)
    log("on_configuration_changed")
    storage.assembling_machines = {}
    for _, surface in pairs(game.surfaces) do
      local entities = surface.find_entities_filtered{type = "assembling-machine"}
      for _, entity in ipairs(entities) do
        update_assembling_machine(entity)
      end
    end
  end
)
