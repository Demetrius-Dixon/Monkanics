extends Control

@onready var main_menu : Node = $"."
@onready var main_screen_nodes : Node = $MainScreen

func _ready() -> void:
	
	pass

func _on_play_pressed() -> void:
	
	#ClientManager.register_to_ingest_server()
	
	main_screen_nodes.hide()
	
	
	
	#ServerBrowser.show()

	#ClientManager.request_active_lobbies()

func _on_play_2_pressed() -> void:
	pass # Replace with function body.

func _on_quit_game_pressed() -> void:
	pass
	#GameQuitterManager.quit_monkanics()
