extends CharacterBody2D

# Константы врага
const SPEED : int = 80                # Скорость движения врага
const MAX_XP : int = 3                # Максимальное количество жизней (HP)
const MIN_XP : int = 0                # Минимальное количество жизней (HP), при котором враг умирает
const ATTACK_DISTANCE : int = 80      # Дистанция, с которой враг начинает атаку
const ATTACK_COOLDOWN : int = 1       # Задержка между атаками (секунды)
const DAMAGE : int = 1                # Урон, наносимый игроку

# Переменные состояния
var hp : int = MAX_XP                 # Текущее количество жизней врага
var direction : int = -1              # Текущее направление движения (-1 = влево, 1 = вправо)
var player = null                     # Ссылка на игрока (Node)
var is_agro : bool = false            # Агрессивен ли враг (видит игрока)
var can_attack : bool = true          # Может ли враг атаковать прямо сейчас

signal died                           # Сигнал смерти врага

# Быстрые ссылки на дочерние узлы
@onready var sprite = $Sprite2D
@onready var edge_check = $EdgeCheck
@onready var detection_area = $DetectionArea
@onready var attack_timer = $AttackCooldown

# Вызывается при добавлении врага в сцену
func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_to_group("enemies")

# Главный цикл физики. Управляет движением и поведением врага
func _physics_process(delta):
	edge_check.target_position = Vector2(16 * direction, 16)
	if is_agro and player:
		var to_player = player.global_position - global_position
		if to_player.length() > ATTACK_DISTANCE and edge_check.is_colliding():
			direction = sign(to_player.x)
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
		else:
			velocity.x = 0
			if can_attack:
				attack()
	else:
		if not edge_check.is_colliding():
			direction *= -1
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0

	velocity.y += 900 * delta
	move_and_slide()
	
# Срабатывает, когда игрок входит в зону обнаружения
func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_agro = true
		player = body

# Срабатывает, когда игрок выходит из зоны обнаружения
func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		is_agro = false
		player = null

# Атака игрока
func attack() -> void:
	can_attack = false
	if player:
		player.take_damage(DAMAGE)
	attack_timer.start()

# Срабатывает, когда заканчивается задержка между атаками
func _on_attack_cooldown_timeout() -> void:
	can_attack = true

# Получение урона врагом
func take_damage(amount: int) -> void:
	hp -= amount
	sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color(1, 1, 1)
	if hp <= MIN_XP:
		emit_signal("died")
		queue_free()
