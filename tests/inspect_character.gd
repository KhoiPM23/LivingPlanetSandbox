@tool
extends SceneTree
func _init():
    var doc = GLTFDocument.new()
    var state = GLTFState.new()
    var err = doc.append_from_file('res://presentation/assets/models/character.glb', state)
    print('GLTF load err: ', err)
    if err == OK:
        var root = doc.generate_scene(state)
        print('Root node: ', root.name)
        _print_nodes(root, '')
        var anims = state.get_animations()
        print('Animations count: ', anims.size())
        for a in anims:
            print('Anim: ', a.resource_name, ' length: ', a.length)
        root.free()
    quit(0)

func _print_nodes(node, indent):
    print(indent, node.name, ' (', node.get_class(), ')')
    if node is AnimationPlayer:
        for anim in node.get_animation_list():
            print(indent, '  Anim in player: ', anim)
    for c in node.get_children():
        _print_nodes(c, indent + '  ')
