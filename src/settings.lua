data:extend({
  {
    type = "int-setting",
    name = "fluid-quality-bonus-percent",
    default_value = 50,
    minimum_value = 0,
    maximum_value = 500,
    setting_type = "runtime-global",
  },
  {
    type = "int-setting",
    name = "fluid-quality-bonus-tick-modulus",
    default_value = 1,
    allowed_values = { 1, 2, 4, 8, 16, 32, 64, 128, 256 },
    setting_type = "runtime-global",
  },
})
