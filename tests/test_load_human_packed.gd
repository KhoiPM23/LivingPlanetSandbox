@tool
extends SceneTree
func _init():
    var scn = load('res://presentation/assets/models/human_character.glb')
    print('Loaded PackedScene: ', scn)
    if scn:
        var inst = scn.instantiate()
        print('Instantiated instance: ', inst.name)
        var anim: AnimationPlayer = inst.find_child('*AnimationPlayer*', true, false)
        print('AnimPlayer: ', anim)
        if anim:
            print('Anims: ', anim.get_animation_list())
        inst.free()
    quit(0)
