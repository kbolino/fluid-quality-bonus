-- TODO: export as setting
bonus_per_quality_level = 0.2

script.on_event(defines.events.on_tick,
  function (event)
    if not storage.prev_entities then
      storage.prev_entities = {}
    end
    local cur_entities = {}
    for _, surface in pairs(game.surfaces) do
      local assembling_machines = surface.find_entities_filtered{
        type = 'assembling-machine'
      }
      for _, machine in ipairs(assembling_machines) do
        local id = machine.unit_number
        local recipe, quality = machine.get_recipe()
        if recipe and quality then
          local fluid_products = {}
          for i, product in ipairs(recipe.products) do
            if product.type == 'fluid' and product.amount then
              fluid_products[#fluid_products + 1] = product
            end
          end
          if #fluid_products > 0 then
            local crafting_progress = machine.crafting_progress
            local bonus_progress = machine.bonus_progress
            cur_entities[id] = {
              r = recipe,
              q = quality,
              c = crafting_progress,
              b = bonus_progress
            }
            local bonuses = 0
            local prev = storage.prev_entities[id]
            if prev and prev.r == recipe and prev.q == quality then
              if crafting_progress < prev.c then
                bonuses = bonuses + 1
              end
              if bonus_progress < prev.b then
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
        end
      end
    end
    storage.prev_entities = cur_entities
  end
)
