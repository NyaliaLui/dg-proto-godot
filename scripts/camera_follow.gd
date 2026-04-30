extends Camera3D

var scroll_enabled := true
var _target: Node3D

func _ready() -> void:
	add_to_group("camera")

func _process(_delta: float) -> void:
	if not scroll_enabled:
		return
	if not _target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_target = players[0]
	if _target:
		global_position.x = _target.global_position.x
