# Fluid Quality Bonus

This repo contains a mod for the game Factorio which provides bonus
output for fluid products when crafting recipes with quality ingredients.
The bonus scales linearly with quality level, and starts at +50% for uncommon
quality, up to +250% for legendary quality.

For example, making holmium solution with rare stone and rare holmium ore
will yield 200 fluid output instead of just 100.

Solid products are not affected, so while making molten iron from legendary
calcite will yield 875 fluid instead of 250, it won't produce any more stone.

This mod exists because of a perceived deficiency in the quality system
as of game version 2.0.55, where solid ingredients of higher quality
have no effect whatsoever on fluid products. This is particularly noticeable
with holmium ore and ice on Fulgora, which can easily gain quality from
mining drills and recyclers, but this quality confers no benefit despite
adding logistical complexity.

## Building

The mod is built using a [Go](https://go.dev) program, so you need to first
[install Go](https://go.dev/dl/).

See `build.ps1` for an example command to build the mod.

## Performance

This mod tries not to do more than necessary, but will likely reduce UPS
for larger factories, because the only event it can listen for is `on_tick`,
and it has to save crafting state for all relevant machines in order to detect
when a crafting cycle completes.

Some performance can be regained by increasing the `tick-modulus` setting as
the number of assembling machines grows.
