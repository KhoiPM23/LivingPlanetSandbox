extends RefCounted

func test_seed_determinism() -> Variant:
	var seed_a: WorldSeed = WorldSeed.new("PLANET_SEED_ALPHA")
	var seed_b: WorldSeed = WorldSeed.new("PLANET_SEED_ALPHA")
	
	if seed_a.master_seed != seed_b.master_seed:
		return "Seeds with same input must match: %d != %d" % [seed_a.master_seed, seed_b.master_seed]
		
	var rng_a: RandomNumberGenerator = seed_a.get_rng("terrain")
	var rng_b: RandomNumberGenerator = seed_b.get_rng("terrain")
	
	for i in range(10):
		var val_a: float = rng_a.randf()
		var val_b: float = rng_b.randf()
		if not is_equal_approx(val_a, val_b):
			return "Stream values diverged at iteration %d: %f != %f" % [i, val_a, val_b]
			
	return null

func test_stream_isolation() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(123456)
	var rng_terrain: RandomNumberGenerator = seed_obj.get_rng("terrain")
	var rng_vegetation: RandomNumberGenerator = seed_obj.get_rng("vegetation")
	
	var val_t: float = rng_terrain.randf()
	var val_v: float = rng_vegetation.randf()
	
	if is_equal_approx(val_t, val_v):
		return "Different streams should not produce identical first values"
		
	return null
