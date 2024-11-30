-- shared: common elements used by other scripts

local shared = {}

function shared.bonus_per_quality_level()
  return settings.startup["fluid-quality-bonus-percent"].value / 100
end

function shared.fluid_products_for_recipe(recipe_products)
  local fluid_products = {}
  for _, product in ipairs(recipe_products) do
    if product.type == "fluid" and product.amount then
      fluid_products[#fluid_products + 1] = product
    end
  end
  if #fluid_products > 0 then
    return fluid_products
  else
    return nil
  end
end

function shared.generated_recipe_name(recipe, quality)
  return string.format("FQB%d_%s", quality.level, recipe.name)
end

function shared.is_generated_recipe(recipe_name)
  if string.find(recipe_name, "^FQB[-]?%d+_") then
    return true
  else
    return false
  end
end

function shared.shallow_copy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

return shared
