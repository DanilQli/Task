extends CharacterBody2D

const SPEED : int = 300                # Скорость передвижения игрока
const JUMP_VELOCITY : int = -500       # Скорость прыжка
const MAX_XP : int = 5                 # Максимальное количество жизней
const MIN_XP : int = 0                 # Минимальное количество жизней (смерть)
const DAMAGE : int = 1                 # Урон, наносимый врагу

@export var hp : int = MAX_XP          # Текущее количество жизней
@export var kills : int = 0            # Текущее количество убийств
var size_viewport_y: int               # Высота экрана

signal died                            # Сигнал смерти игрока
signal hp_changed(new_hp)              # Сигнал изменения HP
signal kill_changed(new_kill)          # Сигнал изменения количество убийств

var facing_right : bool = true         # Куда смотрит игрок
var is_attacking : bool = false        # Атакует ли сейчас

@onready var attack_area = $Area2D
@onready var sprite = $Sprite2D
@onready var animate = $AnimationPlayer

# Инициализация игрока, подключение сигналов, определение высоты экрана
func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	size_viewport_y = get_viewport_rect().size.y
	add_to_group("player")
	
# Главный цикл физики: движение, прыжок, проигрывание анимаций, проверка падения за экран
func _physics_process(delta: float) -> void:
	if global_position.y >= size_viewport_y:
		emit_signal("died")
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	if direction != 0:
		if direction > 0:
			facing_right = true
			if not is_attacking:
				animate.play("walk_right")
		else:
			facing_right = false
			if not is_attacking:
				animate.play("walk_left")
	else:
		if not is_attacking:
			animate.play("idle_right" if facing_right else "idle_left")

	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY

	velocity.y += 900 * delta
	move_and_slide()

# Обработка ввода: атака по кнопке
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not is_attacking:
		attack()
	
# Атака: включает область удара, проигрывает анимацию, выключает область после задержки
func attack() -> void:
	is_attacking = true
	attack_area.monitoring = is_attacking
	if facing_right:
		attack_area.position.x = 20
		animate.play("attack_right")
	else:
		attack_area.position.x = -20
		animate.play("attack_left")
	await get_tree().create_timer(0.3).timeout
	is_attacking = false
	attack_area.monitoring = is_attacking

# Получение урона
func take_damage(amount: int) -> void:
	emit_signal("hp_changed", hp)
	hp -= amount
	sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color(1, 1, 1)
	if hp <= MIN_XP:
		emit_signal("died")

# Обработка попадания по врагу во время атаки
func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(DAMAGE)

# Счётчик убийств
func add_kill():
	kills += 1
	emit_signal("kill_changed", kills)
