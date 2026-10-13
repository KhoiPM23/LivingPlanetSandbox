class_name WorldSeed
extends RefCounted

## Manages reproducible random state and sub-stream seeds for Living Planet Sandbox.

var master_seed: int = 0
var _stream_generators: Dictionary = {}

func _init(p_seed: Variant = 0) -> void:
	set_master_seed(p_seed)

func set_master_seed(p_seed: Variant) -> void:
	if p_seed is String:
		master_seed = hash(p_seed)
	elif p_seed is int:
		master_seed = p_seed
	else:
		master_seed = hash(str(p_seed))
	_stream_generators.clear()

func get_stream_seed(stream_name: String) -> int:
	# Combine master_seed with a hash of the stream name to produce an isolated, deterministic sub-seed
	var combined_hash: int = hash(str(master_seed) + ":" + stream_name)
	return combined_hash

func get_rng(stream_name: String) -> RandomNumberGenerator:
	if not _stream_generators.has(stream_name):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = get_stream_seed(stream_name)
		_stream_generators[stream_name] = rng
	return _stream_generators[stream_name]

func reset_stream(stream_name: String) -> void:
	if _stream_generators.has(stream_name):
		_stream_generators[stream_name].seed = get_stream_seed(stream_name)

func get_stream(stream_name: String) -> RandomNumberGenerator:
	return get_rng(stream_name)
