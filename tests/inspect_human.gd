@tool
extends SceneTree
func _init():
    var doc = GLTFDocument.new()
    var state = GLTFState.new()
    var err = doc.append_from_file('res://presentation/assets/models/human_character.glb', state)
    print('GLTF load err: ', err)
    if err == OK:
        var root = doc.generate_scene(state)
        print('Root node: ', root.name)
        _print_nodes(root, '')
        root.free()
    quit(0)

func _print_nodes(node, indent):
    print(indent, node.name, ' (', node.get_class(), ')')
    if node is AnimationPlayer:
        for anim in node.get_animation_list():
            print(indent, '  >>> Animation: ', anim)
    for c in node.get_children():
        _print_nodes(c, indent + '  ')
