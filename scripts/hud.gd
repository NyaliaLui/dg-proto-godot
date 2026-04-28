extends CanvasLayer

var hp_squares: Array[ColorRect] = []
var bandits_defeated := 0
const WIN_COUNT := 5

func _ready() -> void:
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

	for bandit in get_tree().get_nodes_in_group("enemy"):
		bandit.defeated.connect(_on_bandit_defeated)

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
	for i in range(5):
		hp_squares[i].visible = i < squares_to_show
	if new_hp <= 0:
		$LosePopup.visible = true

func _on_bandit_defeated() -> void:
	bandits_defeated += 1
	if bandits_defeated >= WIN_COUNT:
		$WinPopup.visible = true
