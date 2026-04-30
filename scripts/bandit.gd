extends CharacterBody3D

const SPEED := 2.5
const JUMP_VELOCITY := 14.0
const GRAVITY := 20.0
const MAX_HP := 15
const DAMAGE := 5

var patrol_left := -6.0
var patrol_right := 6.0
var direction := 1.0
var hp := MAX_HP
var walk_phase := 0.0
var is_punching := false
var _punch_tween: Tween
var _punch_hit_bodies: Array = []
var _attack_timer := 0.0
var _jump_timer := 0.0

signal defeated

@onready var model: Node3D = $Model
@onready var left_leg: Node3D = $Model/LeftLeg
@onready var right_leg: Node3D = $Model/RightLeg
@onready var left_arm: Node3D = $Model/LeftArm
@onready var right_arm: Node3D = $Model/RightArm
@onready var hot_ball: MeshInstance3D = $Model/RightArm/HotBall
@onready var hot_ball_area: Area3D = $Model/RightArm/HotBall/HitArea

func _ready() -> void:
	add_to_group("enemy")
	model.rotation.y = PI / 2.0
	hot_ball_area.body_entered.connect(_on_hotball_hit)
	_jump_timer = _random_jump_interval()
	_attack_timer = _random_attack_interval()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	velocity.x = direction * SPEED
	velocity.z = 0.0

	if position.x >= patrol_right:
		direction = -1.0
	elif position.x <= patrol_left:
		direction = 1.0

	model.rotation.y = PI / 2.0 if direction > 0.0 else -PI / 2.0

	_attack_timer -= delta
	if _attack_timer <= 0.0 and not is_punching:
		_attack_timer = _random_attack_interval()
		_do_punch()

	_jump_timer -= delta
	if _jump_timer <= 0.0:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		_jump_timer = _random_jump_interval()

	if is_on_floor() and abs(velocity.x) > 0.0 and not is_punching:
		walk_phase += delta * 8.0
		_animate_walk()
	elif not is_punching:
		walk_phase = 0.0
		_reset_limbs()

	move_and_slide()

func _random_jump_interval() -> float:
	var choices := [1.0, 3.0, 5.0]
	return choices[randi() % 3]

func _random_attack_interval() -> float:
	var choices := [2.0, 4.0, 6.0]
	return choices[randi() % 3]

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
	_punch_hit_bodies.clear()
	hot_ball_area.monitoring = true
	if _punch_tween:
		_punch_tween.kill()
	_punch_tween = create_tween()
	_punch_tween.tween_property(right_arm, "rotation:x", -PI / 2.0, 0.1)
	_punch_tween.tween_interval(0.08)
	_punch_tween.tween_property(right_arm, "rotation:x", 0.0, 0.18)
	await _punch_tween.finished
	hot_ball_area.monitoring = false
	hot_ball.visible = false
	is_punching = false

func _on_hotball_hit(body: Node3D) -> void:
	if body.is_in_group("player") and body not in _punch_hit_bodies:
		_punch_hit_bodies.append(body)
		body.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp <= 0:
		defeated.emit()
		queue_free()
