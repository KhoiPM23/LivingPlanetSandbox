@tool
class_name AnimeCharacterAnimator
extends RefCounted

## High-fidelity procedural humanoid locomotion animator for Anime Character:
## - Smooth multi-state blending (Idle, Walk, Run, Jump, Glide)
## - Natural skeletal kinematics for VRM humanoid rig
## - Secondary physics for hair strands, skirt, and wind flutter

var _skeleton: Skeleton3D = null

# Bone indices cache
var _b_hips: int = -1
var _b_spine: int = -1
var _b_chest: int = -1
var _b_neck: int = -1
var _b_head: int = -1

var _b_l_arm: int = -1
var _b_l_forearm: int = -1
var _b_l_hand: int = -1

var _b_r_arm: int = -1
var _b_r_forearm: int = -1
var _b_r_hand: int = -1

var _b_l_shoulder: int = -1
var _b_r_shoulder: int = -1

# Arm natural pendulum physics
var _arm_swing_l: float = 0.0
var _arm_swing_l_vel: float = 0.0
var _arm_swing_r: float = 0.0
var _arm_swing_r_vel: float = 0.0
var _arm_is_douyin: bool = false # set to true when driving Douyin skeleton

var _b_l_thigh: int = -1
var _b_l_shin: int = -1
var _b_l_foot: int = -1

var _b_r_thigh: int = -1
var _b_r_shin: int = -1
var _b_r_foot: int = -1

var _hair_bones: Array[int] = []
var _b_r_finger_knuckles: Array[int] = []
var _b_r_finger_phalanges: Array[int] = []
var _b_r_thumb1: int = -1
var _b_r_thumb2: int = -1

# Animation state tracking
var _walk_cycle: float = 0.0
var _anim_time: float = 0.0
var _current_blend_glide: float = 0.0
var _current_blend_run: float = 0.0
var _current_blend_walk: float = 0.0
var _current_blend_jump: float = 0.0

# Combat Stance & Procedural Attack Layers
var _in_combat_stance: bool = false
var _combat_blend: float = 0.0
var _attack_active: bool = false
var _attack_timer: float = 0.0
var _attack_duration: float = 0.32
var _attack_stage: int = 0

func set_combat_stance(in_combat: bool) -> void:
	_in_combat_stance = in_combat

func trigger_attack_anim(stage: int) -> void:
	_attack_active = true
	_attack_timer = 0.0
	_attack_stage = stage
	_in_combat_stance = true


func setup(skeleton: Skeleton3D) -> void:
	_skeleton = skeleton
	if not _skeleton:
		return

	_b_hips = _skeleton.find_bone("J_Bip_C_Hips")
	_b_spine = _skeleton.find_bone("J_Bip_C_Spine")
	_b_chest = _skeleton.find_bone("J_Bip_C_Chest")
	_b_neck = _skeleton.find_bone("J_Bip_C_Neck")
	_b_head = _skeleton.find_bone("J_Bip_C_Head")

	_b_l_arm = _skeleton.find_bone("J_Bip_L_UpperArm")
	_b_l_forearm = _skeleton.find_bone("J_Bip_L_LowerArm")
	_b_l_hand = _skeleton.find_bone("J_Bip_L_Hand")

	_b_r_arm = _skeleton.find_bone("J_Bip_R_UpperArm")
	_b_r_forearm = _skeleton.find_bone("J_Bip_R_LowerArm")
	_b_r_hand = _skeleton.find_bone("J_Bip_R_Hand")

	_b_l_shoulder = _skeleton.find_bone("J_Bip_L_Shoulder")
	_b_r_shoulder = _skeleton.find_bone("J_Bip_R_Shoulder")

	_b_l_thigh = _skeleton.find_bone("J_Bip_L_UpperLeg")
	_b_l_shin = _skeleton.find_bone("J_Bip_L_LowerLeg")
	_b_l_foot = _skeleton.find_bone("J_Bip_L_Foot")

	_b_r_thigh = _skeleton.find_bone("J_Bip_R_UpperLeg")
	_b_r_shin = _skeleton.find_bone("J_Bip_R_LowerLeg")
	_b_r_foot = _skeleton.find_bone("J_Bip_R_Foot")

	_b_bust_l1 = _skeleton.find_bone("J_Sec_L_Bust1")
	_b_bust_l2 = _skeleton.find_bone("J_Sec_L_Bust2")
	_b_bust_r1 = _skeleton.find_bone("J_Sec_R_Bust1")
	_b_bust_r2 = _skeleton.find_bone("J_Sec_R_Bust2")

	_b_r_finger_knuckles = [
		_skeleton.find_bone("J_Bip_R_Index1"),
		_skeleton.find_bone("J_Bip_R_Middle1"),
		_skeleton.find_bone("J_Bip_R_Ring1"),
		_skeleton.find_bone("J_Bip_R_Little1")
	]
	_b_r_finger_phalanges = [
		_skeleton.find_bone("J_Bip_R_Index2"),
		_skeleton.find_bone("J_Bip_R_Middle2"),
		_skeleton.find_bone("J_Bip_R_Ring2"),
		_skeleton.find_bone("J_Bip_R_Little2")
	]
	_b_r_thumb1 = _skeleton.find_bone("J_Bip_R_Thumb1")
	_b_r_thumb2 = _skeleton.find_bone("J_Bip_R_Thumb2")

	_hair_bones.clear()
	for i in range(_skeleton.get_bone_count()):
		var bname: String = _skeleton.get_bone_name(i)
		if "Hair" in bname:
			_hair_bones.append(i)

var _b_bust_l1: int = -1
var _b_bust_l2: int = -1
var _b_bust_r1: int = -1
var _b_bust_r2: int = -1

# Secondary dynamic breast jiggle physics (Spring-damper soft-tissue simulation)
var _bust_pitch: float = deg_to_rad(3.2) # Gentle natural downward teardrop hang
var _bust_pitch_vel: float = 0.0
var _bust_yaw: float = 0.0
var _bust_yaw_vel: float = 0.0
var _prev_yaw: float = 0.0
var _prev_y_vel: float = 0.0
# Scale factor for breast physics amplitude (1.0 = anime C-cup, 0.72 = douyin B-)
var bust_physics_scale: float = 1.0

var _current_blend_climb: float = 0.0

func update(delta: float, horizontal_speed: float, is_on_floor: bool, is_gliding: bool, _is_sprinting: bool, is_climbing: bool = false, yaw_rot: float = 0.0, vert_velocity: float = 0.0) -> void:
	if not _skeleton:
		return

	_anim_time += delta

	# State blending weights
	var target_climb: float = 1.0 if is_climbing else 0.0
	var target_glide: float = 1.0 if (is_gliding and not is_climbing) else 0.0
	var target_jump: float = 1.0 if (not is_on_floor and not is_gliding and not is_climbing) else 0.0
	var target_run: float = 1.0 if (is_on_floor and not is_climbing and horizontal_speed > 4.5) else 0.0
	var target_walk: float = 1.0 if (is_on_floor and not is_climbing and horizontal_speed > 0.2 and horizontal_speed <= 4.5) else 0.0

	var blend_rate: float = clampf(delta * 9.0, 0.0, 1.0)
	_current_blend_climb = lerpf(_current_blend_climb, target_climb, blend_rate * 1.5)
	_current_blend_glide = lerpf(_current_blend_glide, target_glide, blend_rate)
	_current_blend_jump = lerpf(_current_blend_jump, target_jump, blend_rate)
	_current_blend_run = lerpf(_current_blend_run, target_run, blend_rate)
	_current_blend_walk = lerpf(_current_blend_walk, target_walk, blend_rate)

	# Locomotion cycle frequency
	var stride_speed: float = 0.0
	if is_on_floor and horizontal_speed > 0.1:
		stride_speed = clampf(horizontal_speed * 1.35, 2.0, 14.0)
		_walk_cycle += delta * stride_speed
	else:
		_walk_cycle = wrapf(_walk_cycle, 0.0, TAU)

	# 1. Base Idle Posing (Natural relaxed arms gracefully resting alongside hips)
	var idle_breathe: float = sin(_anim_time * 2.2) * 0.025
	var idle_sway: float = cos(_anim_time * 1.4) * 0.015

	# Relaxed, open shoulder blade rest pose (broadens chest naturally, opens scapula outwards when idle)
	var l_shoulder_rot: Basis = Basis(Vector3.UP, deg_to_rad(-3.8)) * Basis(Vector3.FORWARD, deg_to_rad(1.8))
	var r_shoulder_rot: Basis = Basis(Vector3.UP, deg_to_rad(3.8)) * Basis(Vector3.FORWARD, deg_to_rad(-1.8))

	# Natural, relaxed arm & hand rest angles (close to body sides, graceful feminine drape without backward retraction)
	var l_arm_rot: Basis = Basis(Vector3.FORWARD, deg_to_rad(76.0)) * Basis(Vector3.UP, deg_to_rad(2.0)) * Basis(Vector3.RIGHT, deg_to_rad(-1.0))
	var r_arm_rot: Basis = Basis(Vector3.FORWARD, deg_to_rad(-76.0)) * Basis(Vector3.UP, deg_to_rad(-2.0)) * Basis(Vector3.RIGHT, deg_to_rad(-1.0))
	var l_fore_rot: Basis = Basis(Vector3.RIGHT, deg_to_rad(10.0)) * Basis(Vector3.UP, deg_to_rad(5.0))
	var r_fore_rot: Basis = Basis(Vector3.RIGHT, deg_to_rad(10.0)) * Basis(Vector3.UP, deg_to_rad(-5.0))
	var l_hand_rot: Basis = Basis(Vector3.FORWARD, deg_to_rad(5.0)) * Basis(Vector3.RIGHT, deg_to_rad(4.0))
	var r_hand_rot: Basis = Basis(Vector3.FORWARD, deg_to_rad(-5.0)) * Basis(Vector3.RIGHT, deg_to_rad(4.0))

	# Feminine hourglass idle stance: subtle outward hip curve (+2.2 deg) accentuating waist-to-hip flare
	var l_thigh_rot: Basis = Basis(Vector3.FORWARD, deg_to_rad(-2.2))
	var r_thigh_rot: Basis = Basis(Vector3.FORWARD, deg_to_rad(2.2))
	var l_shin_rot: Basis = Basis.IDENTITY
	var r_shin_rot: Basis = Basis.IDENTITY

	# Sculpted feminine posture: refined pelvic tilt (+4.8 deg) lifting perky buttocks and creating natural lumbar lordosis S-curve
	var hips_rot: Basis = Basis(Vector3.RIGHT, deg_to_rad(4.8))
	var spine_rot: Basis = Basis(Vector3.RIGHT, -deg_to_rad(2.6) + idle_breathe) * Basis(Vector3.UP, idle_sway)
	var chest_rot: Basis = Basis(Vector3.RIGHT, deg_to_rad(1.2) + idle_breathe * 0.7)

	# 2. Walk Layer (Dainty, elegant feminine stride with small delicate steps)
	if _current_blend_walk > 0.001:
		var w_val: float = sin(_walk_cycle)
		var w_weight: float = _current_blend_walk

		# Dainty, delicate leg stride (19.0 deg pitch - feminine footsteps)
		var l_pitch: float = w_val * deg_to_rad(19.0) * w_weight
		var r_pitch: float = -w_val * deg_to_rad(19.0) * w_weight
		l_thigh_rot = l_thigh_rot * Basis(Vector3.RIGHT, l_pitch)
		r_thigh_rot = r_thigh_rot * Basis(Vector3.RIGHT, r_pitch)

		# Soft knee flex (26.0 deg)
		var l_knee: float = max(0.0, -w_val) * deg_to_rad(26.0) * w_weight
		var r_knee: float = max(0.0, w_val) * deg_to_rad(26.0) * w_weight
		l_shin_rot = l_shin_rot * Basis(Vector3.RIGHT, l_knee)
		r_shin_rot = r_shin_rot * Basis(Vector3.RIGHT, r_knee)

		# Gentle counter arm swing (14.0 deg) and subtle shoulder pumping
		var l_arm_swing: float = -w_val * deg_to_rad(14.0) * w_weight
		var r_arm_swing: float = w_val * deg_to_rad(14.0) * w_weight
		l_arm_rot = l_arm_rot * Basis(Vector3.RIGHT, l_arm_swing)
		r_arm_rot = r_arm_rot * Basis(Vector3.RIGHT, r_arm_swing)
		l_shoulder_rot = l_shoulder_rot * Basis(Vector3.RIGHT, l_arm_swing * 0.25)
		r_shoulder_rot = r_shoulder_rot * Basis(Vector3.RIGHT, r_arm_swing * 0.25)

		# Natural arm pendulum physics — side-to-side lateral dangle during walk
		var arm_lateral_target: float = cos(_walk_cycle) * deg_to_rad(2.8) * w_weight
		var arm_k: float = 38.0
		var arm_damp: float = 2.0 * sqrt(arm_k)
		var la_accel: float = -arm_k * (_arm_swing_l - arm_lateral_target) - arm_damp * _arm_swing_l_vel
		_arm_swing_l_vel += la_accel * delta
		_arm_swing_l += _arm_swing_l_vel * delta
		_arm_swing_l = clampf(_arm_swing_l, deg_to_rad(-6.0), deg_to_rad(6.0))
		var ra_accel: float = -arm_k * (_arm_swing_r + arm_lateral_target) - arm_damp * _arm_swing_r_vel
		_arm_swing_r_vel += ra_accel * delta
		_arm_swing_r += _arm_swing_r_vel * delta
		_arm_swing_r = clampf(_arm_swing_r, deg_to_rad(-6.0), deg_to_rad(6.0))
		l_arm_rot = l_arm_rot * Basis(Vector3.FORWARD, _arm_swing_l)
		r_arm_rot = r_arm_rot * Basis(Vector3.FORWARD, _arm_swing_r)

		# Feminine hip sway (4.0 deg)
		hips_rot = hips_rot * Basis(Vector3.FORWARD, sin(_walk_cycle) * deg_to_rad(4.0) * w_weight)

	# 3. Run Layer (Athletic forward lean, expansive 52 deg stride, high knee drive, pumping bent arms)
	if _current_blend_run > 0.001:
		var r_val: float = sin(_walk_cycle * 1.15)
		var r_weight: float = _current_blend_run

		# Forward torso pitch & natural counter-torso twist against hip drive
		var twist_val: float = cos(_walk_cycle * 1.15) * deg_to_rad(5.5) * r_weight
		spine_rot = spine_rot * Basis(Vector3.RIGHT, deg_to_rad(16.5) * r_weight) * Basis(Vector3.UP, twist_val)
		chest_rot = chest_rot * Basis(Vector3.RIGHT, deg_to_rad(6.5) * r_weight) * Basis(Vector3.UP, -twist_val * 0.65)

		# Expansive, athletic leg stride (+174% wider than walk!)
		var l_stride: float = r_val * deg_to_rad(52.0) * r_weight
		var r_stride: float = -r_val * deg_to_rad(52.0) * r_weight
		l_thigh_rot = l_thigh_rot * Basis(Vector3.RIGHT, l_stride)
		r_thigh_rot = r_thigh_rot * Basis(Vector3.RIGHT, r_stride)

		# High athletic knee lift (82.0 deg)
		var l_knee_r: float = max(0.0, -r_val) * deg_to_rad(82.0) * r_weight
		var r_knee_r: float = max(0.0, r_val) * deg_to_rad(82.0) * r_weight
		l_shin_rot = l_shin_rot * Basis(Vector3.RIGHT, l_knee_r)
		r_shin_rot = r_shin_rot * Basis(Vector3.RIGHT, r_knee_r)

		# Dynamic arm pumping with bent elbows (55 deg elbow flex, 48 deg swing) & athletic shoulder retraction
		var l_pump: float = -r_val * deg_to_rad(48.0) * r_weight
		var r_pump: float = r_val * deg_to_rad(48.0) * r_weight
		l_arm_rot = l_arm_rot * Basis(Vector3.RIGHT, l_pump)
		r_arm_rot = r_arm_rot * Basis(Vector3.RIGHT, r_pump)
		l_fore_rot = l_fore_rot * Basis(Vector3.RIGHT, deg_to_rad(55.0) * r_weight)
		r_fore_rot = r_fore_rot * Basis(Vector3.RIGHT, deg_to_rad(55.0) * r_weight)
		# Retract shoulders only while running dynamically
		l_shoulder_rot = l_shoulder_rot * Basis(Vector3.RIGHT, deg_to_rad(6.5) * r_weight + l_pump * 0.2)
		r_shoulder_rot = r_shoulder_rot * Basis(Vector3.RIGHT, deg_to_rad(6.5) * r_weight + r_pump * 0.2)

	# 4. Jump Layer (In air, knees tucked, arms out)
	if _current_blend_jump > 0.001:
		var j_weight: float = _current_blend_jump
		l_thigh_rot = l_thigh_rot * Basis(Vector3.RIGHT, deg_to_rad(22.0) * j_weight)
		r_thigh_rot = r_thigh_rot * Basis(Vector3.RIGHT, deg_to_rad(16.0) * j_weight)
		l_shin_rot = l_shin_rot * Basis(Vector3.RIGHT, deg_to_rad(32.0) * j_weight)
		r_shin_rot = r_shin_rot * Basis(Vector3.RIGHT, deg_to_rad(40.0) * j_weight)
		l_arm_rot = l_arm_rot * Basis(Vector3.FORWARD, deg_to_rad(-24.0) * j_weight)
		r_arm_rot = r_arm_rot * Basis(Vector3.FORWARD, deg_to_rad(24.0) * j_weight)

	# 5. Glide Layer (Horizontal flight pose, holding glider risers)
	if _current_blend_glide > 0.001:
		var g_weight: float = _current_blend_glide
		# Horizontal body dive (68 degrees pitch)
		hips_rot = hips_rot.slerp(Basis(Vector3.RIGHT, deg_to_rad(68.0)), g_weight)
		spine_rot = spine_rot.slerp(Basis(Vector3.RIGHT, deg_to_rad(12.0)), g_weight)
		chest_rot = chest_rot.slerp(Basis(Vector3.RIGHT, deg_to_rad(14.0)), g_weight)

		# Arms reaching forward-outward to hold glider
		var glide_l_arm: Basis = Basis(Vector3.FORWARD, deg_to_rad(14.0)) * Basis(Vector3.RIGHT, deg_to_rad(-55.0))
		var glide_r_arm: Basis = Basis(Vector3.FORWARD, deg_to_rad(-14.0)) * Basis(Vector3.RIGHT, deg_to_rad(-55.0))
		l_arm_rot = l_arm_rot.slerp(glide_l_arm, g_weight)
		r_arm_rot = r_arm_rot.slerp(glide_r_arm, g_weight)

		# Legs trailing behind gracefully
		var flutter_l: float = sin(_anim_time * 6.5) * deg_to_rad(5.0)
		var flutter_r: float = cos(_anim_time * 6.5) * deg_to_rad(5.0)
		var glide_leg: Basis = Basis(Vector3.RIGHT, deg_to_rad(-18.0))
		l_thigh_rot = l_thigh_rot.slerp(glide_leg * Basis(Vector3.RIGHT, flutter_l), g_weight)
		r_thigh_rot = r_thigh_rot.slerp(glide_leg * Basis(Vector3.RIGHT, flutter_r), g_weight)

	# 6. Combat Stance & Procedural Attack Layers
	var target_combat: float = 1.0 if _in_combat_stance else 0.0
	_combat_blend = lerpf(_combat_blend, target_combat, clampf(delta * 10.0, 0.0, 1.0))
	if absf(_combat_blend - target_combat) < 0.005:
		_combat_blend = target_combat

	if _combat_blend > 0.001 and _current_blend_glide < 0.5:
		var cb: float = _combat_blend * (1.0 - _current_blend_glide)
		# Combat ready guard stance
		var combat_r_arm: Basis = Basis(Vector3.FORWARD, deg_to_rad(-22.0)) * Basis(Vector3.RIGHT, deg_to_rad(-32.0)) * Basis(Vector3.UP, deg_to_rad(15.0))
		var combat_r_fore: Basis = Basis(Vector3.UP, deg_to_rad(-35.0)) * Basis(Vector3.RIGHT, deg_to_rad(45.0))
		var combat_l_arm: Basis = Basis(Vector3.FORWARD, deg_to_rad(35.0)) * Basis(Vector3.RIGHT, deg_to_rad(-15.0))

		# Natural wrist alignment extending straight and strong along the forearm (no broken upward bend)
		var combat_r_hand: Basis = Basis(Vector3.FORWARD, deg_to_rad(-14.0)) * Basis(Vector3.UP, deg_to_rad(10.0))

		r_arm_rot = r_arm_rot.slerp(combat_r_arm, cb)
		r_fore_rot = r_fore_rot.slerp(combat_r_fore, cb)
		l_arm_rot = l_arm_rot.slerp(combat_l_arm, cb * 0.75)
		r_hand_rot = r_hand_rot.slerp(combat_r_hand, cb)

	# 4. Climbing Wall Grip Layer
	if _current_blend_climb > 0.001:
		var c_weight: float = _current_blend_climb
		var c_step: float = sin(_anim_time * 6.5) # Alternating arm reach
		# Arms reach up and grasp wall
		var climb_l_arm: Basis = Basis(Vector3.RIGHT, deg_to_rad(-85.0) + c_step * deg_to_rad(15.0)) * Basis(Vector3.FORWARD, deg_to_rad(30.0))
		var climb_r_arm: Basis = Basis(Vector3.RIGHT, deg_to_rad(-85.0) - c_step * deg_to_rad(15.0)) * Basis(Vector3.FORWARD, deg_to_rad(-30.0))
		var climb_l_fore: Basis = Basis(Vector3.RIGHT, deg_to_rad(45.0))
		var climb_r_fore: Basis = Basis(Vector3.RIGHT, deg_to_rad(45.0))
		# Legs bent clinging to cliff
		var climb_l_thigh: Basis = Basis(Vector3.RIGHT, deg_to_rad(-25.0) - c_step * deg_to_rad(12.0))
		var climb_r_thigh: Basis = Basis(Vector3.RIGHT, deg_to_rad(-25.0) + c_step * deg_to_rad(12.0))
		var climb_l_shin: Basis = Basis(Vector3.RIGHT, deg_to_rad(45.0))
		var climb_r_shin: Basis = Basis(Vector3.RIGHT, deg_to_rad(45.0))

		l_arm_rot = l_arm_rot.slerp(climb_l_arm, c_weight)
		r_arm_rot = r_arm_rot.slerp(climb_r_arm, c_weight)
		l_fore_rot = l_fore_rot.slerp(climb_l_fore, c_weight)
		r_fore_rot = r_fore_rot.slerp(climb_r_fore, c_weight)
		l_thigh_rot = l_thigh_rot.slerp(climb_l_thigh, c_weight)
		r_thigh_rot = r_thigh_rot.slerp(climb_r_thigh, c_weight)
		l_shin_rot = l_shin_rot.slerp(climb_l_shin, c_weight)
		r_shin_rot = r_shin_rot.slerp(climb_r_shin, c_weight)

	# Active Attack Swing Animation
	if _attack_active:
		_attack_timer += delta
		var atk_t: float = clampf(_attack_timer / _attack_duration, 0.0, 1.0)
		var swing_arc: float = sin(atk_t * PI)

		match _attack_stage:
			0:
				# Strike 1: Horizontal Cleave (Right to Left sweep)
				var sweep_yaw: float = lerpf(deg_to_rad(-35.0), deg_to_rad(65.0), atk_t)
				var sweep_pitch: float = deg_to_rad(-45.0) - sin(atk_t * PI) * deg_to_rad(20.0)
				r_arm_rot = Basis(Vector3.UP, sweep_yaw) * Basis(Vector3.RIGHT, sweep_pitch)
				r_fore_rot = Basis(Vector3.RIGHT, deg_to_rad(25.0) + swing_arc * deg_to_rad(30.0))
				chest_rot = chest_rot * Basis(Vector3.UP, (atk_t - 0.5) * deg_to_rad(22.0))
			1:
				# Strike 2: Upward Crescent Slash (Low right to High left)
				var slash_pitch: float = lerpf(deg_to_rad(10.0), deg_to_rad(-75.0), atk_t)
				var slash_roll: float = lerpf(deg_to_rad(-40.0), deg_to_rad(35.0), atk_t)
				r_arm_rot = Basis(Vector3.RIGHT, slash_pitch) * Basis(Vector3.FORWARD, slash_roll)
				r_fore_rot = Basis(Vector3.RIGHT, deg_to_rad(55.0) * (1.0 - atk_t))
				spine_rot = spine_rot * Basis(Vector3.RIGHT, deg_to_rad(-8.0) * swing_arc)
			2:
				# Strike 3: Anemo Whirlwind Finisher (360 dynamic lunging spin)
				var spin_pitch: float = deg_to_rad(-60.0)
				var spin_roll: float = lerpf(deg_to_rad(-60.0), deg_to_rad(85.0), atk_t)
				r_arm_rot = Basis(Vector3.RIGHT, spin_pitch) * Basis(Vector3.FORWARD, spin_roll)
				r_fore_rot = Basis(Vector3.RIGHT, deg_to_rad(65.0) * swing_arc)
				chest_rot = chest_rot * Basis(Vector3.UP, swing_arc * deg_to_rad(38.0))

		if atk_t >= 1.0:
			_attack_active = false

	# Apply final computed bone rotations to Skeleton3D
	_apply_rot(_b_hips, hips_rot)
	_apply_rot(_b_spine, spine_rot)
	_apply_rot(_b_chest, chest_rot)
	_apply_rot(_b_l_shoulder, l_shoulder_rot)
	_apply_rot(_b_r_shoulder, r_shoulder_rot)

	_apply_rot(_b_l_arm, l_arm_rot)
	_apply_rot(_b_l_forearm, l_fore_rot)
	_apply_rot(_b_l_hand, l_hand_rot)
	_apply_rot(_b_r_arm, r_arm_rot)
	_apply_rot(_b_r_forearm, r_fore_rot)
	_apply_rot(_b_r_hand, r_hand_rot)

	_apply_rot(_b_l_thigh, l_thigh_rot)
	_apply_rot(_b_l_shin, l_shin_rot)
	_apply_rot(_b_r_thigh, r_thigh_rot)
	_apply_rot(_b_r_shin, r_shin_rot)

	# Dynamic finger curling for sword grip when weapon is held in combat stance
	if _combat_blend > 0.001:
		var cb_curl: float = _combat_blend * (1.0 - _current_blend_glide)
		var curl_k: Basis = Basis(Vector3.FORWARD, deg_to_rad(65.0) * cb_curl)
		var curl_p: Basis = Basis(Vector3.FORWARD, deg_to_rad(75.0) * cb_curl)
		for b in _b_r_finger_knuckles:
			if b >= 0:
				_skeleton.set_bone_pose_rotation(b, curl_k.get_rotation_quaternion())
		for b in _b_r_finger_phalanges:
			if b >= 0:
				_skeleton.set_bone_pose_rotation(b, curl_p.get_rotation_quaternion())
		if _b_r_thumb1 >= 0:
			var t1: Basis = Basis(Vector3.UP, deg_to_rad(-25.0) * cb_curl)
			_skeleton.set_bone_pose_rotation(_b_r_thumb1, t1.get_rotation_quaternion())
		if _b_r_thumb2 >= 0:
			var t2: Basis = Basis(Vector3.FORWARD, deg_to_rad(35.0) * cb_curl)
			_skeleton.set_bone_pose_rotation(_b_r_thumb2, t2.get_rotation_quaternion())
	else:
		# Reset fingers to relaxed rest pose when weapon is sheathed
		for b in _b_r_finger_knuckles:
			if b >= 0:
				_skeleton.set_bone_pose_rotation(b, Quaternion.IDENTITY)
		for b in _b_r_finger_phalanges:
			if b >= 0:
				_skeleton.set_bone_pose_rotation(b, Quaternion.IDENTITY)
		if _b_r_thumb1 >= 0:
			_skeleton.set_bone_pose_rotation(_b_r_thumb1, Quaternion.IDENTITY)
		if _b_r_thumb2 >= 0:
			_skeleton.set_bone_pose_rotation(_b_r_thumb2, Quaternion.IDENTITY)

	# Secondary dynamic hair flutter & momentum (relative to rest pose so hair naturally cascades down)
	var hair_sway: float = sin(_anim_time * 4.5) * 0.045 * (1.0 + horizontal_speed * 0.25)
	var hair_flutter: float = cos(_anim_time * 6.2) * 0.035
	for hb in _hair_bones:
		var rest_b: Basis = _skeleton.get_bone_rest(hb).basis
		var hair_rot: Basis = rest_b * Basis(Vector3.RIGHT, hair_sway) * Basis(Vector3.FORWARD, hair_flutter)
		_skeleton.set_bone_pose_rotation(hb, hair_rot.get_rotation_quaternion())

	# Secondary Dynamic Breast Jiggle & Soft-Tissue Inertia (Responsive Organic Physics)
	if _b_bust_l1 >= 0 or _b_bust_r1 >= 0:
		# 1. Rotational yaw inertia (responsive sway when character turns or camera rotates)
		var yaw_speed: float = 0.0
		if delta > 0.0001:
			var d_yaw: float = wrapf(yaw_rot - _prev_yaw, -PI, PI)
			yaw_speed = d_yaw / delta
		_prev_yaw = yaw_rot
		var yaw_inertia_force: float = clampf(-yaw_speed * 0.095, -0.45, 0.45)

		# 2. Locomotion footfall bounce (speed-dependent harmonic bounce matching gait)
		var footfall_pulse_l: float = 0.0
		var footfall_pulse_r: float = 0.0
		var strafe_sway: float = 0.0
		if is_on_floor and horizontal_speed > 0.2:
			var step_freq: float = 13.0 if _is_sprinting else 8.8
			var speed_ratio: float = clampf(horizontal_speed / 4.2, 0.1, 2.2)
			var bounce_amp: float = 0.065 * (1.6 if _is_sprinting else 1.15) * bust_physics_scale
			# Organic asymmetric phase between left and right breast
			footfall_pulse_l = sin(_anim_time * step_freq) * speed_ratio * bounce_amp
			footfall_pulse_r = sin(_anim_time * step_freq + 0.38) * speed_ratio * bounce_amp
			# Lateral sway matching gait weight shift
			strafe_sway = cos(_walk_cycle) * (speed_ratio * 0.035 * bust_physics_scale)

		# 3. Vertical landing impact shock
		var vert_accel: float = 0.0
		if delta > 0.0001:
			vert_accel = (vert_velocity - _prev_y_vel) / delta
		_prev_y_vel = vert_velocity
		var landing_impulse: float = clampf(-vert_accel * 0.0035, -0.25, 0.25)

		# 4. Soft-tissue spring-damper ODE integration (juicy, natural harmonic elasticity)
		var spring_k: float = 62.0  # slightly softer = more natural sway
		var damping_c: float = 5.2
		var target_pitch: float = deg_to_rad(4.5) # Natural teardrop gravity droop (heavier at bottom)
		if not is_on_floor and not is_gliding:
			target_pitch += deg_to_rad(4.0) # Downward aerodynamic float during freefall

		# Pitch integration (up/down bounce)
		var p_accel_l: float = -spring_k * (_bust_pitch - target_pitch) - damping_c * _bust_pitch_vel + (footfall_pulse_l + landing_impulse) * 120.0
		_bust_pitch_vel += p_accel_l * delta
		_bust_pitch += _bust_pitch_vel * delta
		_bust_pitch = clampf(_bust_pitch, deg_to_rad(-16.0), deg_to_rad(26.0))

		# Yaw integration (left/right turn sway)
		var y_accel: float = -spring_k * _bust_yaw - damping_c * _bust_yaw_vel + (yaw_inertia_force + strafe_sway) * 110.0
		_bust_yaw_vel += y_accel * delta
		_bust_yaw += _bust_yaw_vel * delta
		_bust_yaw = clampf(_bust_yaw, deg_to_rad(-16.0), deg_to_rad(16.0))

		# Apply dynamic pose rotation to primary bust bones (with subtle organic phase shift)
		if _b_bust_l1 >= 0:
			var rest_l: Basis = _skeleton.get_bone_rest(_b_bust_l1).basis
			var b_l: Basis = rest_l * Basis(Vector3.RIGHT, _bust_pitch) * Basis(Vector3.UP, _bust_yaw) * Basis(Vector3.FORWARD, strafe_sway * 0.5)
			_skeleton.set_bone_pose_rotation(_b_bust_l1, b_l.get_rotation_quaternion())
		if _b_bust_r1 >= 0:
			var rest_r: Basis = _skeleton.get_bone_rest(_b_bust_r1).basis
			# Right breast micro-phase offset for rich lifelike multi-body dynamics
			var pitch_r: float = _bust_pitch + (footfall_pulse_r - footfall_pulse_l) * 0.4
			var b_r: Basis = rest_r * Basis(Vector3.RIGHT, pitch_r) * Basis(Vector3.UP, _bust_yaw) * Basis(Vector3.FORWARD, -strafe_sway * 0.5)
			_skeleton.set_bone_pose_rotation(_b_bust_r1, b_r.get_rotation_quaternion())

		# Secondary soft tip / 3D nipple follow-through (fluid tip elasticity)
		if _b_bust_l2 >= 0:
			var rest_l2: Basis = _skeleton.get_bone_rest(_b_bust_l2).basis
			var b_l2: Basis = rest_l2 * Basis(Vector3.RIGHT, _bust_pitch * 0.45) * Basis(Vector3.UP, _bust_yaw * 0.45)
			_skeleton.set_bone_pose_rotation(_b_bust_l2, b_l2.get_rotation_quaternion())
		if _b_bust_r2 >= 0:
			var rest_r2: Basis = _skeleton.get_bone_rest(_b_bust_r2).basis
			var b_r2: Basis = rest_r2 * Basis(Vector3.RIGHT, _bust_pitch * 0.45) * Basis(Vector3.UP, _bust_yaw * 0.45)
			_skeleton.set_bone_pose_rotation(_b_bust_r2, b_r2.get_rotation_quaternion())

func _apply_rot(bone_idx: int, basis: Basis) -> void:
	if bone_idx >= 0:
		_skeleton.set_bone_pose_rotation(bone_idx, basis.get_rotation_quaternion())
