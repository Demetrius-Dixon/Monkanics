extends Control

@onready var main_menu : Node = $"."
@onready var main_screen_nodes : Node = $MainScreen
var server_browser_scene : Variant = preload("uid://cltyu1oqpw1v4")

func _ready() -> void:
	
	var server_browser_to_load : Variant = server_browser_scene.instantiate()
	server_browser_to_load.hide()
	main_menu.add_child(server_browser_to_load)
	server_browser_scene = server_browser_to_load

func _on_play_pressed() -> void:
	
	ClientManager.register_to_ingest_server()
	
	main_screen_nodes.hide()
	
	server_browser_scene.show()

func _on_quit_game_pressed() -> void:
	GameQuitterManager.quit_monkanics()
