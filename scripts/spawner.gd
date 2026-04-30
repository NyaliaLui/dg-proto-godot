extends Node3D

const BanditScene = preload("res://scenes/bandit.tscn")
const MAX_BANDITS := 7
const SPAWN_INTERVAL := 0.7

var _active_bandits := 0
var _spawn_timer := 0.0
var paused := false

func _ready() -> void:
	add_to_group("spawner")
	for i in 5:
		_spawn_bandit()

func _process(delta: float) -> void:
	if paused:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		_spawn_bandit()

func _spawn_bandit() -> void:
	var bandit = BanditScene.instantiate()
	var torrin = get_tree().get_first_node_in_group("player")
	var spawn_x = torrin.global_position.x + randf_range(5.0, 20.0) if torrin else randf_range(5.0, 20.0)
	bandit.position = Vector3(spawn_x, 0.0, 0.0)
	bandit.patrol_left = spawn_x - 8.0
	bandit.patrol_right = spawn_x + 8.0
	get_parent().add_child(bandit)
	_active_bandits += 1
	bandit.defeated.connect(_on_bandit_defeated)

func _on_bandit_defeated() -> void:
	_active_bandits -= 1
	var hud_nodes := get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		hud_nodes[0].add_score()
