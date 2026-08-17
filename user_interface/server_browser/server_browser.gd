extends Control

func _ready() -> void:
	hide()

func _on_create_lobby_pressed() -> void:
	ClientManager.create_lobby()

func add_lobby_to_server_list(lobby:String) -> void:
	
	$"TabContainer/Join Lobby".add_item("lobby")

func clear_server_browser_cache() -> void:
	
	pass
