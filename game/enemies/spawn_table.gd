class_name SpawnTable
extends Resource
## What can appear at a spawn point. Each reset rolls one entry by weight.
## Files live in data/spawns/. Leave a scene empty for "nothing this time".

@export var scenes: Array[PackedScene] = []
## Relative chance of each entry (same order as scenes).
@export var weights := PackedFloat32Array()
## How many of it (min, max) for each entry.
@export var counts := PackedVector2Array()


## Roll: returns [scene, count] (scene may be null = nothing).
func roll(rng: RandomNumberGenerator) -> Array:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in scenes.size():
		r -= weights[i] if i < weights.size() else 1.0
		if r <= 0.0:
			var c := counts[i] if i < counts.size() else Vector2(1, 1)
			return [scenes[i], rng.randi_range(int(c.x), int(c.y))]
	return [null, 0]
