class_name WorldGenerationConfig
extends RefCounted

## Fully reproducible configuration parameters for procedural world generation & environmental baseline.

@export var seed_val: int = 1337
@export var island_size: float = 160.0
@export var resolution: int = 128
@export var max_height: float = 24.0
@export var water_level: float = 0.0
@export var roughness: float = 0.5 # Fractal gain
@export var vegetation_density: float = 1.0
@export var base_temperature: float = 22.0 # Sea-level baseline temperature in °C
@export var base_moisture: float = 0.65 # Sea-level base humidity [0.0, 1.0]
@export var lapse_rate: float = 0.55 # °C cooling per meter elevation

func _init(p_seed: int = 1337) -> void:
	seed_val = p_seed

func clamp_values() -> void:
	island_size = clamp(island_size, 40.0, 1000.0)
	resolution = clampi(resolution, 32, 256)
	max_height = clamp(max_height, 5.0, 60.0)
	water_level = clamp(water_level, -10.0, 10.0)
	roughness = clamp(roughness, 0.1, 0.9)
	vegetation_density = clamp(vegetation_density, 0.1, 3.0)
	base_temperature = clamp(base_temperature, -15.0, 45.0)
	base_moisture = clamp(base_moisture, 0.05, 1.0)
	lapse_rate = clamp(lapse_rate, 0.1, 1.5)

func is_valid() -> bool:
	return (
		island_size >= 40.0 and island_size <= 1000.0 and
		resolution >= 32 and resolution <= 256 and
		max_height > water_level and
		roughness > 0.0 and roughness < 1.0 and
		vegetation_density > 0.0 and
		base_temperature >= -20.0 and base_temperature <= 50.0 and
		base_moisture >= 0.0 and base_moisture <= 1.0
	)

func to_dict() -> Dictionary:
	return {
		"seed_val": seed_val,
		"island_size": island_size,
		"resolution": resolution,
		"max_height": max_height,
		"water_level": water_level,
		"roughness": roughness,
		"vegetation_density": vegetation_density,
		"base_temperature": base_temperature,
		"base_moisture": base_moisture,
		"lapse_rate": lapse_rate
	}

static func from_dict(dict: Dictionary) -> WorldGenerationConfig:
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new()
	cfg.seed_val = dict.get("seed_val", 1337)
	cfg.island_size = dict.get("island_size", 160.0)
	cfg.resolution = dict.get("resolution", 128)
	cfg.max_height = dict.get("max_height", 24.0)
	cfg.water_level = dict.get("water_level", 0.0)
	cfg.roughness = dict.get("roughness", 0.5)
	cfg.vegetation_density = dict.get("vegetation_density", 1.0)
	cfg.base_temperature = dict.get("base_temperature", 22.0)
	cfg.base_moisture = dict.get("base_moisture", 0.65)
	cfg.lapse_rate = dict.get("lapse_rate", 0.55)
	cfg.clamp_values()
	return cfg
