-- TODO: export as setting
bonus_per_quality_level = 0.2

function fluid_products_for_recipe(recipe)
  local fluid_products = {}
  for i, product in ipairs(recipe.products) do
    if product.type == 'fluid' and product.amount then
      fluid_products[#fluid_products + 1] = product
    end
  end
  return fluid_products
end

function calculate_and_insert_bonus_fluids(machine, recipe, quality, fluid_products)
  local bonuses = 0
  local prev = storage.prev_entities[machine.unit_number]
  if prev and prev.r == recipe and prev.q == quality then
    if machine.crafting_progress < prev.c then
      bonuses = bonuses + 1
    end
    if machine.bonus_progress < prev.b then
      bonuses = bonuses + 1
    end
    bonuses = bonuses * quality.level
    if bonuses > 0 then
      for _, product in ipairs(fluid_products) do
        local amount_to_insert = bonus_per_quality_level * bonuses * product.amount
        machine.insert_fluid{
          name   = product.name,
          amount = amount_to_insert
        }
      end
    end
  end
end

function on_tick_assembling_machine(machine)
  local recipe, quality = machine.get_recipe()
  if recipe and quality then
    local fluid_products = fluid_products_for_recipe(recipe)
    if #fluid_products > 0 then
      calculate_and_insert_bonus_fluids(machine, recipe, quality, fluid_products)
      return {
        r = recipe,
        q = quality,
        c = machine.crafting_progress,
        b = machine.bonus_progress
      }
    end
  end
  return nil
end

function on_tick_surface(surface, entities_out)
  local assembling_machines = surface.find_entities_filtered{
    type = 'assembling-machine'
  }
  for _, machine in ipairs(assembling_machines) do
    local entity = on_tick_assembling_machine(machine)
    if entity then
      entities_out[machine.unit_number] = entity
    end
  end
end

script.on_event(defines.events.on_tick,
  function (event)
    if not storage.prev_entities then
      storage.prev_entities = {}
    end
    local cur_entities = {}
    for _, surface in pairs(game.surfaces) do
      on_tick_surface(surface, cur_entities)
    end
    storage.prev_entities = cur_entities
  end
)
