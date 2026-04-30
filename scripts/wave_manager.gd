extends Node

const BanditScene = preload("res://scenes/bandit.tscn")
const BASE_COUNT := 10
const BASE_TIME  := 60.0
const SCALE      := 1.25

var wave_number := 0
var in_wave     := false
var _remaining  := 0
var _time_left  := 0.0
var _wave_refs: Array = []

signal wave_started(wave_num: int, time_limit: float)
signal wave_tick(time_left: float)
signal wave_ended(cleared: bool)

func _ready() -> void:
	add_to_group("wave_manager")

func start_wave() -> void:
	in_wave      = true
	wave_number += 1
	var count    = ceili(BASE_COUNT * pow(SCALE, wave_number - 1))
	_time_left   = BASE_TIME  * pow(SCALE, wave_number - 1)
	_remaining   = count
	_set_scroll(false)
	_set_spawner_paused(true)
	_despawn_regular_bandits()
	var torrin = get_tree().get_first_node_in_group("player")
	var cx = torrin.global_position.x if torrin else 0.0
	for i in count:
		var b = BanditScene.instantiate()
		b.position = Vector3(cx + randf_range(-12.0, 12.0), 0.0, 0.0)
		b.patrol_left  = b.position.x - 6.0
		b.patrol_right = b.position.x + 6.0
		get_parent().add_child(b)
		b.defeated.connect(_on_wave_bandit_defeated)
		_wave_refs.append(b)
	wave_started.emit(wave_number, _time_left)

func _process(delta: float) -> void:
	if not in_wave:
		return
	_time_left -= delta
	wave_tick.emit(max(0.0, _time_left))
	if _time_left <= 0.0:
		_end_wave(false)

func _on_wave_bandit_defeated() -> void:
	_remaining -= 1
	if _remaining <= 0:
		_end_wave(true)

func _end_wave(cleared: bool) -> void:
	in_wave = false
	for b in _wave_refs:
		if is_instance_valid(b):
			b.queue_free()
	_wave_refs.clear()
	_set_scroll(true)
	_set_spawner_paused(false)
	wave_ended.emit(cleared)

func _set_scroll(enabled: bool) -> void:
	for c in get_tree().get_nodes_in_group("camera"):
		c.scroll_enabled = enabled

func _set_spawner_paused(p: bool) -> void:
	for s in get_tree().get_nodes_in_group("spawner"):
		s.paused = p

func _despawn_regular_bandits() -> void:
	for b in get_tree().get_nodes_in_group("enemy"):
		b.queue_free()
	for s in get_tree().get_nodes_in_group("spawner"):
		s._active_bandits = 0
