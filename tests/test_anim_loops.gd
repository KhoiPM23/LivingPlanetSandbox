@tool
extends SceneTree
func _init():
    var scn = load('res://presentation/assets/models/human_character.glb')
    if scn:
        var inst = scn.instantiate()
        var anim: AnimationPlayer = inst.find_child('*AnimationPlayer*', true, false)
        if anim:
            for name in anim.get_animation_list():
                var a = anim.get_animation(name)
                print(name, ' loop_mode=', a.loop_mode, ' len=', a.length)
        inst.free()
    quit(0)
