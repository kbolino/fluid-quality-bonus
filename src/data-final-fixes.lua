-- data-fixes-final: for every recipe that outputs a fluid product, add hidden
-- quality-scaled versions for use later (prefixed with "FQB{N}_" for quality
-- level {N})

local shared = require("shared")

bonus_per_quality_level = shared.bonus_per_quality_level()

for recipe_name, recipe in pairs(data.raw["recipe"]) do
  local new_recipes = {}
  if recipe.results and not shared.is_generated_recipe(recipe_name) then
    local fluid_products = shared.fluid_products_for_recipe(recipe.results)
    if fluid_products then
      for quality_name, quality in pairs(data.raw["quality"]) do
        local new_recipe = shared.shallow_copy(recipe)
        local new_products = {}
        for i, product in ipairs(recipe.results) do
          if product.type == "fluid" and product.amount then
            local new_product = shared.shallow_copy(product)
            local bonus_amount = product.amount * bonus_per_quality_level * quality.level
            log(string.format("bonus_amount = %f", bonus_amount))
            new_product.amount = product.amount + bonus_amount
            new_products[i] = new_product
          else
            new_products[i] = product
          end
        end
        local recipe_lname = recipe.localised_name
        if not recipe_lname then
          recipe_lname = {string.format("recipe-name.%s", recipe_name)}
          if recipe.main_product then
            -- TODO: main product could be an item instead of a fluid
            -- TODO: main_product can be empty instead of nil if there's only one product
            recipe_lname = {"?", recipe_lname, {string.format("fluid-name.%s", recipe.main_product)}}
          end
        end
        new_recipe.localised_name = {
          "",
          recipe_lname,
          " (",
          {string.format("quality-name.%s", quality_name)},
          ")"
        }
        new_recipe.enabled = true
        new_recipe.hidden = true
        new_recipe.results = new_products
        local new_name = shared.generated_recipe_name(recipe, quality)
        new_recipe.name = new_name
        new_recipes[#new_recipes + 1] = new_recipe
        log(string.format("created new recipe %s", serpent.line(new_recipe)))
      end
    end
  end
  if #new_recipes > 0 then
    data:extend(new_recipes)
  end
end
