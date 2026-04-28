extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 16.0
const GRAVITY := 20.0
const MAX_HP := 25
const DAMAGE := 5

signal health_changed(new_hp: int)

var is_punching := false
var walk_phase := 0.0
var _punch_tween: Tween
var hp := MAX_HP
var facing_dir := 1.0

@onready var model: Node3D = $Model
@onready var left_leg: Node3D = $Model/LeftLeg
@onready var right_leg: Node3D = $Model/RightLeg
@onready var left_arm: Node3D = $Model/LeftArm
@onready var right_arm: Node3D = $Model/RightArm
@onready var hot_ball: MeshInstance3D = $Model/RightArm/HotBall

func _ready() -> void:
	add_to_group("player")
	model.rotation.y = PI / 2.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var direction := 0.0
	if Input.is_action_pressed("move_right"):
		direction = 1.0
	if Input.is_action_pressed("move_left"):
		direction = -1.0

	velocity.x = direction * SPEED
	velocity.z = 0.0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("punch") and not is_punching:
		_do_punch()

	if direction != 0.0:
		facing_dir = direction
		model.rotation.y = PI / 2.0 if direction > 0.0 else -PI / 2.0

	if is_on_floor() and abs(direction) > 0.0 and not is_punching:
		walk_phase += delta * 8.0
		_animate_walk()
	elif not is_punching:
		walk_phase = 0.0
		_reset_limbs()

	move_and_slide()

func _animate_walk() -> void:
	var swing := sin(walk_phase) * 0.5
	right_leg.rotation.x = swing
	left_leg.rotation.x = -swing
	right_arm.rotation.x = -swing * 0.6
	left_arm.rotation.x = swing * 0.6

func _reset_limbs() -> void:
	right_leg.rotation.x = 0.0
	left_leg.rotation.x = 0.0
	right_arm.rotation.x = 0.0
	left_arm.rotation.x = 0.0

func _do_punch() -> void:
	is_punching = true
	hot_ball.visible = true
	if _punch_tween:
		_punch_tween.kill()
	_punch_tween = create_tween()
	_punch_tween.tween_property(right_arm, "rotation:x", -PI / 2.0, 0.1)
	_punch_tween.tween_interval(0.08)
	_punch_tween.tween_property(right_arm, "rotation:x", 0.0, 0.18)
	await get_tree().create_timer(0.1).timeout
	_check_punch_hit()
	await _punch_tween.finished
	hot_ball.visible = false
	is_punching = false

func _check_punch_hit() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var diff: Vector3 = enemy.global_position - global_position
		var forward_dist: float = diff.x * facing_dir
		if forward_dist >= 0.0 and forward_dist <= 2.0 and abs(diff.y) < 1.5:
			enemy.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	health_changed.emit(hp)
	if hp <= 0:
		queue_free()
