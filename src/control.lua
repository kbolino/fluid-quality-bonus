---Locally tracked state of an assembling machine. Keys:
---* e is the entity
---* f is the number of products finished as of the last bonus
---* r was the recipe as of ..
---* q was the quality as of ..
---* p was the crafting_progress as of ..
---* b was the bonus_progress as of ..
---@alias _AssemblingMachine {e: LuaEntity, f: number}
---@alias _EntityEvent {name: string, entity: LuaEntity} | {name: string, source: LuaEntity, destination: LuaEntity}

-----------------------------------------
-- Memoize recipes with fluid products --
-----------------------------------------

---Returns the fluid products, if any, produced by the recipe.
---@param recipe LuaRecipePrototype
---@return FluidProduct[]
function fluid_products_for_recipe(recipe)
  local fluid_products = {}
  if string.find(recipe.name, "^empty-.*-barrel$") then
    return {}
  end
  for _, product in ipairs(recipe.products) do
    if product.type == "fluid" and product.amount then
      fluid_products[#fluid_products + 1] = product
    end
  end
  return fluid_products
end

---Map of names of recipes with fluid products to their fluid products.
---@type table<string, FluidProduct[]>
local recipes_with_fluid_products = {}

for recipe_name, recipe in pairs(prototypes.recipe) do
  local fluid_products = fluid_products_for_recipe(recipe)
  if #fluid_products > 0 then
    recipes_with_fluid_products[recipe_name] = fluid_products
  end
end

-----------------------------------
-- Track all assembling machines --
-----------------------------------

---Updates the tracked parameters of an assembling machine.
---@param entity LuaEntity
function update_assembling_machine(entity)
  storage.assembling_machines[entity.unit_number] = {
    e = entity,
    f = entity.products_finished,
  }
end

---Called on any event that creates an assembling machine.
---@param event _EntityEvent
function on_entity_created(event)
  local entity = event.entity
  if not entity then
    entity = event.destination
  end
  update_assembling_machine(entity)
end

---Called on any event that destroys an assembling machine.
---@param event _EntityEvent
function on_entity_destroyed(event)
  storage.assembling_machines[event.entity.unit_number] = nil
end

local event_filters = { { filter = "type", type = "assembling-machine" } }

script.on_event(defines.events.on_built_entity, on_entity_created, event_filters)
script.on_event(defines.events.on_entity_cloned, on_entity_created, event_filters)
script.on_event(defines.events.on_robot_built_entity, on_entity_created, event_filters)
script.on_event(defines.events.on_space_platform_built_entity, on_entity_created, event_filters)
script.on_event(defines.events.script_raised_built, on_entity_created, event_filters)
script.on_event(defines.events.script_raised_revive, on_entity_created, event_filters)

script.on_event(defines.events.on_entity_died, on_entity_destroyed, event_filters)
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed, event_filters)
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed, event_filters)
script.on_event(defines.events.on_space_platform_mined_entity, on_entity_destroyed, event_filters)
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed, event_filters)

script.on_configuration_changed(function(_)
  log("on_configuration_changed")
  if not storage.assembling_machines then
    ---@type table<number, _AssemblingMachine>
    storage.assembling_machines = {}
  end
  for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered { type = "assembling-machine" }
    for _, entity in ipairs(entities) do
      machine = storage.assembling_machines[entity.unit_number]
      if machine == nil or machine.f == nil then
        update_assembling_machine(entity)
      end
    end
  end
end)

-----------------------------------------------------------
-- Produce bonus fluids based on newly finished products --
-----------------------------------------------------------

---@param machine _AssemblingMachine
---@param bonus_per_quality_level number
function calculate_and_insert_bonus_fluids(machine, bonus_per_quality_level)
  local entity = machine.e
  local recipe, quality = entity.get_recipe()
  if recipe == nil or
      quality == nil or
      quality.level == 0 or
      entity.products_finished <= machine.f
  then
    return
  end
  local fluid_products = recipes_with_fluid_products[recipe.name]
  if fluid_products == nil then
    return
  end
  local new_products = entity.products_finished - machine.f
  local bonus_multiplier = bonus_per_quality_level * new_products * quality.level
  for _, product in ipairs(fluid_products) do
    entity.insert_fluid {
      name   = product.name,
      amount = bonus_multiplier * product.amount / 100
    }
  end
end

script.on_event(defines.events.on_tick,
  function(event)
    local bonus_per_quality_level = settings.global["fluid-quality-bonus-percent"].value + 0
    local tick_modulus = settings.global["fluid-quality-bonus-tick-modulus"].value + 0
    local tick = event.tick % tick_modulus
    for id, machine in pairs(storage.assembling_machines) do
      local entity = machine.e
      if not entity.valid then
        storage.assembling_machines[id] = nil
      elseif id % tick_modulus == tick then
        calculate_and_insert_bonus_fluids(machine, bonus_per_quality_level)
        update_assembling_machine(entity)
      end
    end
  end
)
