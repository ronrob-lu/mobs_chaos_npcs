def print_anims(anims, padding=0.05):
    curr = 0.0
    for name, dur in anims:
        start = curr + padding
        end = start + dur
        print(f"  {name.replace('-', '_')} = {{x = {start:.3f}, y = {end:.3f}}},")
        curr = end

print("Humans:")
human_anims = [
    ("static", 0.100),
    ("idle", 1.333),
    ("walk", 0.667),
    ("sprint", 0.500),
    ("jump", 0.500),
    ("fall", 0.333),
    ("crouch", 0.167),
    ("sit", 0.167),
    ("drive", 0.167),
    ("die", 0.333),
    ("pick-up", 0.333),
    ("emote-yes", 0.667),
    ("emote-no", 0.667),
    ("holding-right", 0.167),
    ("holding-left", 0.167),
    ("holding-both", 0.167),
    ("holding-right-shoot", 0.200),
    ("holding-left-shoot", 0.200),
    ("holding-both-shoot", 0.200),
    ("attack-melee-right", 0.417),
    ("attack-melee-left", 0.417),
    ("attack-kick-right", 0.533),
    ("attack-kick-left", 0.533),
    ("interact-right", 0.667),
    ("interact-left", 0.667),
    ("wheelchair-sit", 0.167),
    ("wheelchair-look-left", 0.333),
    ("wheelchair-look-right", 0.333),
    ("wheelchair-move-forward", 0.500),
    ("wheelchair-move-back", 0.500),
    ("wheelchair-move-left", 0.500),
    ("wheelchair-move-right", 0.500),
]
print_anims(human_anims)

print("Chest:")
chest_anims = [
    ("open", 0.300),
    ("close", 1.000),
    ("open-close", 1.300)
]
print_anims(chest_anims)
