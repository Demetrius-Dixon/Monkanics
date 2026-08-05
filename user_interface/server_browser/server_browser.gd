extends Control

func _ready() -> void:
	
	add_lobby_to_server_list("TestString")

func _on_create_lobby_pressed() -> void:
	ClientManager.create_lobby()

func add_lobby_to_server_list(lobby:String) -> void:
	
	$"TabContainer/Join Lobby".add_item("lobby")
