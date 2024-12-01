# Fluid Quality Bonus

This repo contains a mod for the game Factorio which provides bonus
output for fluid products when crafting recipes with quality ingredients.
The bonus scales linearly with quality level, and starts at +20% for uncommon
quality, up to +100% for legendary quality.

For example, making holmium solution with rare stone and rare holmium ore
will yield 140 fluid output instead of just 100.

Solid products are not affected, so while making molten iron from legendary
calcite will yield 500 fluid instead of 250, it won't produce any more stone.

This mod exists because of a perceived deficiency in the quality system
as of game version 2.0.21, where solid ingredients of higher quality
have no effect whatsoever on fluid products. This is particularly noticeable
with holmium ore and ice on Fulgora, which can easily gain quality from
mining drills and recyclers, but this quality confers no benefit despite
adding logistical complexity.

## Building

The mod is built using a [Go](https://go.dev) program, so you need to first
[install Go](https://go.dev/dl/).

Once installed, `go run .` will produce a ZIP file directly, and
`go run . - install` will do the same and also place it in the game's `mods`
folder.

# To Do

- Support "set recipe" from circuit network
    - Need to use `AssemblingMachineControlBehavior` and undocumented field
      `quality` of `Signal` type
