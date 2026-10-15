@tool
extends SceneTree
func _init():
    var vp = SubViewport.new()
    vp.size = Vector2i(1024, 512)
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    var root = Node3D.new()
    vp.add_child(root)

    var light = DirectionalLight3D.new()
    light.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(30.0), 0.0)
    root.add_child(light)

    var cam = Camera3D.new()
    cam.position = Vector3(0.0, 1.2, 3.5)
    cam.look_at(Vector3(0.0, 0.9, 0.0))
    root.add_child(cam)

    var scn = load('res://presentation/assets/models/human_character.glb')
    var inst = scn.instantiate()
    inst.scale = Vector3(0.85, 0.85, 0.85)
    # Character 1: facing front (rot y = 0)
    root.add_child(inst)
    inst.position = Vector3(-1.0, 0.0, 0.0)

    # Character 2: rot y = PI (turned around)
    var inst2 = scn.instantiate()
    inst2.scale = Vector3(0.85, 0.85, 0.85)
    inst2.rotation.y = PI
    inst2.position = Vector3(1.0, 0.0, 0.0)
    root.add_child(inst2)

    var anim: AnimationPlayer = inst.find_child('*AnimationPlayer*', true, false)
    if anim:
        anim.play('idle')
        anim.advance(0.1)

    var anim2: AnimationPlayer = inst2.find_child('*AnimationPlayer*', true, false)
    if anim2:
        anim2.play('walk')
        anim2.advance(0.2)

    # Render frame
    RenderingServer.frame_post_draw.connect(func():
        var img = vp.get_texture().get_image()
        if img:
            img.save_png('reports/test_human_character_preview.png')
            print('Saved preview PNG!')
        quit(0)
    )
