# Mobs Chaos NPCs

A Luanti (Minetest) mod built on the `mobs` API. This mod introduces Humans and Orc factions, interactive Chaos Chests, and physically simulated falling structural blocks.

## Installation

This mod requires `mobs` as a strict dependency. To install:
1. Ensure `mobs` is installed and enabled in your world.
2. Clone or place this mod's folder (`mobs_chaos_npcs`) into your Minetest `mods/` directory.
3. Enable `mobs_chaos_npcs` in your world configuration.

## Features

- **Falling Blocks**: Adds physical structural blocks (Barrels, Chairs, Tables, Wood Structures) that behave like sand and will fall if unsupported. They can be broken by hand and are colorable.
- **Chaos Chest**: An animated storage chest with a 0.05s buffered continuous timeline animation, capable of storing items including the new falling blocks.
- **Human Faction**: Friendly toward players and other Humans. They will aggressively attack non-humans.
- **Orc Faction**: Hostile to players, Humans, and other non-orc mobs. Only friendly to other Orcs.
- **Destructive Pathing**: Both Humans and Orcs will smash through any non-dirt node they collide with while pathing or attacking.

## Usage Guide

- **Chaos Chest**: Right-click the chest to open its inventory. This will trigger its open animation. When the formspec is closed, the chest will play its close animation. It functions identically to a default chest.
- **Spawn Eggs**: You can spawn Humans and Orcs using their respective spawn eggs provided in your inventory/creative menu.
- **Falling Blocks**: Place the new blocks (Barrels, Chairs, Tables, Wood Structures) anywhere. If the node beneath them is removed, they will fall.

## Licensing & Attribution

This mod uses two distinct licenses for the source code and assets to ensure open-source compliance.

- **Code**: All Lua code is licensed under the **MIT License**. Copyright (c) 2026 ronrob-lu. (See `LICENSE` file for details).
- **Assets (3D Models & Textures)**: All `.obj` and `.glb` models, as well as the texture palettes, were created by and obtained from **Kenney.nl**. They are licensed under **CC0 1.0 Universal (Public Domain Dedication)**. We extend our thanks and credit to Kenney.nl for these fantastic assets!
