extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 16.0
const GRAVITY := 20.0
const MAX_HP := 25
const DAMAGE := 5

signal health_changed(new_hp: int)
signal max_hp_changed(new_max_hp: int)

var is_punching := false
var hp := MAX_HP
var _max_hp: int = MAX_HP
var facing_dir := 1.0
var _damage_cooldown := 0.0
var _punch_hit_bodies: Array = []
var _anim_player: AnimationPlayer = null
var _walk_anim_name := ""
var _attack_anim_name := ""
var _hit_area: Area3D = null

@onready var model: Node3D = $Model
@onready var body_area: Area3D = $Model/BodyArea
@onready var head_area: Area3D = $Model/HeadArea
@onready var _glb_container: Node3D = $Model/GLBInstance

func _ready() -> void:
	add_to_group("player")
	model.rotation.y = PI / 2.0
	body_area.body_entered.connect(_on_hurtbox_entered)
	head_area.body_entered.connect(_on_hurtbox_entered)
	_setup_glb_animation()

func _setup_glb_animation() -> void:
	var anim_tree := _glb_container.find_child("AnimationTree", true, false) as AnimationTree
	if anim_tree:
		anim_tree.active = false
	_anim_player = _find_animation_player(_glb_container)
	if _anim_player == null:
		push_warning("Torrin: No AnimationPlayer found in GLB")
		return
	_anim_player.animation_finished.connect(_on_animation_finished)
	var list := _anim_player.get_animation_list()
	print("[Torrin] GLB animations: ", list)
	for anim_name in list:
		var lower := anim_name.to_lower()
		if _walk_anim_name.is_empty() and (lower.contains("walk") or lower.contains("run")):
			_walk_anim_name = anim_name
		if _attack_anim_name.is_empty() and (lower.contains("attack") or lower.contains("punch") \
				or lower.contains("swing") or lower.contains("slash") or lower.contains("strike")):
			_attack_anim_name = anim_name
	if _walk_anim_name.is_empty():
		for anim_name in list:
			if anim_name != "RESET" and anim_name != _attack_anim_name:
				_walk_anim_name = anim_name
				break
	print("[Torrin] Walk: '%s'  Attack: '%s'" % [_walk_anim_name, _attack_anim_name])
	_setup_hit_area()

func _setup_hit_area() -> void:
	var skeleton := _find_skeleton(_glb_container)
	if skeleton == null:
		push_warning("Torrin: No Skeleton3D found in GLB — attack hit detection disabled")
		return
	var bone_name := _find_hand_bone(skeleton)
	print("[Torrin] Hand bone: '%s'" % bone_name)
	if bone_name.is_empty():
		push_warning("Torrin: Could not find hand bone — attack hit detection disabled")
		return
	var attachment := BoneAttachment3D.new()
	skeleton.add_child(attachment)
	attachment.bone_name = bone_name
	_hit_area = Area3D.new()
	_hit_area.monitoring = false
	attachment.add_child(_hit_area)
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	shape_node.shape = sphere
	_hit_area.add_child(shape_node)
	_hit_area.body_entered.connect(_on_hit_area_entered)

func _find_hand_bone(skeleton: Skeleton3D) -> String:
	var bone_count := skeleton.get_bone_count()
	var all_bones: Array[String] = []
	for i in bone_count:
		all_bones.append(skeleton.get_bone_name(i))
	print("[Torrin] Skeleton bones: ", all_bones)
	var hand_kw := ["hand", "weapon", "sword", "wrist", "palm"]
	var right_kw := [".r", "_r", "right", "r_"]
	# Right hand / weapon bone first
	for i in bone_count:
		var name := skeleton.get_bone_name(i).to_lower()
		var has_hand := false
		for kw in hand_kw:
			if name.contains(kw):
				has_hand = true
				break
		if not has_hand:
			continue
		for rkw in right_kw:
			if name.ends_with(rkw) or name.begins_with(rkw) or name.contains(rkw):
				return skeleton.get_bone_name(i)
	# Any hand bone
	for i in bone_count:
		var name := skeleton.get_bone_name(i).to_lower()
		for kw in hand_kw:
			if name.contains(kw):
				return skeleton.get_bone_name(i)
	# Last bone as fallback (often a tip or weapon node)
	if bone_count > 0:
		return skeleton.get_bone_name(bone_count - 1)
	return ""

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

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
		_animate_walk()
	elif not is_punching:
		_reset_limbs()

	move_and_slide()

func _animate_walk() -> void:
	if _anim_player == null or _walk_anim_name.is_empty():
		return
	if not _anim_player.is_playing() or _anim_player.current_animation != _walk_anim_name:
		_anim_player.play(_walk_anim_name)

func _reset_limbs() -> void:
	if _anim_player != null and _anim_player.is_playing():
		_anim_player.stop()

func _do_punch() -> void:
	if _anim_player == null or _attack_anim_name.is_empty():
		return
	is_punching = true
	_punch_hit_bodies.clear()
	if _hit_area != null:
		_hit_area.monitoring = true
	_anim_player.play(_attack_anim_name)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == _attack_anim_name:
		if _hit_area != null:
			_hit_area.monitoring = false
		is_punching = false

func _on_hurtbox_entered(body: Node3D) -> void:
	if _damage_cooldown > 0.0:
		return
	if body.is_in_group("enemy"):
		take_damage(body.DAMAGE)
		_damage_cooldown = 1.0

func _on_hit_area_entered(body: Node3D) -> void:
	if body.is_in_group("enemy") and body not in _punch_hit_bodies:
		_punch_hit_bodies.append(body)
		body.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	health_changed.emit(hp)
	if hp <= 0:
		queue_free()

func add_health_bars(count: int) -> void:
	var bonus := count * 5
	_max_hp += bonus
	hp += bonus
	max_hp_changed.emit(_max_hp)
	health_changed.emit(hp)
