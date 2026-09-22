extends Control

@onready var main_menu : Node = $"."
@onready var main_screen_nodes : Node = $MainScreen

func _ready() -> void:
	
	pass

func _on_play_pressed() -> void:
	
	ClientManager.create_client()
	
	UiManager.unload_ui_element("main_menu")
	
	UiManager.load_ui_element("server_browser")
	
	ClientManager.request_active_lobbies_from_server()

func _on_play_2_pressed() -> void:
	pass # Replace with function body.

func _on_quit_game_pressed() -> void:
	QuittingManager.quit_monkanics()
