extends Control

func _on_create_lobby_pressed() -> void:
	ClientManager.create_lobby()
