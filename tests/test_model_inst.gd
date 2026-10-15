@tool
extends SceneTree
func _init():
    var scn = load('res://presentation/assets/models/human_character.glb')
    var root = Node3D.new()
    var model = scn.instantiate()
    root.add_child(model)
    # Check forward vector of model
    print('Model rotation: ', model.rotation)
    print('Model basis: ', model.transform.basis)
    var anim: AnimationPlayer = model.find_child('*AnimationPlayer*', true, false)
    if anim:
        print('Has anim player!')
        anim.play('walk')
        anim.advance(0.1)
    root.free()
    quit(0)
