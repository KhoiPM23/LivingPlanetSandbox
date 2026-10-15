class_name PlayerCharacter
extends FirstPersonWalker

## PlayerCharacter alias and specialized third-person character controller.
## Inherits full 3D humanoid mesh, skeletal animation state machine, and dual perspective support.

func _init() -> void:
	super._init()
	is_third_person = true
