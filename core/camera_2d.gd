extends Camera2D

@export var target_path: NodePath
var target_node: Node2D

func _ready():
	if target_path != NodePath(""):
		target_node = get_node_or_null(target_path)
	current = true

func _process(delta):
	if target_node:
		global_position = target_node.global_position
