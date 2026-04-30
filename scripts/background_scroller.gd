extends Node3D

const BEHIND_THRESHOLD := -15.0

var _torrin: Node3D

func _process(_delta: float) -> void:
	if not _torrin:
		var p = get_tree().get_nodes_in_group("player")
		if p.size() > 0:
			_torrin = p[0]
		return
	var tx := _torrin.global_position.x
	_wrap_group($Mountains.get_children(), tx, 10.0)
	_wrap_group($Trees.get_children(),    tx,  9.0)
	_wrap_group($Clouds.get_children(),   tx,  8.0)

func _wrap_group(nodes: Array, torrin_x: float, spacing: float) -> void:
	if nodes.is_empty():
		return
	var sorted := nodes.duplicate()
	sorted.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	var rightmost_x: float = sorted[-1].global_position.x
	for n in sorted:
		if n.global_position.x < torrin_x + BEHIND_THRESHOLD:
			rightmost_x += spacing
			n.global_position.x = rightmost_x
		else:
			break
