@tool
extends SceneTree
func _init():
    var scn = load('res://presentation/assets/models/human_character.glb')
    var inst = scn.instantiate()
    var anim: AnimationPlayer = inst.find_child('*AnimationPlayer*', true, false)
    if anim:
        var walk_anim: Animation = anim.get_animation('walk')
        print('Walk tracks count: ', walk_anim.get_track_count())
        for i in range(walk_anim.get_track_count()):
            var path = walk_anim.track_get_path(i)
            print('Track: ', path, ' type: ', walk_anim.track_get_type(i))
            if walk_anim.track_get_key_count(i) > 0 and walk_anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
                print('  key0: ', walk_anim.track_get_key_value(i, 0))
    inst.free()
    quit(0)
