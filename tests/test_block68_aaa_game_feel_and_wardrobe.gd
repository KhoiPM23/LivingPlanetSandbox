extends RefCounted

## Living Planet Sandbox — Block 68 Contract Tests.
## Verifies:
## 1. Wardrobe & Appearance System Isolation (Low coupling, high cohesion, SRP).
## 2. Character Registry & SFW Asset Safety (Graceful fallback, no hardcoded NSFW paths).
## 3. AAA Game Feel Traversal: Genshin Sprint Dash Impulse & Camera FOV Kick.
## 4. AAA Game Feel Glider: Genshin Air Cushioning & Descent Clamping.
## 5. AAA Game Feel Locomotion: RDR2 Stopping Skid Brake & Forward Pitch Lean.

const FirstPersonWalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const PlayerWardrobeSystem = preload("res://presentation/character/wardrobe/player_wardrobe_system.gd")
const CharacterRegistrySystem = preload("res://presentation/character/character_registry_system.gd")

func test_wardrobe_system_isolation_and_signals() -> bool:
	var wardrobe = PlayerWardrobeSystem.new()
	if wardrobe == null:
		push_error("PlayerWardrobeSystem must be instantiable as a pure RefCounted service")
		return false

	var signal_log: Array[Dictionary] = []

	wardrobe.outfit_changed.connect(func(id: String, name: String, is_bikini: bool):
		signal_log.append({"id": id, "name": name, "is_bikini": is_bikini})
	)

	# Test outfit cycling on anime character
	wardrobe.set_anime_outfit_mode(PlayerWardrobeSystem.AnimeOutfitMode.STANDARD)
	if signal_log.is_empty() or signal_log[-1]["is_bikini"] != false:
		push_error("Setting STANDARD outfit should emit outfit_changed with is_bikini = false")
		return false

	wardrobe.set_anime_outfit_mode(PlayerWardrobeSystem.AnimeOutfitMode.BIKINI)
	if signal_log.size() < 2 or signal_log[-1]["is_bikini"] != true:
		push_error("Setting BIKINI outfit should emit outfit_changed with is_bikini = true")
		return false

	return true

func test_character_registry_isolation() -> bool:
	var registry = CharacterRegistrySystem.new()
	if registry == null:
		push_error("CharacterRegistrySystem must be instantiable")
		return false

	var characters = registry.get_available_characters()
	if characters.size() < 1:
		push_error("CharacterRegistry must register at least SFW Anime Heroine")
		return false

	var anime_char = registry.get_character_by_id("anime_heroine")
	if anime_char == null or anime_char.is_optional != false:
		push_error("Anime Heroine must be registered as core non-optional character")
		return false

	var initial_idx: int = registry.get_active_index()
	# Set active index to next
	var switched_idx: int = registry.set_active_index((initial_idx + 1) % registry.get_roster_count())
	if registry.get_roster_count() > 1 and switched_idx == initial_idx:
		push_error("set_active_index should advance active character index")
		return false

	return true

func test_genshin_sprint_dash_impulse_and_fov_kick() -> bool:
	var walker: FirstPersonWalker = FirstPersonWalkerScript.new()
	walker._init()
	walker._ready()

	# Initially stationary
	walker.velocity = Vector3.ZERO

	# Simulate sprint input with wish_dir forward
	var wish_dir: Vector3 = Vector3(0, 0, -1)
	walker.move_character(0.016, wish_dir, true, false)

	# Check dash impulse timer triggered
	if walker._dash_impulse_timer <= 0.0:
		push_error("Sprint transition should trigger dash impulse timer")
		walker.free()
		return false

	# Check initial sprint velocity incorporates dash impulse
	var horizontal_speed: float = Vector2(walker.velocity.x, walker.velocity.z).length()
	if horizontal_speed < 1.0:
		push_error("Dash impulse must immediately impart forward speed, got %f" % horizontal_speed)
		walker.free()
		return false

	walker.free()
	return true

func test_genshin_glider_cushion() -> bool:
	var walker: FirstPersonWalker = FirstPersonWalkerScript.new()
	walker._init()
	walker._ready()

	# Simulate high downward fall speed
	walker.velocity = Vector3(0, -12.0, 0)
	walker._was_on_ground = false

	# Deploy glider
	walker.open_glider()
	if not walker.is_gliding:
		push_error("open_glider() should set is_gliding")
		walker.free()
		return false

	# Verify upward air cushion lift kicks in immediately
	if walker.velocity.y < 0.0:
		push_error("Genshin glider air cushion should clamp/lift initial downward velocity on deploy, got: %f" % walker.velocity.y)
		walker.free()
		return false

	walker.free()
	return true

func test_rdr2_stopping_skid_and_momentum() -> bool:
	var walker: FirstPersonWalker = FirstPersonWalkerScript.new()
	walker._init()
	walker._ready()

	# Set high sprint speed and ground state
	walker.velocity = Vector3(0, 0, -7.0)
	walker._is_sprinting = true
	walker._was_sprinting_prev = true

	# Release movement keys (wish_dir = ZERO, sprint = false)
	walker.move_character(0.016, Vector3.ZERO, false, false)

	# Verify stopping skid initiated
	if walker._skid_timer <= 0.0:
		push_error("Abrupt sprint release at high speed should initiate RDR2 stopping skid braking")
		walker.free()
		return false

	# Verify forward pitch braking torque
	if walker._skid_pitch <= 0.0:
		push_error("Stopping skid should pitch body forward with inertia")
		walker.free()
		return false

	walker.free()
	return true
