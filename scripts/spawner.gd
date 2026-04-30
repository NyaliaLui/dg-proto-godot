extends Node3D

const BanditScene = preload("res://scenes/bandit.tscn")
const MAX_BANDITS := 7
const SPAWN_INTERVAL := 7.0

var _active_bandits := 0
var _spawn_timer := 0.0

func _ready() -> void:
	for i in 5:
		_spawn_bandit()

func _process(delta: float) -> void:
	if _active_bandits >= MAX_BANDITS:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		_spawn_bandit()

func _spawn_bandit() -> void:
	if _active_bandits >= MAX_BANDITS:
		return
	var bandit = BanditScene.instantiate()
	bandit.position = Vector3(randf_range(-10.0, 10.0), 0.0, 0.0)
	get_parent().add_child(bandit)
	_active_bandits += 1
	bandit.defeated.connect(_on_bandit_defeated)

func _on_bandit_defeated() -> void:
	_active_bandits -= 1
	var hud_nodes := get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		hud_nodes[0].add_score()
