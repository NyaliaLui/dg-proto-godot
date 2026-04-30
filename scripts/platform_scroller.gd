extends Node3D

const BEHIND_THRESHOLD := -15.0
const HIGH_Y  := 6.0
const LOW_Y   := 3.0
const SPACING := 12.0

var _torrin: Node3D

func _process(_delta: float) -> void:
	if not _torrin:
		var p = get_tree().get_nodes_in_group("player")
		if p.size() > 0:
			_torrin = p[0]
		return
	var tx := _torrin.global_position.x
	var platforms := get_children()
	if platforms.is_empty():
		return
	platforms.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	var leftmost: Node3D = platforms[0]
	if leftmost.global_position.x < tx + BEHIND_THRESHOLD:
		var rightmost: Node3D = platforms[-1]
		var next_y := LOW_Y if is_equal_approx(rightmost.position.y, HIGH_Y) else HIGH_Y
		leftmost.position.x = rightmost.position.x + SPACING
		leftmost.position.y = next_y
