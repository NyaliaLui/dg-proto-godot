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
var _damage_cooldown := 0.0
var _punch_hit_bodies: Array = []

@onready var model: Node3D = $Model
@onready var left_leg: Node3D = $Model/LeftLeg
@onready var right_leg: Node3D = $Model/RightLeg
@onready var left_arm: Node3D = $Model/LeftArm
@onready var right_arm: Node3D = $Model/RightArm
@onready var hot_ball: MeshInstance3D = $Model/RightArm/HotBall
@onready var body_area: Area3D = $Model/Body/BodyArea
@onready var head_area: Area3D = $Model/Head/HeadArea
@onready var hot_ball_area: Area3D = $Model/RightArm/HotBall/HitArea

func _ready() -> void:
	add_to_group("player")
	model.rotation.y = PI / 2.0
	body_area.body_entered.connect(_on_hurtbox_entered)
	head_area.body_entered.connect(_on_hurtbox_entered)
	hot_ball_area.body_entered.connect(_on_hotball_hit)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta

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

func _on_hurtbox_entered(body: Node3D) -> void:
	if _damage_cooldown > 0.0:
		return
	if body.is_in_group("enemy"):
		take_damage(body.DAMAGE)
		_damage_cooldown = 1.0

func _on_hotball_hit(body: Node3D) -> void:
	if body.is_in_group("enemy") and body not in _punch_hit_bodies:
		_punch_hit_bodies.append(body)
		body.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	health_changed.emit(hp)
	if hp <= 0:
		queue_free()
