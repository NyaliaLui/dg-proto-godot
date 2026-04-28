extends CharacterBody3D

const SPEED := 2.5
const GRAVITY := 20.0
const MAX_HP := 15
const DAMAGE := 5

var patrol_left := -6.0
var patrol_right := 6.0
var direction := 1.0
var hp := MAX_HP
var _damage_cooldown := 0.0

signal defeated

@onready var model: Node3D = $Model

func _ready() -> void:
	add_to_group("enemy")
	model.rotation.y = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	velocity.x = direction * SPEED
	velocity.z = 0.0

	if position.x >= patrol_right:
		direction = -1.0
	elif position.x <= patrol_left:
		direction = 1.0

	model.rotation.y = 0.0 if direction > 0.0 else PI

	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta
	_check_contact_damage()

	move_and_slide()

func _check_contact_damage() -> void:
	if _damage_cooldown > 0.0:
		return
	for player in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(player.global_position) < 1.0:
			if player.is_punching:
				take_damage(player.DAMAGE)
			else:
				player.take_damage(DAMAGE)
			_damage_cooldown = 1.0

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp <= 0:
		defeated.emit()
		queue_free()
