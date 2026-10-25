class_name BiomeClassifier
extends RefCounted

## Explainable Whittaker-inspired ecological biome classification based on environmental state variables.

enum BiomeType {
	OCEAN,
	COASTAL_BEACH,
	WETLAND,
	TEMPERATE_MEADOW,
	BOREAL_FOREST,
	ALPINE_SUMMIT,
	ARID_SHRUBLAND
}

static func classify(temperature: float, moisture: float, elevation: float, water_level: float = 0.0) -> BiomeType:
	# 1. Marine rule
	if elevation <= water_level:
		return BiomeType.OCEAN
		
	# 2. Coastal shoreline rule
	if elevation <= water_level + 1.2:
		if moisture > 0.75:
			return BiomeType.WETLAND
		return BiomeType.COASTAL_BEACH
		
	# 3. High altitude / Alpine Summit rule (cold summit peak or alpine elevation >= 32m)
	if elevation >= 32.0 or (elevation >= 12.0 and temperature < 6.0):
		return BiomeType.ALPINE_SUMMIT
		
	# 4. Moisture and temperature matrix
	if moisture < 0.30:
		return BiomeType.ARID_SHRUBLAND
		
	if temperature < 15.0:
		# Cool climate
		if moisture >= 0.40:
			return BiomeType.BOREAL_FOREST
		else:
			return BiomeType.ARID_SHRUBLAND
	else:
		# Temperate / warm climate
		if moisture >= 0.75 and elevation < 4.0:
			return BiomeType.WETLAND
		return BiomeType.TEMPERATE_MEADOW

static func get_biome_name(type: BiomeType) -> String:
	match type:
		BiomeType.OCEAN: return "Open Ocean"
		BiomeType.COASTAL_BEACH: return "Coastal Beach"
		BiomeType.WETLAND: return "Coastal Wetland"
		BiomeType.TEMPERATE_MEADOW: return "Temperate Meadow"
		BiomeType.BOREAL_FOREST: return "Boreal Pine Forest"
		BiomeType.ALPINE_SUMMIT: return "Alpine Granite Summit"
		BiomeType.ARID_SHRUBLAND: return "Arid Shrubland"
		_: return "Unknown Biome"

static func get_biome_color(type: BiomeType) -> Color:
	match type:
		BiomeType.OCEAN: return Color(0.08, 0.28, 0.52)
		BiomeType.COASTAL_BEACH: return Color(0.86, 0.80, 0.62)
		BiomeType.WETLAND: return Color(0.32, 0.50, 0.35)
		BiomeType.TEMPERATE_MEADOW: return Color(0.36, 0.62, 0.26)
		BiomeType.BOREAL_FOREST: return Color(0.20, 0.42, 0.22)
		BiomeType.ALPINE_SUMMIT: return Color(0.68, 0.70, 0.75)
		BiomeType.ARID_SHRUBLAND: return Color(0.72, 0.65, 0.42)
		_: return Color(0.5, 0.5, 0.5)

static func explain_biome(type: BiomeType, temp: float, moist: float, elev: float) -> String:
	match type:
		BiomeType.OCEAN:
			return "Submerged below waterline (Elev: %.1fm <= 0.0m)" % elev
		BiomeType.COASTAL_BEACH:
			return "Low coastal fringe (Elev: %.1fm, Moist: %.0f%%)" % [elev, moist * 100.0]
		BiomeType.WETLAND:
			return "Waterlogged lowland (Elev: %.1fm, High moisture: %.0f%%)" % [elev, moist * 100.0]
		BiomeType.TEMPERATE_MEADOW:
			return "Mild climate and balanced moisture (%.1f°C, %.0f%% moist)" % [temp, moist * 100.0]
		BiomeType.BOREAL_FOREST:
			return "Cool temperatures and fertile soil (%.1f°C, %.0f%% moist)" % [temp, moist * 100.0]
		BiomeType.ALPINE_SUMMIT:
			return "Cold summit peak exposed to frost (%.1f°C, Elev: %.1fm)" % [temp, elev]
		BiomeType.ARID_SHRUBLAND:
			return "Dry, moisture-deficient zone (%.0f%% moist, %.1f°C)" % [moist * 100.0, temp]
		_:
			return "Unclassified environmental conditions"
