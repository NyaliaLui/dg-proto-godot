extends CanvasLayer

var hp_squares: Array[ColorRect] = []
var bandits_defeated := 0
var _wave_manager: Node = null

func _ready() -> void:
	add_to_group("hud")
	var left_btn: Button = $BottomLeft/LeftBtn
	var right_btn: Button = $BottomLeft/RightBtn
	var jump_btn: Button = $BottomRight/JumpBtn
	var attack_btn: Button = $BottomRight/AttackBtn

	left_btn.button_down.connect(func(): Input.action_press("move_left"))
	left_btn.button_up.connect(func(): Input.action_release("move_left"))
	right_btn.button_down.connect(func(): Input.action_press("move_right"))
	right_btn.button_up.connect(func(): Input.action_release("move_right"))

	jump_btn.pressed.connect(_on_jump_pressed)
	attack_btn.pressed.connect(_on_attack_pressed)

	hp_squares = [$HealthBar/HP1, $HealthBar/HP2, $HealthBar/HP3, $HealthBar/HP4, $HealthBar/HP5]

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].health_changed.connect(_on_health_changed)
		players[0].max_hp_changed.connect(_on_max_hp_changed)

	$WinPopup/VBox/FacebookBtn.pressed.connect(_on_facebook_pressed)
	$WinPopup/VBox/RestartBtn.pressed.connect(_on_restart_pressed)
	$LosePopup/VBox/FacebookBtn.pressed.connect(_on_facebook_pressed)
	$LosePopup/VBox/RestartBtn.pressed.connect(_on_restart_pressed)

	var wm_nodes = get_tree().get_nodes_in_group("wave_manager")
	if wm_nodes.size() > 0:
		_wave_manager = wm_nodes[0]
		_wave_manager.wave_started.connect(_on_wave_started)
		_wave_manager.wave_tick.connect(_on_wave_tick)
		_wave_manager.wave_ended.connect(_on_wave_ended)
	$BuffLabel.visible = false

func _on_jump_pressed() -> void:
	Input.action_press("jump")
	await get_tree().process_frame
	Input.action_release("jump")

func _on_attack_pressed() -> void:
	Input.action_press("punch")
	await get_tree().process_frame
	Input.action_release("punch")

func _on_health_changed(new_hp: int) -> void:
	var squares_to_show := ceili(new_hp / 5.0)
	for i in range(hp_squares.size()):
		hp_squares[i].visible = i < squares_to_show
	if new_hp <= 0:
		$LosePopup.visible = true

func add_score() -> void:
	bandits_defeated += 1
	$ScoreLabel.text = "Score: %d" % bandits_defeated
	if bandits_defeated % 5 == 0 and _wave_manager != null:
		_wave_manager.start_wave()

func _on_facebook_pressed() -> void:
	OS.shell_open("https://www.facebook.com/profile.php?id=61572357196698")

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_wave_started(wave_num: int, time_limit: float) -> void:
	$CountdownLabel.text = "%d" % ceili(time_limit)
	$CountdownLabel.visible = true

func _on_wave_tick(time_left: float) -> void:
	$CountdownLabel.text = "%d" % ceili(time_left)

func _on_wave_ended(cleared: bool) -> void:
	$CountdownLabel.visible = false
	if cleared:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			players[0].add_health_bars(2)

func _on_max_hp_changed(new_max_hp: int) -> void:
	var new_count := new_max_hp / 5
	while hp_squares.size() < new_count:
		var sq := ColorRect.new()
		sq.custom_minimum_size = Vector2(30, 30)
		sq.color = Color(0.8, 0.1, 0.1, 1)
		$HealthBar.add_child(sq)
		hp_squares.append(sq)
