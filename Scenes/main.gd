extends Node

@onready var player = $Player
@onready var ui = $CanvasLayer/UI
@onready var enemies_left: int

# Инициализация: подключение сигналов и установка начальных значений
func _ready():
	enemies_left = get_tree().get_nodes_in_group("enemies").size()
	player.died.connect(_show_game_over)
	player.died.connect(ui.show_game_over)
	player.hp_changed.connect(ui.update_hp)
	ui.update_hp(player.hp)
	ui.update_kill(player.kills)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(_on_enemy_died)
		enemy.died.connect(player.add_kill)
		enemy.died.connect(ui.update_kill)

# Перезапуск сцены
func _show_game_over():
	await get_tree().create_timer(1).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()

# Прооверка наличия врагов
func _on_enemy_died():
	enemies_left -= 1
	if enemies_left <= 0:
		ui.show_game_over()
		_show_game_over()
