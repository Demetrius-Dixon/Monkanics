extends Control


func _on_play_online_pressed() -> void:
	
	Client.register_to_ingest_server()
	
	
	
	#TODO Add sub-menu later in development

func _on_quit_game_pressed() -> void:
	GameQuitter.quit_monkanics()
