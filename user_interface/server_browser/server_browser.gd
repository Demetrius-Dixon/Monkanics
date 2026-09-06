extends Control

@onready var server_list : Node = $"TabContainer/Join Lobby"

var lobby_selection_button : PackedScene = preload("uid://ibl4vlin44xa")

var received_active_lobbies : Array[Dictionary] = []

func _ready() -> void:
	hide()

func _on_create_lobby_pressed() -> void:
	ClientManager.create_lobby()

func add_lobby_to_dictionary(lobby_info:Dictionary) -> void:
	
	received_active_lobbies.append(lobby_info)
	
	#add_lobbies_to_server_list(lobby[&"host"])

#func add_lobbies_to_server_list(lobby_info:String) -> void:
	#
	#var new_lobby_selection_button := lobby_selection_button.instantiate()
	#
	#new_lobby_selection_button.ping_label.text = lobby_info[&"host"]
	

func clear_server_browser_cache() -> void:
	received_active_lobbies.clear()
