---@alias _AssemblingMachine {e: LuaEntity, r: LuaRecipe, q: LuaQualityPrototype, c: number, b: number}
---@alias _EntityEvent {name: string, entity: LuaEntity}

-----------------------------------------
-- Memoize recipes with fluid products --
-----------------------------------------

---Returns the fluid products, if any, produced by the recipe.
---@param recipe LuaRecipePrototype
---@return FluidProduct[]
function fluid_products_for_recipe(recipe)
  local fluid_products = {}
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
  local recipe, quality = entity.get_recipe()
  storage.assembling_machines[entity.unit_number] = {
    e = entity,
    r = recipe,
    q = quality,
    c = entity.crafting_progress,
    b = entity.bonus_progress
  }
end

---Called on any event that creates an assembling machine.
---@param event _EntityEvent
function on_built_event(event)
  update_assembling_machine(event.entity)
end

---Called on any event that destroys an assembling machine.
---@param event _EntityEvent
function on_mined_event(event)
  storage.assembling_machines[event.entity.unit_number] = nil
end

local event_filters = { { filter = "type", type = "assembling-machine" } }
script.on_event(defines.events.on_built_entity, on_built_event, event_filters)
script.on_event(defines.events.on_robot_built_entity, on_built_event, event_filters)
script.on_event(defines.events.on_space_platform_built_entity, on_built_event, event_filters)
script.on_event(defines.events.on_entity_died, on_mined_event, event_filters)
script.on_event(defines.events.on_player_mined_entity, on_mined_event, event_filters)
script.on_event(defines.events.on_robot_mined_entity, on_mined_event, event_filters)
script.on_event(defines.events.on_space_platform_mined_entity, on_mined_event, event_filters)

script.on_configuration_changed(
  function(_)
    log("on_configuration_changed")
    ---@type table<number, _AssemblingMachine>
    storage.assembling_machines = {}
    for _, surface in pairs(game.surfaces) do
      local entities = surface.find_entities_filtered { type = "assembling-machine" }
      for _, entity in ipairs(entities) do
        update_assembling_machine(entity)
      end
    end
  end
)

--------------------------------------------------------------
-- Produce bonus fluids on the tick that crafting completes --
--------------------------------------------------------------

---@param machine _AssemblingMachine
---@param recipe LuaRecipe
---@param quality LuaQualityPrototype
---@param fluid_products FluidProduct[]
---@param bonus_per_quality_level number
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
        entity.insert_fluid {
          name   = product.name,
          amount = amount_to_insert
        }
      end
    end
  end
end

---@param machine _AssemblingMachine
---@param bonus_per_quality_level number
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

script.on_event(defines.events.on_tick,
  function(_)
    bonus_per_quality_level = settings.global["fluid-quality-bonus-percent"].value / 100
    if storage.assembling_machines then
      for _, machine in pairs(storage.assembling_machines) do
        on_tick_assembling_machine(machine, bonus_per_quality_level)
      end
    end
  end
)
